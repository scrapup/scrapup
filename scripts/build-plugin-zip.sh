#!/usr/bin/env bash
#
# Build the importable scrapup plugin .zip.
#
# Packages the plugin payload only (manifest + components) with the
# .claude-plugin/ manifest at the zip root, so the archive loads directly via
# `claude --plugin-dir scrapup-<tag>.zip`. package.json, workflows, scripts and
# VCS metadata are intentionally excluded.
#
# Usage: scripts/build-plugin-zip.sh <tag> [out_dir]
#   <tag>      version tag for the file name, e.g. v0.2.0
#   [out_dir]  directory for the .zip (default: current directory)
#
# Prints the absolute path of the generated .zip on success.

set -euo pipefail

tag="${1:?usage: build-plugin-zip.sh <tag> [out_dir]}"
out_dir="${2:-$PWD}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"
zip_path="$out_dir/scrapup-${tag}.zip"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

cp -R .claude-plugin "$stage/"
for path in skills agents commands hooks README.md README.pt.md README.ja.md LICENSE; do
  [ -e "$path" ] && cp -R "$path" "$stage/"
done

rm -f "$zip_path"
( cd "$stage" && zip -rq "$zip_path" . )

echo "$zip_path"
