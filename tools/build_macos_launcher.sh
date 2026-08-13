#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/native/macos/main.swift"
APP_BUNDLE="$ROOT_DIR/总控台.app"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/local-ops-launcher.XXXXXX")"
MODE="${1:-build}"

if [[ "$MODE" != "build" && "$MODE" != "--verify" ]]; then
  echo "用法：$0 [--verify]" >&2
  exit 2
fi

cleanup() {
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

SWIFTC="$(xcrun --find swiftc)"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
SOURCE_SHA256="$(/usr/bin/shasum -a 256 "$SOURCE_FILE" | awk '{print $1}')"
SOURCE_ID="LOCAL_OPS_SOURCE_SHA256=$SOURCE_SHA256"
SOURCE_ID_FILE="$BUILD_DIR/source.sha256"
printf '%s\n' "$SOURCE_ID" >"$SOURCE_ID_FILE"

compile_arch() {
  local arch="$1"
  "$SWIFTC" \
    -sdk "$SDK_PATH" \
    -target "${arch}-apple-macos12.0" \
    -framework AppKit \
    -O \
    -whole-module-optimization \
    -Xlinker -sectcreate \
    -Xlinker __TEXT \
    -Xlinker __src_hash \
    -Xlinker "$SOURCE_ID_FILE" \
    "$SOURCE_FILE" \
    -o "$BUILD_DIR/launcher-$arch"
}

compile_arch arm64
compile_arch x86_64
xcrun lipo -create \
  "$BUILD_DIR/launcher-arm64" \
  "$BUILD_DIR/launcher-x86_64" \
  -output "$BUILD_DIR/launcher"

TARGET_APP="$APP_BUNDLE"
if [[ "$MODE" == "--verify" ]]; then
  TARGET_APP="$BUILD_DIR/总控台.app"
  /usr/bin/ditto "$APP_BUNDLE" "$TARGET_APP"
fi
OUTPUT_FILE="$TARGET_APP/Contents/MacOS/launcher"
install -m 755 "$BUILD_DIR/launcher" "$OUTPUT_FILE"
/usr/bin/codesign --force --deep --sign - "$TARGET_APP"

verify_app() {
  local app_bundle="$1"
  local launcher="$app_bundle/Contents/MacOS/launcher"
  local archs

  /usr/bin/codesign --verify --deep --strict "$app_bundle"
  archs="$(xcrun lipo -archs "$launcher")"
  if [[ "$(wc -w <<<"$archs" | tr -d ' ')" != "2" \
      || " $archs " != *" arm64 "* || " $archs " != *" x86_64 "* ]]; then
    echo "错误：原生启动器不是 arm64 + x86_64 通用二进制：$archs" >&2
    exit 1
  fi

  for arch in arm64 x86_64; do
    local thin_launcher="$BUILD_DIR/verify-$arch"
    if ! xcrun vtool -show-build -arch "$arch" "$launcher" \
        | grep -Eq 'minos[[:space:]]+12\.0'; then
      echo "错误：$arch launcher 的最低系统版本不是 macOS 12.0" >&2
      exit 1
    fi
    xcrun lipo -thin "$arch" "$launcher" -output "$thin_launcher"
    if ! /usr/bin/strings "$thin_launcher" | grep -Fq "$SOURCE_ID"; then
      echo "错误：$arch launcher 与当前 Swift 源码哈希不一致" >&2
      exit 1
    fi
  done
}

verify_app "$TARGET_APP"

if [[ "$MODE" == "--verify" ]]; then
  verify_app "$APP_BUNDLE"
  echo "原生启动器验证通过：源码哈希、通用二进制、macOS 12 目标与签名一致"
else
  echo "已构建原生启动器：$OUTPUT_FILE ($(xcrun lipo -archs "$OUTPUT_FILE"))"
fi
