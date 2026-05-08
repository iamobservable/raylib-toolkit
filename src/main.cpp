#include "game.h"
#include "raylib.h"

#ifdef PLATFORM_WEB
#include <emscripten/emscripten.h>
#endif

#include <algorithm>

constexpr int SCREEN_WIDTH = 800;
constexpr int SCREEN_HEIGHT = 450;

// ---------------------------------------------------------------------------
// Web loop callback — forwards to MVU functions via void* arg
// ---------------------------------------------------------------------------
void frameLoop(void* arg) {
    auto* state = static_cast<game::GameState*>(arg);
    float dt = std::min(GetFrameTime(), 0.1F);
    game::update(dt, *state);
    game::view(*state);
}

int main() {
    SetConfigFlags(FLAG_WINDOW_RESIZABLE);
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "raylib-toolkit");

    if (!IsWindowReady()) {
        return 1;
    }

    InitAudioDevice();

    game::GameState state = game::init();

#ifdef PLATFORM_WEB
    emscripten_set_main_loop_arg(frameLoop, &state, 0, 1);
#else
    SetTargetFPS(60);

    while (!WindowShouldClose()) {
        float dt = std::min(GetFrameTime(), 0.1F);
        game::update(dt, state);
        game::view(state);
    }
#endif

    game::shutdown();
    CloseAudioDevice();
    CloseWindow();
    return 0;
}