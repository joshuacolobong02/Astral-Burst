# Astral Burst - Game Documentation

**Astral Burst** is a high-octane Godot 4.x space shooter. Players pilot a starship through various celestial stages, engaging in combat with enemy formations and bosses while navigating complex meteor hazards.

---

## 1. Core Gameplay Mechanics

### Player Movement

- **Desktop:** Movement is mapped to `WASD` and Arrow Keys. The ship features a dynamic **Horizontal Tilt** effect, rotating up to 15 degrees based on lateral movement.
- **Mobile:** Supports **Relative Drag** interaction. Players can touch and drag anywhere on the screen; the ship moves relative to the finger's displacement.
- **Screen Clamping:** The player's position is strictly constrained within the viewport boundaries (402x874) to prevent moving off-screen.

### Combat System

- **Auto-Firing:** The ship automatically fires lasers at a defined interval (`fire_shoot`).
- **Fire Rate Upgrades:** The firing interval decreases by 0.05s upon reaching each new game stage, down to a minimum cap of 0.1s.
- **Laser Animation:** Lasers feature a procedural stretching effect based on their vertical velocity, making them appear more dynamic as they travel.
- **Health & Respawn:**
  - The player starts with **3 lives**.
  - Collision with an enemy or meteor results in immediate death.
  - Upon death, an explosion animation plays, and the player respawns after a **0.8s delay**.
  - **Dynamic AI Targeting:** Enemies are aware of the player's lifecycle. When a player dies, enemies will search for the new instance in the `player` group upon respawn. While the player is dead, enemies continue to fire straight down.
  - If lives reach zero, the game transitions to the Game Over screen.

---

## 2. Scoring & Progression Rules

### Scoring Table

| Entity Type         | Points Awarded | Notes                                                       |
| :------------------ | :------------- | :---------------------------------------------------------- |
| **Bosses**          | 500+           | Triggers 0.05x time-scale cinematic and heavy camera shake. |
| **Guardians**       | 100            | Includes orbital and infinity-pattern enemies.              |
| **Coins**           | 500            | Collected via the Gold Power-up.                            |
| **Meteors/Minions** | 0/50           | Mostly hazards; some meteors award minor points.            |

- **High Scores:** High scores are persisted locally in `user://save.data`.

### Stage Progression

Progression is linked to the player's total score. Reaching a milestone triggers a background transition and initiates a boss encounter for that celestial region.

1.  **SPACE:** 0 pts (Start)
2.  **MOON:** 10,000 pts
3.  **MARS:** 25,000 pts
4.  **ASTEROID BELT:** 35,000 pts
5.  **JUPITER:** 50,000 pts
6.  **SATURN:** 75,000 pts
7.  **URANUS:** 90,000 pts
8.  **NEPTUNE:** 105,000 pts
9.  **SCATTERED DISC:** 125,000 pts
10. **KUIPER BELT:** 140,000 pts
11. **OORT CLOUD:** 160,000 pts

---

## 3. Hazard & Formation Systems

### Structured Meteor Formations

The game cycles through a wave sequence of formations including:

- **V-Formation:** A 5-meteor arrowhead.
- **Circle:** 10 meteors falling in a synchronized ring.
- **Wave:** 8 meteors following a serpentine sine-wave path with synchronized `phase_offset` for a "snake" effect.
- **Diagonal Rain:** Staggered meteors sweeping the screen at a 45-degree angle.
- **Spiral:** A 12-meteor winding sequence spawning from the center.

Wave patterns (V, Diamond, Squad, X_PATTERN, Circle, etc.) rotate deterministically via `WAVE_SEQUENCE`.

### Enemy Behaviors

- **Basic:** Straight descent.
- **Diver:** High-speed vertical or tracking dives.
- **Orbital/Infinity:** Move in complex circular or figure-eight paths around a center point.
- **Protectors & Guardians:** Shield-like units that orbit bosses or are thrown by them. They now feature **Spread Attacks**, throwing patterns of 3 meteors in a fan-like shape to increase difficulty and visual engagement.

---

## 4. Power-up System

Power-ups spawn on timers (BoostManager) and during wave gaps. Coins drop from destroyed enemies (15% chance). Laser, Shield, and Speed boosts are spawned by BoostManager based on game state.

### Power-up Types

- **Laser Boost (Blue):**
  - **Effect:** Increases fire rate significantly (0.4x current interval) and adds a 5-way spread shot.
  - **Duration:** 20 seconds.
  - **Visual:** Ship glows blue while active.
- **Shield (Green):**
  - **Effect:** Grants one-time protection from a hit.
  - **Visual:** A rotating blue energy sphere surrounds the ship.
- **Coin (Gold):**
  - **Effect:** Grants an immediate 500-point score bonus.

### Visual Presentation

All power-ups feature high-visibility enhancements:

- `z_index` set to 150 to render above all environment layers.
- Procedural pulsing background glows and outer-ring expansion animations.
- Themed color coding (Blue, Green, Gold).

---

## 5. Visual & Audio Systems

### Visual Effects (VFX)

- **Glow Environment:** Uses `WorldEnvironment` with 0.15 Bloom and 0.4 Intensity for glowing projectiles and engines.
- **Atmospheric Tint:** A `CanvasModulate` node applies a `(0.7, 0.7, 0.8)` tint to create a consistent deep-space aesthetic.
- **Parallax Stabilization:** Planetary backgrounds and stars use `ParallaxBackground`. The `scroll_offset` is rounded to integers in the `_process` loop to eliminate sub-pixel jittering.
- **Hit Feedback:** Enemies use a specialized `hit_outline.gdshader` to flash white and perform a scale "punch" when taking damage.

### HUD & User Interface

- **Score Pop:** Collecting points triggers a brief scale "pop" animation on the score label.
- **Life Indicators:** Animated heart icons that pulse/glow when lost.
- **Laser Boost Indicator:** A dedicated progress bar appears below the score when a Laser Boost is active, showing the remaining duration.
- **Safe Zone Rendering:** All critical UI elements are positioned at least 15px from the edges to accommodate various mobile display cutouts.

---

## 6. Technical Configuration

### Input Mapping

- `left`/`right`/`up`/`down`: Directional movement.
- `shoot`: Manual fire (Spacebar).
- `pause`: Pause game (P key).
- `reset`: Reload current scene (Shift+R).
- `quit`: Close application (Esc).

### Physics Layers & Groups

- **Physics Layer 1:** Player
- **Physics Layer 2:** Enemy
- **Physics Layer 3:** Laser
- **Physics Layer 4:** borderTop (Utility)
- **Group "player":** Used for dynamic AI targeting and respawn synchronization.

### Critical Code Rules

- **Godot 4 Setters:** Internal variable assignments to `score` or `lives` in `game.gd` must use the `self.` prefix (e.g., `self.score += 100`) to ensure the HUD update logic is triggered.
- **Power-up Container:** Power-ups must be added to the `PowerupContainer` node to ensure they fall at a consistent speed independent of ParallaxBackground scaling.
- **Laser Pooling:** Player emits `laser_shot(scene, position, speed_mult)`; `game.gd` spawns lasers via pool. Lasers use `reset(pos, speed_mult)` to apply player speed multipliers correctly.

### Rendering

- **Method:** Renderer Compatibility (HTML export / Web-optimized).
- **Viewport:** 402x874 (Vertical Aspect Ratio).
