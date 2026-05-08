# raylib-toolkit

A cross-platform raylib C++ game template using CMake. Build games for **Desktop** and **Web (WASM)** with a clean, minimal architecture.

Based on [raylib 6.0](https://github.com/raysan5/raylib).

## Features

- 🖥️ **Desktop** — Windows, Linux, macOS
- 🌐 **Web (WASM)** — Full Emscripten/WebAssembly support with custom shell
- 📦 **CMake FetchContent** — Automatically downloads and builds raylib 6.0
- 🧪 **Verification script** — Build + runtime smoke testing
- 🛡️ **Sanitizers** — AddressSanitizer, UBSan, ThreadSanitizer support
- 🔧 **Code quality** — clang-format and clang-tidy configs included
- 🏗️ **Modern C++17** — RAII, smart pointers, move semantics

## Quick Start

### Prerequisites

| Platform | Requirements |
|----------|-------------|
| Desktop  | CMake 3.20+, C/C++ compiler (GCC, Clang, MSVC) |
| Web      | Emscripten SDK ([install guide](https://emscripten.org/docs/getting_started/)) |

**Linux** users may also need: `libgl1-mesa-dev libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libxext-dev`

### Desktop Build

```bash
# Configure and build
cmake -S . -B build
cmake --build build

# Run
./build/raylib-toolkit/raylib-toolkit
```

Or use the build script:

```bash
./scripts/build_desktop.sh
```

### Web (WASM) Build

```bash
# Make sure emscripten is activated
source /path/to/emsdk/emsdk_env.sh

# Build
./scripts/build_web.sh

# Serve locally
./scripts/serve_web.sh
```

### Debug Build with Sanitizers

```bash
cmake -S . -B build-debug -DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=ON
cmake --build build-debug
```

## Project Structure

```
.
├── CMakeLists.txt           # Main CMake configuration
├── LICENSE                  # zlib license
├── README.md                # This file
├── UPDATES.md                # Project status & open questions
├── .clang-format            # Code formatting config
├── .clang-tidy              # Static analysis config
├── .gitignore
├── resources/               # Game assets (images, sounds, fonts)
├── src/
│   ├── main.cpp             # Entry point + main loop
│   ├── model.h              # GameState struct (all mutable state)
│   ├── game.h / game.cpp    # MVU functions (init/update/view/shutdown)
└── web/
    └── shell.html           # Custom Emscripten HTML shell
└── scripts/
    ├── build_desktop.sh     # Desktop build helper
    ├── build_web.sh         # Web/WASM build helper
    ├── serve_web.sh         # Local HTTP server for web builds
    └── verify.sh            # Comprehensive verification script
```

## Architecture

The template uses a **pragmatic MVU (Model-View-Update)** pattern inspired by Elm Architecture:

```cpp
// model.h — plain data, no logic
struct GameState {
    float ballX = 0.0F;
    float ballY = 0.0F;
    // ... all game state lives here
};

// game.h — pure functions, namespace-scoped
namespace game {
    GameState init();                      // Create initial state
    void update(float dt, GameState&);     // Mutate state (logic only)
    void view(const GameState&);           // Render state (read-only)
    void shutdown();                       // Free resources
}
```

**Why MVU?**
- **Separated concerns** — `update()` can't draw, `view()` can't mutate state
- **Testable** — `update()` is a pure function of `(dt, GameState&)`
- **Inspectable** — all state is in one `GameState` struct, easy to debug/serialize
- **Zero overhead** — reference-based update, no copy, no virtual dispatch
- **Scales** — add fields to `GameState` as your game grows

**Why not immutable (Elm-style)?** Because C++ games mutate by nature. Copying a struct on every frame is waste. The `const` on `view()` still gives you the key guarantee: rendering doesn't touch state.

- **Desktop**: Standard `while (!WindowShouldClose())` loop
- **Web**: `emscripten_set_main_loop_arg` — no code changes needed

### Expanding the State

Add fields to `GameState` and use them in `update()`/`view()`:

```cpp
// model.h
struct GameState {
    float ballX = 0.0F;
    float ballY = 0.0F;
    int score = 0;         // new field
    bool gameOver = false;  // new field
};
```

No class hierarchies, no virtual dispatch — just data and functions.

### Asset Paths

The `ASSETS_PATH` macro is defined in CMake:

```cpp
// In your code, use the ASSETS_PATH macro:
Texture2D tex = LoadTexture(ASSETS_PATH "textures/my_image.png");
```

During development it points to the source `resources/` directory. For release, change it to a relative path in CMakeLists.txt.

### Web Compatibility

- Uses `emscripten_set_main_loop` automatically on web builds (no blocking `while` loop)
- ASYNCIFY is enabled for `WindowShouldClose()` compatibility
- Custom shell file in `web/shell.html` provides a clean canvas

## CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `PLATFORM` | Auto-detected | Target platform: `Desktop` or `Web` |
| `RAYLIB_VERSION` | `6.0` | raylib version to fetch via FetchContent |
| `USE_FIND_PACKAGE_RAYLIB` | `OFF` | Use `find_package` instead of FetchContent |
| `FETCHCONTENT_SOURCE_DIR_RAYLIB` | _(unset)_ | Path to local raylib source (bypasses download) |
| `ASSETS_PATH` | `${CMAKE_CURRENT_SOURCE_DIR}/resources/` | Path to game assets |
| `ENABLE_DEBUG` | `OFF` | Enable debug build with extra logging |
| `ENABLE_ASAN` | `OFF` | Enable AddressSanitizer |
| `ENABLE_UBSAN` | `OFF` | Enable UndefinedBehaviorSanitizer |
| `ENABLE_TSAN` | `OFF` | Enable ThreadSanitizer |

### Using a Local raylib

If you have raylib source checked out locally:

```bash
cmake -S . -B build -DFETCHCONTENT_SOURCE_DIR_RAYLIB=/path/to/raylib
```

Or if raylib is installed on your system:

```bash
cmake -S . -B build -DUSE_FIND_PACKAGE_RAYLIB=ON
```

## Code Quality

### Formatting

```bash
# Check formatting
clang-format --dry-run --Werror src/*.cpp src/*.h

# Apply formatting
clang-format -i src/*.cpp src/*.h
```

### Static Analysis

```bash
# Requires a build directory with compile_commands.json
cmake -S . -B build
clang-tidy -p build src/main.cpp src/game.cpp
```

## Verification

Run the comprehensive verification script:

```bash
# Full verification (desktop build + runtime test)
./scripts/verify.sh

# Skip runtime smoke test (headless environments)
./scripts/verify.sh --skip-run

# Skip web build (no emscripten)
./scripts/verify.sh --skip-web

# Also test AddressSanitizer build
./scripts/verify.sh --asan

# Verbose output
./scripts/verify.sh -v
```

The verification script checks:
1. ✅ Source file structure completeness
2. ✅ CMake configuration for desktop
3. ✅ Desktop compilation
4. ✅ Desktop runtime smoke test (5-second run, no crash)
5. ✅ Web build (if emscripten available)
6. ✅ Code quality (clang-format, clang-tidy)
7. ✅ AddressSanitizer build (optional, `--asan`)

### Future Verification Enhancements

These approaches are not yet implemented but documented for future consideration:

- **Headless/CI testing** — Use raylib's `PLATFORM_MEMORY` backend for frame rendering without a display server, enabling automated testing in CI
- **Automated screenshot capture** — Render a frame, save to PNG, compare pixel-by-pixel against a reference image to detect rendering regressions
- **Web runtime testing** — Use `emrun` or Puppeteer to load the WASM build in a headless browser and verify it initializes correctly
- **Unit testing framework** — Integrate Catch2 or GoogleTest for testing game logic in isolation (without a window)
- **Performance benchmarking** — Track average frame time across N frames, compare against baseline, detect regressions

## Using C++ with raylib

This template follows the best practices from the [raylib C++ wiki](https://github.com/raysan5/raylib/wiki/Using-raylib-with-Cpp):

- **C++ brace initialization**: Uses `Vector2{ x, y }` instead of C-style compound literals
- **`std::string` compatibility**: Use `.c_str()` when passing to raylib C functions
- **MVU pattern**: State, logic, and rendering are separated into `GameState`, `update()`, and `view()`
- **No OOP wrapper**: Using raylib's C API directly — MVU makes raylib-cpp less relevant since the Model is plain data

### Adding `raylib-cpp`

If your project grows and you want the OOP wrapper (automatic `UnloadTexture` on destructors, method chaining, operator overloads), add it via FetchContent:

```cmake
# In CMakeLists.txt, after raylib setup:
FetchContent_Declare(
    raylib-cpp
    GIT_REPOSITORY https://github.com/RobLoach/raylib-cpp.git
    GIT_TAG master
)
FetchContent_MakeAvailable(raylib-cpp)
target_link_libraries(${PROJECT_NAME} PRIVATE raylib-cpp)
```

## License

This template is licensed under the [zlib license](LICENSE), the same as raylib.

---

*Built with [raylib](https://www.raylib.com/) — enjoy videogames programming!*