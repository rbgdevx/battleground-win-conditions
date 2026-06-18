#!/usr/bin/env bash
# Packages this repo into a distributable zip for PC/Mac WoW clients.
#
# Output: ../BattlegroundWinConditions-v<version>.zip   (sibling of this
#         repo, in the shared addons working dir).
#
# The zip contains a single top-level folder `BattlegroundWinConditions/`
# so users on Windows or Mac can extract it directly into:
#   World of Warcraft\_retail_\Interface\AddOns\
#
# Excludes (dev-only, not part of the addon distribution):
#   .git/, .gitignore, .DS_Store, ._* (AppleDouble), .claude/, .vscode/,
#   .luarc.json, AGENTS.md, CLAUDE.md, README.md, CHANGELOG.md,
#   cspell.json, stylua.toml, deploy-to-wow.sh, package-addon.sh
#
# Kept:
#   .toc / .xml / .lua, core/, interface/, libs/, maps/, predictions/,
#   logo.tga

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$(cd "$SRC/.." && pwd)"
TOC="$SRC/BattlegroundWinConditions.toc"

# --- Read version from .toc (no bump) -----------------------------------
version=$(awk -F': ' '/^## Version:/ { print $2; exit }' "$TOC" | tr -d '[:space:]')
if [[ -z "$version" ]]; then
  echo "ERROR: no '## Version:' line found in $TOC" >&2
  exit 1
fi

ZIP_NAME="BattlegroundWinConditions-v${version}.zip"
ZIP_PATH="$OUT_DIR/$ZIP_NAME"

echo "Packaging BattlegroundWinConditions v${version}"
echo "   from: $SRC"
echo "   to:   $ZIP_PATH"

# --- Stage in a temp dir so the zip has a clean BattlegroundWinConditions/ root ---
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

rsync -a \
  --exclude='.git/' \
  --exclude='.gitignore' \
  --exclude='.DS_Store' \
  --exclude='._*' \
  --exclude='.claude/' \
  --exclude='.vscode/' \
  --exclude='.luarc.json' \
  --exclude='.luacheckrc' \
  --exclude='AGENTS.md' \
  --exclude='CLAUDE.md' \
  --exclude='README.md' \
  --exclude='CHANGELOG.md' \
  --exclude='cspell.json' \
  --exclude='stylua.toml' \
  --exclude='deploy-to-wow.sh' \
  --exclude='package-addon.sh' \
  "$SRC/" "$STAGE/BattlegroundWinConditions/"

# --- Zip it -------------------------------------------------------------
# COPYFILE_DISABLE=1 prevents macOS from injecting AppleDouble (._*) files
# into the archive. -X strips extra file attrs so the archive is portable.
rm -f "$ZIP_PATH"
( cd "$STAGE" && COPYFILE_DISABLE=1 zip -rXq "$ZIP_PATH" "BattlegroundWinConditions" )

echo "Done. Wrote $ZIP_PATH"
