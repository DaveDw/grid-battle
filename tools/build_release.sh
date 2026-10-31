#!/usr/bin/env bash
# Export Windows, Linux and macOS builds and package them into builds/release/.
# Run from the project root (Git Bash): bash tools/build_release.sh
set -e
G=/c/Users/ddwig/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe
V=0.0.8
"$G" --headless --path . --import >/dev/null 2>&1
"$G" --headless --path . --export-release "Windows Alpha" builds/windows/GridBattle-Alpha-$V.exe 2>&1 | grep -iE "^ERROR" || true
"$G" --headless --path . --export-release "Linux Alpha" builds/linux/GridBattle-Alpha-$V.x86_64 2>&1 | grep -iE "^ERROR" || true
"$G" --headless --path . --export-release "macOS Alpha" builds/macos/GridBattle-Alpha-$V-macos.zip 2>&1 | grep -iE "^ERROR" || true
mkdir -p builds/release
rm -f builds/release/*-$V-* builds/release/README-macos-$V.txt   # keep older snapshots
(cd builds/windows && powershell -NoProfile -Command "Compress-Archive -Force -Path 'GridBattle-Alpha-$V.exe','README.txt' -DestinationPath '../release/GridBattle-Alpha-$V-windows.zip'")
tar -C builds/linux --mode=755 -czf builds/release/GridBattle-Alpha-$V-linux.tar.gz GridBattle-Alpha-$V.x86_64 README.txt
cp builds/macos/GridBattle-Alpha-$V-macos.zip builds/release/
cp builds/macos/README.txt builds/release/README-macos-$V.txt
ls -la builds/release
