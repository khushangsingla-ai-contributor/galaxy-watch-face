#!/usr/bin/env bash
#
# Validates every watch face in this repo against the official Watch Face Format
# (WFF) validator from https://github.com/google/watchface.
#
# The validator jar is expected at $HOME/wff-tools/wff-validator.jar. If it is
# missing, build it once with:
#   git clone --depth 1 https://github.com/google/watchface.git /tmp/watchface
#   cd /tmp/watchface/third_party/wff && ./gradlew :specification:validator:executable-jar
#   mkdir -p "$HOME/wff-tools" && cp specification/validator/build/libs/wff-validator.jar "$HOME/wff-tools/"
#
# Usage: scripts/wff-validate.sh [wff-version]   (default version: 2)

set -euo pipefail

VERSION="${1:-2}"
JAR="${WFF_VALIDATOR_JAR:-$HOME/wff-tools/wff-validator.jar}"

if [ ! -f "$JAR" ]; then
    echo "ERROR: WFF validator jar not found at: $JAR" >&2
    echo "See the header of this script for build instructions." >&2
    exit 1
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
status=0

while IFS= read -r -d '' face; do
    echo "== Validating $face (WFF v$VERSION) =="
    if ! java -jar "$JAR" "$VERSION" "$face"; then
        status=1
    fi
done < <(find "$repo_root/faces" -path '*/res/raw/watchface.xml' -print0)

exit "$status"
