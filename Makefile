# ---------------------------------------------------------------------------
# raylib-toolkit Makefile — convenience targets for development
# ---------------------------------------------------------------------------
# Usage:
#   make            Build the project
#   make setup      Configure CMake and link compile_commands.json
#   make build      Build the project (runs setup if needed)
#   make run        Build and run the game
#   make web        Build for web/WASM
#   make serve      Serve the web build locally
#   make format     Run clang-format on source files
#   make check      Check formatting + run clang-tidy
#   make clean      Remove build directory and symlink
# ---------------------------------------------------------------------------

BUILD_DIR   := build
WEB_DIR     := build-web
NAME        := raylib-toolkit
EXECUTABLE  := $(BUILD_DIR)/$(NAME)/$(NAME)

# ---------------------------------------------------------------------------
# Phony targets
# ---------------------------------------------------------------------------
.PHONY: all setup build run web serve format check tidy clean

# ---------------------------------------------------------------------------
# Default
# ---------------------------------------------------------------------------
all: build

# ---------------------------------------------------------------------------
# Setup — configure CMake and create compile_commands.json symlink
# ---------------------------------------------------------------------------
setup: compile_commands.json

compile_commands.json: $(BUILD_DIR)/compile_commands.json
	@ln -sf $(BUILD_DIR)/compile_commands.json compile_commands.json
	@echo "✅ Linked compile_commands.json"

$(BUILD_DIR)/compile_commands.json:
	@echo "⚙️  Configuring CMake..."
	cmake -S . -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=Release

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
build: setup
	@echo "🔧 Building..."
	cmake --build $(BUILD_DIR) --parallel

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
run: build
	@cd $(BUILD_DIR)/$(NAME) && ./$(NAME)

# ---------------------------------------------------------------------------
# Web build
# ---------------------------------------------------------------------------
web: setup
	@echo "🌐 Building for web..."
	emcmake cmake -S . -B $(WEB_DIR) -DCMAKE_BUILD_TYPE=Release -DPLATFORM=Web
	cmake --build $(WEB_DIR) --parallel

# ---------------------------------------------------------------------------
# Serve web build
# ---------------------------------------------------------------------------
serve:
	@cd $(WEB_DIR)/$(NAME) && python3 -m http.server 8080

# ---------------------------------------------------------------------------
# Format
# ---------------------------------------------------------------------------
format:
	@echo "🎨 Formatting..."
	clang-format -i src/*.cpp src/*.h
	@echo "✅ Formatted"

# ---------------------------------------------------------------------------
# Check — format check (strict) + clang-tidy (advisory)
# ---------------------------------------------------------------------------
check: setup
	@echo "🔍 Checking formatting..."
	@clang-format --dry-run --Werror src/*.cpp src/*.h && echo "✅ Format OK" || (echo "❌ Format issues (run: make format)" && exit 1)
	@echo "🔍 Running clang-tidy..."
	-clang-tidy -p $(BUILD_DIR) src/main.cpp src/game.cpp src/model.h src/game.h 2>&1 | grep -E "^(src/|warning:|error:)" || true
	@echo "✅ Check complete (clang-tidy warnings are advisory)"

# ---------------------------------------------------------------------------
# Clean
# ---------------------------------------------------------------------------
clean:
	@echo "🧹 Cleaning..."
	rm -rf $(BUILD_DIR) $(WEB_DIR) compile_commands.json
	@echo "✅ Cleaned"