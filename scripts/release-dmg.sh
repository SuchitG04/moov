#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Moov"
SCHEME="Moov"
PROJECT_FILE="Moov.xcodeproj"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

BUILD_DIR="${REPO_ROOT}/build"
DERIVED_DATA_DIR="${BUILD_DIR}/derived-data"
APP_PATH="${DERIVED_DATA_DIR}/Build/Products/Release/${APP_NAME}.app"
STAGING_DIR="${BUILD_DIR}/dmg-staging"

DMG_BASENAME="${1:-${APP_NAME}}"
DMG_PATH="${REPO_ROOT}/${DMG_BASENAME}.dmg"

echo "==> Building ${APP_NAME}.app (Release)"
xcodebuild \
  -project "${REPO_ROOT}/${PROJECT_FILE}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -derivedDataPath "${DERIVED_DATA_DIR}" \
  build

if [[ ! -d "${APP_PATH}" ]]; then
  echo "Error: built app not found at ${APP_PATH}" >&2
  exit 1
fi

echo "==> Preparing DMG staging folder"
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"
cp -R "${APP_PATH}" "${STAGING_DIR}/${APP_NAME}.app"
ln -s /Applications "${STAGING_DIR}/Applications"

echo "==> Creating DMG at ${DMG_PATH}"
rm -f "${DMG_PATH}"
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

echo "==> Done: ${DMG_PATH}"
echo "Tip: upload this DMG to GitHub Releases."
