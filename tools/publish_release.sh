#!/usr/bin/env bash
# Publish the builds from tools/build_release.sh as a GitHub release, so the in-game
# updater (scripts/updater.gd) can find them.
# Run from the project root (Git Bash): bash tools/publish_release.sh 0.0.5 "What changed"
#
# Uploads, under tag v<version>:
#   GridBattle-Alpha-<v>-windows.exe     raw exe   (the Windows updater downloads this)
#   GridBattle-Alpha-<v>-linux.x86_64    raw binary (the Linux updater downloads this)
#   the windows .zip, linux .tar.gz and macos .zip from builds/release, for people.
# Needs a GitHub token with Contents read/write on the repo: GITHUB_TOKEN if set,
# otherwise the one Git Credential Manager already stores for github.com.
# The repo must be public, or players' games can't see the release.
set -e
V=${1:?usage: publish_release.sh <version> [notes]}
NOTES=${2:-"Alpha Test Snapshot v$V"}
REPO=DaveDw/grid-battle
API=https://api.github.com/repos/$REPO

TOKEN=${GITHUB_TOKEN:-$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill | sed -n 's/^password=//p')}
[ -n "$TOKEN" ] || { echo "No GitHub token found"; exit 1; }
AUTH=(-H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json")

for f in builds/windows/GridBattle-Alpha-$V.exe builds/linux/GridBattle-Alpha-$V.x86_64 \
         builds/release/GridBattle-Alpha-$V-windows.zip builds/release/GridBattle-Alpha-$V-linux.tar.gz \
         builds/release/GridBattle-Alpha-$V-macos.zip; do
	[ -f "$f" ] || { echo "Missing $f (run tools/build_release.sh first)"; exit 1; }
done

ESC=$(printf '%s' "$NOTES" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n' ' ')   # JSON-escape the notes
BODY=$(printf '{"tag_name":"v%s","target_commitish":"main","name":"Alpha Test Snapshot v%s","body":"%s"}' "$V" "$V" "$ESC")
ID=$(curl -sf "${AUTH[@]}" -X POST "$API/releases" -d "$BODY" | sed -n 's/^  "id": \([0-9]*\),$/\1/p' | head -1)
[ -n "$ID" ] || { echo "Creating the release failed (does v$V already exist?)"; exit 1; }
echo "Created release v$V (id $ID)"

upload() {   # <file> <asset name>
	curl -sf "${AUTH[@]}" -H "Content-Type: application/octet-stream" --data-binary @"$1" \
		"https://uploads.github.com/repos/$REPO/releases/$ID/assets?name=$2" > /dev/null
	echo "  uploaded $2"
}
upload builds/windows/GridBattle-Alpha-$V.exe GridBattle-Alpha-$V-windows.exe
upload builds/linux/GridBattle-Alpha-$V.x86_64 GridBattle-Alpha-$V-linux.x86_64
upload builds/release/GridBattle-Alpha-$V-windows.zip GridBattle-Alpha-$V-windows.zip
upload builds/release/GridBattle-Alpha-$V-linux.tar.gz GridBattle-Alpha-$V-linux.tar.gz
upload builds/release/GridBattle-Alpha-$V-macos.zip GridBattle-Alpha-$V-macos.zip
echo "Done: https://github.com/$REPO/releases/tag/v$V"
