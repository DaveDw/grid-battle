extends Node
## Self-update from GitHub Releases. The title screen makes one of these: it asks
## GitHub for the latest release, and if that's newer than Game.VERSION it can
## download this platform's build, swap it in for the running executable and restart.
##
## Release assets are found by name suffix ("-windows.exe", "-linux.x86_64");
## tools/publish_release.sh uploads them. A macOS .app can't replace itself while
## running, so there the update opens the release page instead.
## For testing, GRIDBATTLE_UPDATE_API points the check at another URL (same JSON shape)
## and GRIDBATTLE_UPDATE_AUTO=1 starts the update as soon as one is found.

signal status(text: String)          # a line for the title screen ("Up to date", ...)
signal available(version: String)    # a newer release exists
signal progress(fraction: float)     # download progress, 0..1
signal failed(text: String)

## The GitHub repository whose releases are checked. It must be public: the game
## carries no login, and GitHub answers 404 for a private repo's releases.
const REPO := "DaveDw/grid-battle"
const API := "https://api.github.com/repos/%s/releases/latest"
const ASSET_SUFFIX := {"Windows": "-windows.exe", "Linux": "-linux.x86_64"}
const HEADERS := ["Accept: application/vnd.github+json", "User-Agent: GridBattle-Updater"]

var latest := ""        # newest release tag, e.g. "v0.0.5"
var page_url := ""      # that release's web page
var _asset_url := ""
var _asset_size := 0
var _new_path := ""
var _http: HTTPRequest

## Only exported builds update themselves; running from the editor never checks
## unless a test URL is set.
static func should_check() -> bool:
	return OS.has_feature("template") or OS.get_environment("GRIDBATTLE_UPDATE_API") != ""

## Can this build swap its own executable? (Windows and Linux exports.)
static func can_self_update() -> bool:
	return OS.has_feature("template") and ASSET_SUFFIX.has(OS.get_name())

## "Alpha Test Snapshot v0.0.4" / "v0.0.4" -> [0, 0, 4]
static func version_parts(s: String) -> Array:
	var m := RegEx.create_from_string("(\\d+)\\.(\\d+)\\.(\\d+)").search(s)
	if m == null:
		return [0, 0, 0]
	return [int(m.get_string(1)), int(m.get_string(2)), int(m.get_string(3))]

static func is_newer(a: String, b: String) -> bool:
	var x := version_parts(a)
	var y := version_parts(b)
	for i in 3:
		if x[i] != y[i]:
			return x[i] > y[i]
	return false

## Remove the executable left behind by the last update (Windows renames the running
## exe aside instead of overwriting it).
static func cleanup() -> void:
	var old := OS.get_executable_path() + ".old"
	if OS.has_feature("template") and FileAccess.file_exists(old):
		DirAccess.remove_absolute(old)

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	set_process(false)

func check() -> void:
	var url := OS.get_environment("GRIDBATTLE_UPDATE_API")
	if url == "":
		url = API % REPO
	_say("Checking for updates…")
	_http.timeout = 15.0
	_http.request_completed.connect(_on_release, CONNECT_ONE_SHOT)
	if _http.request(url, HEADERS) != OK:
		_fail("Couldn't check for updates")

func _on_release(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail("Couldn't check for updates")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY or not data.has("tag_name"):
		_fail("Couldn't check for updates")
		return
	latest = data["tag_name"]
	page_url = data.get("html_url", "")
	var suffix: String = ASSET_SUFFIX.get(OS.get_name(), "")
	for a in data.get("assets", []):
		if suffix != "" and String(a.get("name", "")).ends_with(suffix):
			_asset_url = a.get("browser_download_url", "")
			_asset_size = int(a.get("size", 0))
	if is_newer(latest, Game.VERSION):
		print("[updater] %s available (running %s)" % [latest, Game.VERSION])
		available.emit(latest)
		if OS.get_environment("GRIDBATTLE_UPDATE_AUTO") == "1":
			update()
	else:
		_say("Up to date")

## Download the new build next to the running one, swap it in and restart.
func update() -> void:
	if not can_self_update():
		if page_url != "":
			OS.shell_open(page_url)
		return
	if _asset_url == "":
		_fail("This release has no %s build" % OS.get_name())
		return
	_new_path = OS.get_executable_path() + ".new"
	var probe := FileAccess.open(_new_path, FileAccess.WRITE)
	if probe == null:
		_fail("Can't write to the game's folder")
		return
	probe.close()
	_http.timeout = 0.0
	_http.download_file = _new_path
	_http.request_completed.connect(_on_downloaded, CONNECT_ONE_SHOT)
	if _http.request(_asset_url, ["User-Agent: GridBattle-Updater"]) != OK:
		_fail("Couldn't start the download")
		return
	set_process(true)

func _process(_delta: float) -> void:
	if _asset_size > 0:
		progress.emit(clampf(float(_http.get_downloaded_bytes()) / _asset_size, 0.0, 1.0))

func _on_downloaded(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	set_process(false)
	_http.download_file = ""
	var got := FileAccess.get_size(_new_path) if FileAccess.file_exists(_new_path) else 0
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or (_asset_size > 0 and got != _asset_size):
		DirAccess.remove_absolute(_new_path)
		_fail("Download failed")
		return
	progress.emit(1.0)
	_swap_and_restart()

func _swap_and_restart() -> void:
	var exe := OS.get_executable_path()
	var old := exe + ".old"
	if FileAccess.file_exists(old):
		DirAccess.remove_absolute(old)
	# Windows won't overwrite a running exe but will rename it; Linux replaces in place.
	if OS.get_name() == "Windows" and DirAccess.rename_absolute(exe, old) != OK:
		DirAccess.remove_absolute(_new_path)
		_fail("Couldn't replace the game file")
		return
	if DirAccess.rename_absolute(_new_path, exe) != OK:
		if OS.get_name() == "Windows":
			DirAccess.rename_absolute(old, exe)
		_fail("Couldn't replace the game file")
		return
	if OS.get_name() == "Linux":
		OS.execute("chmod", ["+x", exe])
	print("[updater] installed %s, restarting" % latest)
	OS.create_process(exe, OS.get_cmdline_args())
	get_tree().quit()

func _say(text: String) -> void:
	print("[updater] ", text)
	status.emit(text)

func _fail(text: String) -> void:
	print("[updater] ", text)
	failed.emit(text)
