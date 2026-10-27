#!/usr/bin/env bash
# Import each unit's frames as soon as Codex logs it in art_incoming/progress.txt.
# Stops once every logged unit is imported and 23 are done, or after ~3 hours.
cd "$(dirname "$0")/.."
G=/c/Users/ddwig/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe
done_list=""
for i in $(seq 1 90); do
  if [ -f art_incoming/progress.txt ]; then
    for u in $(grep -oE '^[a-z]+/[a-z_]+ done' art_incoming/progress.txt | cut -d' ' -f1); do
      case " $done_list " in *" $u "*) continue;; esac
      if [ -f "art_incoming/${u}_idle.png" ]; then
        timeout 600 "$G" --headless --path . -s tools/import_frames.gd -- "$u" 2>&1 | grep -E "\->.*_idle|ERROR" | sed "s/^/[$(date +%H:%M)] /"
        done_list="$done_list $u"
      fi
    done
    n=$(echo $done_list | wc -w)
    if [ "$n" -ge 23 ]; then echo "all $n units imported"; exit 0; fi
    if grep -qiE "fail" art_incoming/progress.txt; then grep -iE "fail" art_incoming/progress.txt | sed 's/^/NOTE: /' | sort -u > /tmp/fails.txt; fi
  fi
  sleep 120
done
echo "stopped after 3h: imported $(echo $done_list | wc -w) units:$done_list"
cat /tmp/fails.txt 2>/dev/null
