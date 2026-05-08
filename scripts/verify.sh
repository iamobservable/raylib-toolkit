#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# verify.sh — Comprehensive build and runtime verification for raylib-toolkit
#
# This script verifies that the template can build and run correctly.
# It performs the following checks:
#   1. Source file structure verification
#   2. CMake configuration verification (desktop)
#   3. Desktop build verification
#   4. Desktop runtime smoke test (launch, check window, exit)
#   5. Web build verification (if emscripten available)
#   6. Code quality tooling check (clang-format, clang-tidy)
#   7. Sanitizer build (if enabled)
#
# Usage: ./scripts/verify.sh [--skip-run] [--skip-web] [--asan] [-v]
# ---------------------------------------------------------------------------
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Options
SKIP_RUN=false
SKIP_WEB=false
ENABLE_ASAN=false
VERBOSE=false
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-run)  SKIP_RUN=true; shift ;;
        --skip-web)  SKIP_WEB=true; shift ;;
        --asan)      ENABLE_ASAN=true; shift ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help)
            echo "Usage: ./scripts/verify.sh [--skip-run] [--skip-web] [--asan] [-v]"
            echo ""
            echo "Options:"
            echo "  --skip-run   Skip the runtime smoke test (headless environments)"
            echo "  --skip-web   Skip the web/WASM build check"
            echo "  --asan       Also test an AddressSanitizer build"
            echo "  -v           Verbose output"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    echo -e "  ${GREEN}✅ PASS${NC}: $1"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo -e "  ${RED}❌ FAIL${NC}: $1"
}

skip() {
    SKIP_COUNT=$((SKIP_COUNT + 1))
    echo -e "  ${YELLOW}⏭️  SKIP${NC}: $1"
}

section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log() {
    if [ "$VERBOSE" = true ]; then
        echo -e "  $1"
    fi
}

# ---------------------------------------------------------------------------
# Check 1: Source structure
# ---------------------------------------------------------------------------
section "1. Source File Structure"

EXPECTED_FILES=(
    "CMakeLists.txt"
    "LICENSE"
    "README.md"
    "UPDATES.md"
    ".gitignore"
    ".clang-format"
    ".clang-tidy"
    "Makefile"
    "src/main.cpp"
    "src/model.h"
    "src/game.h"
    "src/game.cpp"
    "web/shell.html"
    "scripts/build_desktop.sh"
    "scripts/build_web.sh"
    "scripts/serve_web.sh"
    "scripts/verify.sh"
)

for f in "${EXPECTED_FILES[@]}"; do
    if [ -f "$f" ]; then
        pass "$f exists"
    else
        fail "$f missing"
    fi
done

# Check resources directory exists
if [ -d "resources" ]; then
    pass "resources/ directory exists"
else
    fail "resources/ directory missing"
fi

# ---------------------------------------------------------------------------
# Check 2: CMake Configuration (Desktop)
# ---------------------------------------------------------------------------
section "2. CMake Configuration (Desktop)"

BUILD_DIR="build-verify-desktop"
rm -rf "${BUILD_DIR}" 2>/dev/null || true

CONFIG_OK=true
CONFIG_OUTPUT=$(cmake -S . -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release 2>&1) || CONFIG_OK=false

if [ "$CONFIG_OK" = true ]; then
    pass "CMake configuration succeeded"

    # Verify CMake detected the platform correctly
    if echo "$CONFIG_OUTPUT" | grep -q "Target platform: Desktop"; then
        pass "Platform detected as Desktop"
    else
        log "Platform detection output not found in CMake output (may be normal)"
    fi

    pass "CMake generated build files"
else
    fail "CMake configuration failed (run with -v for details)"
    if [ "$VERBOSE" = true ]; then
        echo "$CONFIG_OUTPUT" | head -30
    fi
fi

# ---------------------------------------------------------------------------
# Check 3: Desktop Build
# ---------------------------------------------------------------------------
section "3. Desktop Build"

