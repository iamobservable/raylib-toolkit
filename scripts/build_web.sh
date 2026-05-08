#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# build_web.sh — Build raylib-toolkit for WebAssembly (Emscripten)
#
# Prerequisites:
#   - Emscripten SDK installed and activated (emsdk_env.sh sourced)
#
# Usage: ./scripts/build_web.sh [Debug|Release|MinSizeRel|RelWithDebInfo]
# ---------------------------------------------------------------------------
set -euo pipefail

BUILD_TYPE="${1:-Release}"
BUILD_DIR="build-web"

# Check for emscripten
if ! command -v emcc &> /dev/null; then
    echo "❌ Error: emcc not found in PATH."
    echo "   Install and activate emscripten: https://emscripten.org/docs/getting_started/"
    echo "   Then run: source /path/to/emsdk/emsdk_env.sh"
    exit 1
fi

echo "========================================"
echo " Building for Web/WASM (${BUILD_TYPE})"
echo "========================================"

emcmake cmake -S . -B "${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
    -DPLATFORM=Web

cmake --build "${BUILD_DIR}" --config "${BUILD_TYPE}" --parallel

echo ""
echo "✅ Web build complete!"
echo "   Files in: ${BUILD_DIR}/raylib-toolkit/"
echo "   Serve with: ./scripts/serve_web.sh"
echo "========================================"