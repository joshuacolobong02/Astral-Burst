# Suggested Documentation Structure

For scalability, consider splitting the monolithic `AstralBurstDocumentation.md` into focused documents:

---

## Proposed Layout

| Document | Purpose | Suggested Content |
|----------|---------|-------------------|
| **README.md** | Project entry point | Overview, requirements, run/build, controls |
| **docs/GAMEPLAY.md** | Player-facing mechanics | Movement, combat, scoring, power-ups, stages |
| **docs/TECHNICAL.md** | Developer reference | Input mapping, physics layers, code rules, rendering |
| **docs/ARCHITECTURE.md** | System design | Scene hierarchy, signals, strategy pattern |
| **docs/CONTRIBUTING.md** | Contribution guide | How to add stages, enemies, power-ups |
| **CHANGELOG.md** | Version history | Release notes |

---

## Migration Mapping

| Current Section | Target Document |
|-----------------|------------------|
| 1. Core Gameplay Mechanics | GAMEPLAY.md |
| 2. Scoring & Progression | GAMEPLAY.md |
| 3. Hazard & Formation Systems | GAMEPLAY.md |
| 4. Power-up System | GAMEPLAY.md |
| 5. Visual & Audio Systems | TECHNICAL.md |
| 6. Technical Configuration | TECHNICAL.md |

---

## When to Split

- **Now:** Keep single file if team is small and docs change rarely
- **Later:** Split when docs exceed ~300 lines or multiple people edit them
