#!/bin/sh
# Builds the place with Rojo and runs a headless test script inside Roblox Studio.
# Needs Studio installed plus run-in-roblox (rokit add --global rojo-rbx/run-in-roblox).
#   sh tools/run-tests.sh                                  # server logic tests
#   sh tools/run-tests.sh tools/tests/Balance.server.lua   # chase winnability per zone / Run Speed
set -e
script="${1:-tools/tests/ServerTests.server.lua}"
place="${TMPDIR:-/tmp}/KickTheEgg-tests.rbxl"
rojo build default.project.json -o "$place"
run-in-roblox --place "$place" --script "$script"
