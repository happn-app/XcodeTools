#!/bin/bash
set -euo pipefail

readonly LINUX_SWIFT_IMAGE="swift:5.3.3"

# This can only be run on macOS
test "$(uname -s)" = "Darwin"

cd "$(dirname "$0")"

echo "*** RUNNING C TEST ON MACOS"
make signal-tests && ./signal-tests
rm signal-tests

echo
echo
echo "*** RUNNING C TEST ON LINUX"
docker run --rm -it -v "$(pwd):/tmp/cwd" --workdir /tmp/cwd --security-opt=seccomp:unconfined --entrypoint bash "$LINUX_SWIFT_IMAGE" -c 'make signal-tests && ./signal-tests && rm signal-tests'

echo
echo
echo "*** RUNNING SWIFT TEST ON MACOS"
# We must compile, when run via swift as a script, some signal are handled by Swift itself
swiftc ./signal-tests-macos.swift && ./signal-tests-macos
rm signal-tests-macos

echo
echo
echo "*** RUNNING SWIFT TEST ON LINUX"
docker run --rm -it -v "$(pwd):/tmp/cwd" --workdir /tmp/cwd --security-opt=seccomp:unconfined --entrypoint bash "$LINUX_SWIFT_IMAGE" -c 'swiftc -o ./signal-tests-linux ./signal-tests-linux.swift && ./signal-tests-linux && rm signal-tests-linux'
