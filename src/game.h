#pragma once

#include "model.h"

// ---------------------------------------------------------------------------
// MVU (Model-View-Update) game functions
//
//   GameState init()              → Create initial game state
//   void update(dt, GameState&)  → Mutate state (logic only, no rendering)
//   void view(const GameState&)  → Render state (read-only, no mutations)
//   void shutdown()               → Free loaded resources
// ---------------------------------------------------------------------------
namespace game {

GameState init();
void update(float dt, GameState& state);
void view(const GameState& state);
void shutdown();

} // namespace game