#!/bin/sh
# DEV ONLY. tools/anim/encode.sh <frames dir> <out.mp4> [encode.py options]: runs encode.py in headless Blender.
blender="${BLENDER:-/c/Program Files/Blender Foundation/Blender 5.2/blender.exe}"
dir="$(cd "$(dirname "$0")" && pwd)"
src="$(cygpath -w "$1")"; out="$(cygpath -w "$2")"; shift 2
"$blender" -b --factory-startup --python "$(cygpath -w "$dir/encode.py")" -- "$src" "$out" "$@" 2>&1 | grep -E "^(crop|mp4|sheet)|Error|Traceback"
