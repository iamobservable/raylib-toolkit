#include "game.h"
#include "raylib.h"

namespace game {

GameState init() {
    GameState state;
    state.ballX = static_cast<float>(GetScreenWidth()) / 2.0F;
    state.ballY = static_cast<float>(GetScreenHeight()) / 2.0F;
    return state;
}

void update([[maybe_unused]] float dt, GameState& state) {
    // Bouncing ball demo
    state.ballX += state.ballSpeedX;
    state.ballY += state.ballSpeedY;

    if (state.ballX - state.ballRadius <= 0 ||
        state.ballX + state.ballRadius >= static_cast<float>(GetScreenWidth())) {
        state.ballSpeedX = -state.ballSpeedX;
    }
    if (state.ballY - state.ballRadius <= 0 ||
        state.ballY + state.ballRadius >= static_cast<float>(GetScreenHeight())) {
        state.ballSpeedY = -state.ballSpeedY;
    }
}

void view(const GameState& state) {
    BeginDrawing();
    ClearBackground(RAYWHITE);
    DrawCircleV(Vector2{state.ballX, state.ballY}, state.ballRadius, MAROON);
    DrawText("raylib-toolkit", 10, 10, 20, DARKGRAY);
    EndDrawing();
}

void shutdown() {
    // Unload game resources here
}

} // namespace game