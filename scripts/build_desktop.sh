#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# build_desktop.sh — Build raylib-toolkit for Desktop (Linux/macOS/Windows)
# Usage: ./scripts/build_desktop.sh [Debug|Release|MinSizeRel|RelWithDebInfo]
# ---------------------------------------------------------------------------
set -euo pipefail

BUILD_TYPE="${1:-Release}"
BUILD_DIR="build"

echo "========================================"
echo " Building for Desktop (${BUILD_TYPE})"
echo "========================================"

cmake -S . -B "${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"

cmake --build "${BUILD_DIR}" --config "${BUILD_TYPE}" --parallel

echo ""
echo "✅ Desktop build complete!"
echo "   Run: ${BUILD_DIR}/raylib-toolkit/raylib-toolkit"
echo "========================================"