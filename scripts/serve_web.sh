#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# serve_web.sh — Serve the web build on a local HTTP server
#
# Usage: ./scripts/serve_web.sh [port] [build_dir]
# ---------------------------------------------------------------------------
set -euo pipefail

PORT="${1:-8080}"
BUILD_DIR="${2:-build-web/raylib-toolkit}"

if [ ! -d "${BUILD_DIR}" ]; then
    echo "❌ Error: Build directory not found: ${BUILD_DIR}"
    echo "   Run ./scripts/build_web.sh first"
    exit 1
fi

echo "========================================"
echo " Serving web build on http://localhost:${PORT}"
echo " Directory: ${BUILD_DIR}"
echo " Press Ctrl+C to stop"
echo "========================================"

cd "${BUILD_DIR}"
python3 -m http.server "${PORT}"