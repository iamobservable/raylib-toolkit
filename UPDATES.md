# UPDATES.md — Project Status & Open Questions

_Last updated: 2026-05-07_

---

## Project Overview

A cross-platform **raylib C++ game template** using CMake, targeting **Desktop** and **Web (WASM/Emscripten)**. Based on raylib 6.0. Named **raylib-toolkit**.

---

## Decisions Made

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| 1 | **raylib-cpp OOP wrapper?** | **No — plain C API** | MVU makes raylib-cpp unnecessary. Model is plain data, view calls C draw functions, update doesn't touch raylib types. Can add later if needed. |
| 2 | **C++ standard?** | **C++17** | Broad support, modern features. |
| 3 | **Mobile scope?** | **Removed** | Not needed. |
| 4 | **Raylib integration?** | **FetchContent** | Confirmed. |
| 5 | **Game architecture?** | **MVU (Model-View-Update) with reference semantics** | `GameState init()`, `void update(float dt, GameState&)`, `void view(const GameState&)`. Zero-copy, const-qualified view, testable update. Named `GameState` to avoid raylib's `Model` type collision. |
| 6 | **CI/CD?** | **No**, for now | Can be added later. |
| 7 | **Code quality tooling?** | **Yes** — `.clang-format`, `.clang-tidy`, sanitizers, **Makefile** with compile_commands.json auto-linking | Makefile provides `setup`, `build`, `run`, `format`, `check`, `web`, `serve`, `clean`. |

---

## MVU Architecture

```
GameState init()                    → Create initial game state (plain data struct)
void update(float dt, GameState&)    → Mutate state in place (logic only, no rendering)
void view(const GameState&)          → Render state (read-only, no mutations)
void shutdown()                      → Free loaded resources
```

**Key design choices:**
- `GameState` (not `Model`) — avoids collision with raylib's `Model` type
- `update` takes `GameState&` (reference, not by-value) — zero overhead, idiomatic C++
- `view` takes `const GameState&` — compiler-enforced read-only, no accidental mutations
- `init` returns `GameState` by value (called once, at startup)
- All functions in `namespace game` — no class needed, just data + functions
- Input collection happens via raylib polling (between `update` and `view`)
- Window lifecycle managed in `main.cpp`, game logic in `game.cpp`

**File layout:**
- `src/model.h` — `GameState` struct (all mutable state lives here)
- `src/game.h` — MVU function declarations (`namespace game`)
- `src/game.cpp` — MVU function implementations
- `src/main.cpp` — Entry point, window init, main loop, web support

---

## Project Structure

```
.
├── CMakeLists.txt              # Main build system (FetchContent, Desktop/Web)
├── LICENSE                     # zlib license
├── Makefile                    # Convenience targets (setup, build, run, etc.)
├── README.md                   # Full documentation
├── UPDATES.md                  # This file — session continuity
├── .clang-format               # Code formatting config
├── .clang-tidy                 # Static analysis config
├── .gitignore
├── compile_commands.json → build/compile_commands.json  # Auto-linked
├── resources/
│   └── .gitkeep                # Placeholder for game assets
├── src/
│   ├── main.cpp                # Entry point + main loop
│   ├── model.h                 # GameState struct (all mutable state)
│   ├── game.h                  # MVU function declarations
│   └── game.cpp                # MVU function implementations
├── web/
│   └── shell.html              # Custom Emscripten HTML shell
└── scripts/
    ├── build_desktop.sh        # Desktop build helper
    ├── build_web.sh            # Web/WASM build helper
    ├── serve_web.sh             # Local HTTP server for web builds
    └── verify.sh               # Comprehensive verification script
```

---

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make setup` | Configure CMake + create `compile_commands.json` symlink |
| `make build` | Build the project (runs setup if needed) |
| `make run` | Build and run the game |
| `make web` | Build for Web/WASM (requires emscripten) |
| `make serve` | Serve web build on localhost:8080 |
| `make format` | Run clang-format on source files |
| `make check` | Format check (strict) + clang-tidy (advisory) |
| `make clean` | Remove build directory and symlink |

---

## CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `PLATFORM` | Auto-detected | `Desktop` or `Web` |
| `RAYLIB_VERSION` | `6.0` | raylib version fetched via FetchContent |
| `USE_FIND_PACKAGE_RAYLIB` | `OFF` | Use system-installed raylib |
| `FETCHCONTENT_SOURCE_DIR_RAYLIB` | _(unset)_ | Path to local raylib source |
| `ASSETS_PATH` | `${CMAKE_CURRENT_SOURCE_DIR}/resources/` | Compile-time asset path |
| `ENABLE_DEBUG` | `OFF` | Adds `DEBUG` compile definition |
| `ENABLE_ASAN` | `OFF` | Enable AddressSanitizer |
| `ENABLE_UBSAN` | `OFF` | Enable UndefinedBehaviorSanitizer |
| `ENABLE_TSAN` | `OFF` | Enable ThreadSanitizer |

---

## Verification

`./scripts/verify.sh` — 8 sections, 29 checks. Headless-aware (exit code 1 = graceful `IsWindowReady()` failure).

---

## All Open Questions Resolved

All three original questions have been answered and implemented:

1. ✅ **Q1 (raylib-cpp):** No — stick with plain C API
2. ✅ **Q5 (MVU):** Yes — implemented with `GameState&` reference semantics
3. ✅ **Q7 (Neovim tooling):** Done — Makefile + compile_commands.json auto-link

No pending questions remain.

---

## jj/git History

```
@  (pending)  MVU refactor, rename Model → GameState, fix verify.sh
○  tktqokyk   Add Makefile, fix clang-tidy config
○  rsxnuspz   Initial raylib C++ game template structure
◆  zzzzzzzz   (root)
```

---

## Reference Links

- raylib GitHub: https://github.com/raysan5/raylib
- raylib Wiki: https://github.com/raysan5/raylib/wiki
- raylib Templates: https://github.com/raysan5/raylib/wiki/raylib-templates
- C++ with raylib: https://github.com/raysan5/raylib/wiki/Using-raylib-with-Cpp
- raylib Examples: https://www.raylib.com/examples.html
- raylib CMake Wiki: https://github.com/raysan5/raylib/wiki/Working-with-CMake
- raylib Web (HTML5): https://github.com/raysan5/raylib/wiki/Working-for-Web-(HTML5)
- Elm Architecture: https://guide.elm-lang.org/architecture/
- raylib 6.0 Release: https://github.com/raysan5/raylib/releases/tag/6.0