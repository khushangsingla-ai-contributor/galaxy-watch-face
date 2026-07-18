#!/usr/bin/env bash
#
# Build release APKs for every watch face and collect them under an output
# directory (default: dist/). Writes manifest.json with per-face metadata.
#
# Usage:
#   ./scripts/build-artifacts.sh                  # build -> dist/
#   ./scripts/build-artifacts.sh --output dist
#   ./scripts/build-artifacts.sh --skip-build     # collect existing APKs only
#
# CI: the release workflow runs this script on tag push and uploads dist/*.apk
# as GitHub Release assets.
#
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
faces_dir="$repo_root/faces"
output_dir="$repo_root/dist"
skip_build=0

usage() {
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage 0 ;;
        -o|--output)
            [[ $# -ge 2 ]] || { echo "ERROR: --output requires a path" >&2; exit 1; }
            output_dir="$2"
            shift 2
            ;;
        --skip-build) skip_build=1; shift ;;
        *) echo "ERROR: unknown argument: $1" >&2; usage 1 ;;
    esac
done

if [[ "$output_dir" != /* ]]; then
    output_dir="$repo_root/$output_dir"
fi

discover_faces() {
    find "$faces_dir" -mindepth 1 -maxdepth 1 -type d -name '.*' -prune -o \
        -type d -print | while read -r dir; do
        [[ -f "$dir/build.gradle" ]] && basename "$dir"
    done | sort
}

read_version_name() {
    local face_dir="$1"
    local gradle="$face_dir/build.gradle"
    if [[ -f "$gradle" ]]; then
        grep -E "versionName\s+'" "$gradle" | head -1 | sed -E "s/.*versionName\s+'([^']+)'.*/\1/" || true
    fi
}

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        echo ""
    fi
}

if [[ "$skip_build" -eq 0 ]]; then
    echo "Building release APKs (./gradlew assembleRelease)..."
    (cd "$repo_root" && ./gradlew assembleRelease -q --no-daemon)
fi

mkdir -p "$output_dir"
manifest_entries=()
built_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

while IFS= read -r face_id; do
    [[ -n "$face_id" ]] || continue
    face_dir="$faces_dir/$face_id"
    apk_dir="$face_dir/build/outputs/apk/release"
    apk_src=""
    if [[ -d "$apk_dir" ]]; then
        apk_src="$(find "$apk_dir" -maxdepth 1 -name '*.apk' -type f | sort | head -1)"
    fi
    if [[ -z "$apk_src" || ! -f "$apk_src" ]]; then
        echo "WARNING: no release APK for $face_id (expected under $apk_dir)" >&2
        continue
    fi

    dest_name="${face_id}.apk"
    dest_path="$output_dir/$dest_name"
    cp "$apk_src" "$dest_path"

    version_name="$(read_version_name "$face_dir")"
    version_name="${version_name:-unknown}"
    checksum="$(sha256_file "$dest_path")"
    size_bytes="$(wc -c < "$dest_path" | tr -d ' ')"

    echo "  $face_id -> $dest_path ($version_name, ${size_bytes} bytes)"

    # Build a JSON object for this face (manifest is assembled below).
    entry=$(cat <<EOF
{
  "id": "$face_id",
  "apk": "$dest_name",
  "versionName": "$version_name",
  "sizeBytes": $size_bytes,
  "sha256": "$checksum",
  "builtAt": "$built_at"
}
EOF
)
    manifest_entries+=("$entry")
done < <(discover_faces)

if [[ ${#manifest_entries[@]} -eq 0 ]]; then
    echo "ERROR: no watch-face APKs were produced" >&2
    exit 1
fi

manifest_path="$output_dir/manifest.json"
{
    echo "{"
    echo "  \"generatedAt\": \"$built_at\","
    echo "  \"faces\": ["
    first=1
    for entry in "${manifest_entries[@]}"; do
        [[ $first -eq 1 ]] || echo ","
        first=0
        echo -n "    "
        echo "$entry" | tr -d '\n'
    done
    echo ""
    echo "  ]"
    echo "}"
} > "$manifest_path"

echo "Wrote ${#manifest_entries[@]} APK(s) to $output_dir"
echo "Manifest: $manifest_path"