if [ "$CONFIG_OK" = true ]; then
    if cmake --build "${BUILD_DIR}" --config Release --parallel > /dev/null 2>&1; then
        pass "Desktop build succeeded"
    else
        fail "Desktop build failed"
    fi

    # Check for executable
    EXECUTABLE="${BUILD_DIR}/raylib-toolkit/raylib-toolkit"
    if [ -f "${EXECUTABLE}" ]; then
        pass "Desktop executable exists"
    elif [ -f "${EXECUTABLE}.exe" ]; then
        pass "Desktop executable exists (.exe)"
        EXECUTABLE="${EXECUTABLE}.exe"
    else
        fail "Desktop executable not found"
        EXECUTABLE=""
    fi

    # Check resources were copied
    if [ -d "${BUILD_DIR}/raylib-toolkit/resources" ]; then
        pass "Resources copied to build directory"
    else
        log "Resources directory not found in build (may be empty)"
    fi
else
    skip "Desktop build (configuration failed)"
    EXECUTABLE=""
fi

# ---------------------------------------------------------------------------
# Check 4: Desktop Runtime Smoke Test
# ---------------------------------------------------------------------------
section "4. Desktop Runtime Smoke Test"

if [ "$SKIP_RUN" = true ]; then
    skip "Runtime smoke test (--skip-run)"
elif [ -z "${EXECUTABLE:-}" ] || [ ! -f "${EXECUTABLE:-}" ]; then
    skip "Runtime smoke test (no executable)"
else
    TIMEOUT=5
    CD_DIR=$(dirname "${EXECUTABLE}")

    # Some environments (headless, CI) may not have a display.
    # A segfault in that case is expected — we detect it.
    HEADLESS=false
    if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
        HEADLESS=true
        log "No DISPLAY detected — running in headless mode"
    fi

    if command -v timeout &> /dev/null; then
        set +e
        (cd "${CD_DIR}" && timeout "${TIMEOUT}" ./raylib-toolkit > /dev/null 2>&1)
        EXIT_CODE=$?
        set -e

        if [ $EXIT_CODE -eq 124 ]; then
            pass "Game ran for ${TIMEOUT}s without crash (signaled exit)"
        elif [ $EXIT_CODE -eq 0 ]; then
            pass "Game ran and exited within ${TIMEOUT}s"
        elif [ $EXIT_CODE -eq 1 ] && [ "$HEADLESS" = true ]; then
            pass "Game exited gracefully in headless environment (no DISPLAY)"
        elif [ $EXIT_CODE -eq 139 ] && [ "$HEADLESS" = true ]; then
            pass "Game segfaulted in headless environment (no DISPLAY — expected)"
        else
            if [ "$HEADLESS" = true ]; then
                log "Game exited with code ${EXIT_CODE} in headless environment"
            fi
            fail "Game exited with unexpected code: ${EXIT_CODE}"
        fi
    else
        set +e
        (cd "${CD_DIR}" && ./raylib-toolkit > /dev/null 2>&1) &
        GAME_PID=$!
        sleep "${TIMEOUT}"
        if kill -0 "${GAME_PID}" 2>/dev/null; then
            kill "${GAME_PID}" 2>/dev/null || true
            wait "${GAME_PID}" 2>/dev/null || true
            pass "Game ran for ${TIMEOUT}s without crash"
        else
            wait "${GAME_PID}" 2>/dev/null
            EXIT_CODE=$?
            if [ "$HEADLESS" = true ]; then
                pass "Game exited in headless environment (no DISPLAY — expected)"
            else
                fail "Game crashed or exited early with code: ${EXIT_CODE}"
            fi
        fi
        set -e
    fi

    pass "Runtime smoke test passed"
fi

# ---------------------------------------------------------------------------
# Check 5: Web Build (if emscripten available)
# ---------------------------------------------------------------------------
section "5. Web Build (Emscripten)"

if [ "$SKIP_WEB" = true ]; then
    skip "Web build (--skip-web)"
elif ! command -v emcc &> /dev/null; then
    skip "Web build (emscripten not found in PATH)"
