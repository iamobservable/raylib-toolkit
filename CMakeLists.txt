cmake_minimum_required(VERSION 3.20...3.30)

# ---------------------------------------------------------------------------
# Project definition
# ---------------------------------------------------------------------------
project(raylib-toolkit
    VERSION 0.1.0
    LANGUAGES C CXX
)

# ---------------------------------------------------------------------------
# C++ standard
# ---------------------------------------------------------------------------
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ---------------------------------------------------------------------------
# Generate compile_commands.json for IDE/tooling support
# ---------------------------------------------------------------------------
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------
if(EMSCRIPTEN)
    set(PLATFORM "Web" CACHE STRING "Target platform")
else()
    set(PLATFORM "Desktop" CACHE STRING "Target platform")
endif()

message(STATUS "[raylib-toolkit] Target platform: ${PLATFORM}")

# ---------------------------------------------------------------------------
# raylib dependency
# ---------------------------------------------------------------------------
# Uses FetchContent to download and build raylib from source.
# To use a local/system-installed raylib instead, pass:
#   -DFETCHCONTENT_SOURCE_DIR_RAYLIB=<path-to-raylib-source>
#   OR
#   -DUSE_FIND_PACKAGE_RAYLIB=ON  (requires raylib installed on system)
# ---------------------------------------------------------------------------
set(RAYLIB_VERSION "6.0" CACHE STRING "raylib version to fetch")

option(USE_FIND_PACKAGE_RAYLIB "Use find_package instead of FetchContent" OFF)

if(USE_FIND_PACKAGE_RAYLIB)
    find_package(raylib ${RAYLIB_VERSION} REQUIRED)
else()
    include(FetchContent)

    FetchContent_Declare(
        raylib
        DOWNLOAD_EXTRACT_TIMESTAMP OFF
        URL https://github.com/raysan5/raylib/archive/refs/tags/${RAYLIB_VERSION}.tar.gz
        FIND_PACKAGE_ARGS ${RAYLIB_VERSION}
    )

    # Suppress raylib examples/games build
    set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(BUILD_GAMES OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(raylib)
endif()

# ---------------------------------------------------------------------------
# Game executable
# ---------------------------------------------------------------------------
set(GAME_SOURCES
    src/main.cpp
    src/game.cpp
)

set(GAME_HEADERS
    src/model.h
    src/game.h
)

add_executable(${PROJECT_NAME} ${GAME_SOURCES} ${GAME_HEADERS})

target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(${PROJECT_NAME} PRIVATE raylib)

# ---------------------------------------------------------------------------
# Warnings and compiler flags
# ---------------------------------------------------------------------------
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang|AppleClang")
    target_compile_options(${PROJECT_NAME} PRIVATE
        -Wall -Wextra -Wpedantic
        -Wno-unknown-pragmas
    )
elseif(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /W4)
endif()

# ---------------------------------------------------------------------------
# Asset path definition
# ---------------------------------------------------------------------------
# ASSETS_PATH is set to the absolute source path during development.
# For release builds, consider changing this to a relative path
# appropriate for the target platform's packaging structure.
# ---------------------------------------------------------------------------
if(NOT DEFINED ASSETS_PATH)
    set(ASSETS_PATH "${CMAKE_CURRENT_SOURCE_DIR}/resources/" CACHE PATH "Path to game assets")
endif()
target_compile_definitions(${PROJECT_NAME} PUBLIC ASSETS_PATH="${ASSETS_PATH}")

# ---------------------------------------------------------------------------
# Resource copying (post-build for desktop, pre-build for web)
# ---------------------------------------------------------------------------
if(PLATFORM STREQUAL "Web")
    add_custom_command(
        TARGET ${PROJECT_NAME} PRE_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_CURRENT_SOURCE_DIR}/resources
            $<TARGET_FILE_DIR:${PROJECT_NAME}>/resources
    )
else()
    add_custom_command(
        TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_CURRENT_SOURCE_DIR}/resources
            $<TARGET_FILE_DIR:${PROJECT_NAME}>/resources
    )
endif()

# ---------------------------------------------------------------------------
# WebAssembly (Emscripten) configuration
# ---------------------------------------------------------------------------
if(PLATFORM STREQUAL "Web")
    # Set output to .html so emscripten generates the full web package
    set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".html")

    target_link_options(${PROJECT_NAME} PUBLIC
        -sUSE_GLFW=3
        -sASSERTIONS=1
        -sWASM=1
        -sASYNCIFY
        -sGL_ENABLE_GET_PROC_ADDRESS=1
        --preload-file ${CMAKE_CURRENT_SOURCE_DIR}/resources@resources
    )

    # Use custom shell file if available, otherwise emscripten default
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/web/shell.html")
        target_link_options(${PROJECT_NAME} PUBLIC
            --shell-file ${CMAKE_CURRENT_SOURCE_DIR}/web/shell.html
        )
    endif()
endif()

# ---------------------------------------------------------------------------
# macOS frameworks
# ---------------------------------------------------------------------------
if(APPLE AND NOT PLATFORM STREQUAL "Web")
    target_link_libraries(${PROJECT_NAME} PRIVATE "-framework IOKit")
    target_link_libraries(${PROJECT_NAME} PRIVATE "-framework Cocoa")
    target_link_libraries(${PROJECT_NAME} PRIVATE "-framework OpenGL")
endif()

# ---------------------------------------------------------------------------
# Output directory
# ---------------------------------------------------------------------------
set_target_properties(${PROJECT_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${PROJECT_NAME}
)

# ---------------------------------------------------------------------------
# Sanitizers (desktop only, debug builds)
# ---------------------------------------------------------------------------
option(ENABLE_ASAN "Enable AddressSanitizer" OFF)
option(ENABLE_UBSAN "Enable UndefinedBehaviorSanitizer" OFF)
option(ENABLE_TSAN "Enable ThreadSanitizer" OFF)

if(ENABLE_ASAN AND NOT PLATFORM STREQUAL "Web")
    target_compile_options(${PROJECT_NAME} PRIVATE -fsanitize=address -fno-omit-frame-pointer)
    target_link_options(${PROJECT_NAME} PRIVATE -fsanitize=address)
endif()

if(ENABLE_UBSAN AND NOT PLATFORM STREQUAL "Web")
    target_compile_options(${PROJECT_NAME} PRIVATE -fsanitize=undefined)
    target_link_options(${PROJECT_NAME} PRIVATE -fsanitize=undefined)
endif()

if(ENABLE_TSAN AND NOT PLATFORM STREQUAL "Web")
    target_compile_options(${PROJECT_NAME} PRIVATE -fsanitize=thread)
    target_link_options(${PROJECT_NAME} PRIVATE -fsanitize=thread)
endif()

# ---------------------------------------------------------------------------
# Development conveniences
# ---------------------------------------------------------------------------
option(ENABLE_DEBUG "Enable debug build with extra logging" OFF)
if(ENABLE_DEBUG)
    target_compile_definitions(${PROJECT_NAME} PRIVATE DEBUG)
endif()