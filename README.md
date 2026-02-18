# Astral Burst

A high-octane 2D space shooter built with **Godot 4.6**. Pilot your starship through 11 celestial stages, battle enemy formations and bosses, and collect power-ups to survive increasingly intense waves of foes.

![Godot 4.6](https://img.shields.io/badge/Godot-4.6-478cbf?logo=godot-engine)
![GL Compatibility](https://img.shields.io/badge/Renderer-GL%20Compatibility-478cbf)

---

## Features

- **11 stages** — From Space to Oort Cloud, each with unique bosses and formations
- **Multiple input modes** — WASD/Arrow keys (desktop) or touch-and-drag (mobile)
- **Power-ups** — Laser Boost, Shield, and Coin for strategic advantage
- **Dynamic formations** — V, Circle, Wave, Spiral, Grid, and more enemy patterns
- **Parallax backgrounds** — Animated planetary environments per stage
- **Local high-score** — Persisted to `user://` storage

---

## Requirements

- **Godot Engine** 4.6 or later (4.2+ may work; tested with 4.6)
- **Renderer:** GL Compatibility (for Web export)

---

## Getting Started

### Running the game

1. Clone or download this repository.
2. Open the project in Godot 4.6 (`project.godot`).
3. Press **F5** or use **Project → Run** to launch.

### Building for Web

1. Open **Project → Export**.
2. Select the **Web** preset.
3. Adjust export path if needed (default: `../AstralTesting/index.html`).
4. Export and serve the output with a static HTTP server (e.g. `python -m http.server`).

### Build for other platforms

Add or edit export presets in **Project → Export** for Desktop (Windows/macOS/Linux) or Mobile (Android/iOS) as needed.

---

## Project Structure

```
Astral Burst/
├── asset/         # PNG sprites, audio, effects
├── script/        # GDScript and shaders
├── scene/         # Godot scenes (.tscn)
├── docs/          # Additional documentation
├── project.godot
├── export_presets.cfg
├── AstralBurstDocumentation.md   # Detailed gameplay & technical docs
└── README.md
```

---

## Controls

| Action     | Desktop              | Mobile   |
|-----------|----------------------|----------|
| Move      | WASD / Arrow keys    | Touch + drag |
| Shoot     | Space (auto-fire)    | Auto     |
| Reset     | Shift + R            | —        |
| Quit      | Esc                  | —        |
| Pause     | (if mapped)          | Settings |

---

## Documentation

- **[AstralBurstDocumentation.md](AstralBurstDocumentation.md)** — Gameplay mechanics, scoring, power-ups, stages, hazards, and technical configuration.
- **[docs/IMPROVEMENT_REPORT.md](docs/IMPROVEMENT_REPORT.md)** — Technical review, architecture notes, and improvement roadmap.

---

## License

(Add license information if applicable.)

---

## Acknowledgments

Built with [Godot Engine](https://godotengine.org/).
