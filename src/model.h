#pragma once

// ---------------------------------------------------------------------------
// Game state — plain data, no logic
//
// All mutable game state lives here. Add fields as your game grows.
// Named GameState to avoid collision with raylib's Model type.
// ---------------------------------------------------------------------------
namespace game {

struct GameState {
    float ballX = 0.0F;
    float ballY = 0.0F;
    float ballSpeedX = 4.0F;
    float ballSpeedY = 3.0F;
    float ballRadius = 20.0F;
};

} // namespace game