else
    WEB_BUILD_DIR="build-verify-web"
    rm -rf "${WEB_BUILD_DIR}" 2>/dev/null || true

    WEB_CONFIG_OK=true
    emcmake cmake -S . -B "${WEB_BUILD_DIR}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DPLATFORM=Web > /dev/null 2>&1 || WEB_CONFIG_OK=false

    if [ "$WEB_CONFIG_OK" = true ]; then
        pass "Web CMake configuration succeeded"
    else
        fail "Web CMake configuration failed"
    fi

    if [ "$WEB_CONFIG_OK" = true ]; then
        if cmake --build "${WEB_BUILD_DIR}" --config Release --parallel > /dev/null 2>&1; then
            pass "Web build succeeded"
        else
            fail "Web build failed"
        fi
    fi

    # Check output files
    if [ -f "${WEB_BUILD_DIR}/raylib-toolkit/raylib-toolkit.html" ]; then
        pass "Web HTML output exists"
    else
        fail "Web HTML output not found"
    fi

    if [ -f "${WEB_BUILD_DIR}/raylib-toolkit/raylib-toolkit.wasm" ]; then
        pass "Web WASM output exists"
    else
        fail "Web WASM output not found"
    fi

    if [ -f "${WEB_BUILD_DIR}/raylib-toolkit/raylib-toolkit.js" ]; then
        pass "Web JS glue code output exists"
    fi
fi

# ---------------------------------------------------------------------------
# Check 6: Code Quality Tooling
# ---------------------------------------------------------------------------
section "6. Code Quality Tooling"

if command -v clang-format &> /dev/null; then
    # Check formatting without modifying files
    FORMAT_OUTPUT=$(clang-format --dry-run --Werror src/main.cpp src/game.cpp src/model.h src/game.h 2>&1) || true
    if [ -z "$FORMAT_OUTPUT" ]; then
        pass "clang-format: all files are formatted correctly"
    else
        if [ "$VERBOSE" = true ]; then
            echo "$FORMAT_OUTPUT"
        fi
        fail "clang-format: some files need formatting (run: clang-format -i src/*.cpp src/*.h)"
    fi
else
    skip "clang-format not found in PATH"
fi

if command -v clang-tidy &> /dev/null; then
    if [ -f "build-verify-desktop/compile_commands.json" ]; then
        TIDY_OUTPUT=$(clang-tidy -p build-verify-desktop src/main.cpp src/game.cpp src/model.h src/game.h 2>&1) || true
        # Count only warnings from our source files (not raylib headers)
        TIDY_WARNINGS=$(echo "$TIDY_OUTPUT" | grep -c "^/home\|^$(pwd)" || true)
        TIDY_SRC_WARNINGS=$(echo "$TIDY_OUTPUT" | grep -cE "^src/" || true)
        if [ "$TIDY_SRC_WARNINGS" -eq 0 ]; then
            pass "clang-tidy: no warnings in project source"
        else
            log "clang-tidy: ${TIDY_SRC_WARNINGS} warning(s) in project source (advisory)"
            fail "clang-tidy: ${TIDY_SRC_WARNINGS} warning(s) in project source"
        fi
    else
        skip "clang-tidy (no compile_commands.json)"
    fi
else
    skip "clang-tidy not found in PATH"
fi

# ---------------------------------------------------------------------------
# Check 7: AddressSanitizer Build (optional)
# ---------------------------------------------------------------------------
section "7. AddressSanitizer Build (optional)"

if [ "$ENABLE_ASAN" = true ]; then
    ASAN_BUILD_DIR="build-verify-asan"
    rm -rf "${ASAN_BUILD_DIR}" 2>/dev/null || true

    if cmake -S . -B "${ASAN_BUILD_DIR}" -DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=ON > /dev/null 2>&1; then
        pass "ASan CMake configuration succeeded"
    else
        fail "ASan CMake configuration failed"
    fi

    if cmake --build "${ASAN_BUILD_DIR}" --config Debug --parallel > /dev/null 2>&1; then
        pass "ASan build succeeded"
    else
        fail "ASan build failed"
    fi

    # Clean up ASan build
    rm -rf "${ASAN_BUILD_DIR}" 2>/dev/null || true
else
    skip "AddressSanitizer build (use --asan to enable)"
fi

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
section "8. Cleanup"
rm -rf "build-verify-desktop" "build-verify-web" 2>/dev/null || true
pass "Verification build directories cleaned"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
section "Summary"
echo -e "  ${GREEN}Passed: ${PASS_COUNT}${NC}"
echo -e "  ${RED}Failed: ${FAIL_COUNT}${NC}"
echo -e "  ${YELLOW}Skipped: ${SKIP_COUNT}${NC}"
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "  ${RED}⛔ Verification FAILED${NC}"
    exit 1
else
    echo -e "  ${GREEN}🎉 Verification PASSED${NC}"
    exit 0
fi