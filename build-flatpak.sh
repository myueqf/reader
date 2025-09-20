#!/usr/bin/env bash
set -euo pipefail

APP_ID="io.github.myueqf.reader"
MANIFEST="${APP_ID}.json"
BUILD_DIR="flatpak-build"
REPO_DIR="./QAQ"

echo "开始构建~ ${APP_ID}"

# 清理旧构建产物～
rm -rf "$BUILD_DIR" "$REPO_DIR"

# 构建～
echo "构建应用～"
flatpak-builder \
  --force-clean \
  --install-deps-from=flathub \
  --repo="$REPO_DIR" \
  "$BUILD_DIR" \
  "$MANIFEST"

# 安装和导出～
echo "安装到用户空间~"
flatpak install --user --reinstall "$REPO_DIR" "$APP_ID" -y

echo "导出～"
  flatpak build-bundle ${REPO_DIR} ${APP_ID}.flatpak ${APP_ID}
  

