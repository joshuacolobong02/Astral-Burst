# Astral Burst — QA Review Report

**Date:** February 18, 2025  
**Scope:** Full game review — scripts, mechanics, UI, performance, UX

---

## 1. Issues Found

### Critical (Fixed)

| # | Location | Issue | Fix |
|---|----------|-------|-----|
| 1 | `player.gd:31` | `god_mode = true` left enabled — player was invincible | Set to `god_mode = false` |
| 2 | `game.gd:653` (HEXAGON formation) | Ternary operator error: `target_pos.x > view_size.x/2 if view_size.x + 100 else -100` evaluated to boolean; ships spawned from wrong side | Corrected to `view_size.x + 100 if target_pos.x > view_size.x/2 else -100` |
| 3 | `game.gd:723–726` (shake_camera) | `tween_method` call malformed — `intensity, 0.0, duration` were inside lambda, causing tuple assignment to `camera.offset`; shake did not run correctly | Fixed to proper `tween_method(callable, from, to, duration)` with separate `damp_fn` and division-by-zero guard |

### Previously Fixed (Session)

- `enemy.gd`: `killed` emitted before `die()` for correct progression
- `boss_behavior.gd` / `boss_behavior_2.gd`: `VisibleOnScreenNotifier` override emits `killed` before `queue_free`
- Boss movement clamped with `BOSS_MARGIN` and `ROAM_Y_MAX_RATIO`
- Boost scene loading: runtime `load()` via `_load_boost_scene()` for reliability
- Physics callbacks: `_on_enemy_killed`, `power_up._do_collect`, `laser._destroy` wrapped in `call_deferred` to avoid physics-flush errors
- Guardian throw smoothed in BigBoss

### Medium (Verified / No Change)

| # | Location | Notes |
|---|----------|-------|
| 4 | `game_over_screen.tscn` | Restart button correctly connected: `pressed` → `_on_restart_button_pressed` → `restart.emit()` |
| 5 | `fleet_controller.gd:29` | `for row in rows` is correct — GDScript iterates 0..rows-1 over an int |
| 6 | `project.godot` | No `pause` action — **Fixed:** added `pause` mapped to **P** key |

### Minor

- `hud.gd`: `_animate_life_loss` is async and not awaited; animation still runs, no functional bug
- Shared hit shader material in `enemy.gd`: static `shared_hit_mat` reused — acceptable for visuals

---

## 2. Improvements Made

### Code Changes

1. **player.gd**
   - `god_mode = false` — player can take damage as intended

2. **game.gd**
   - HEXAGON formation: correct spawn-side logic for ships
   - `shake_camera`: correct `tween_method` usage with dampening and division-by-zero guard

### Logic & Flow

- Boss death and enemy death progression are robust
- Restart flow from game over works correctly
- Power-up and laser deferred callbacks avoid physics timing issues

---

## 3. Recommendations for Future Enhancement

### Input

- **Done:** `pause` action added (P key). Escape remains mapped to `quit`.

### Performance

- Continue object pooling for lasers; extend to explosions if needed
- Fleet dive spawns new `DiveMovement`/`SeekerMovement` — no pooling needed at current scale

### UX

- Difficulty milestones (25k, 50k, etc.) — consider tuning scroll speed or enemy spawn rate if spikes feel harsh
- Touch drag: `TOUCH_DELTA_CLAMP` already mitigates frame hitches; ensure it feels consistent on low-end devices

### Polish

- Pause screen: add blur or overlay for clear visual feedback
- Life loss animation: optionally `await` `_animate_life_loss` in HUD for stricter sync with other feedback
- Optional juice: small rumble/haptics on hit and power-up collect (if supported)

---

## 4. Summary

| Category | Status |
|----------|--------|
| Critical bugs | Fixed |
| Game logic | Verified |
| Player controls | Responsive (desktop + touch) |
| UI/restart flow | Working |
| Boss/enemy death | Fixed earlier in session |
| Shake / effects | Fixed |
| Performance | No major issues identified |

The game is stable and playable. Main issues addressed were player invincibility, HEXAGON spawn logic, and camera shake. Restart, power-ups, and combat flow behave as expected.
