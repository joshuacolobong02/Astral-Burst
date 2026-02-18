# Astral Burst — Architecture Overview

## High-Level System Diagram

```mermaid
flowchart TB
    subgraph GameLayer["Game (game.gd)"]
        GM[GameManager Logic]
        Stage[Stage Transitions]
        Wave[Wave Spawning]
        Parallax[Parallax Controller]
        Save[Save/Load]
    end

    subgraph PlayerLayer["Player"]
        Player[player.gd]
        Input[Input Handler]
        Boosts[Boost State]
    end

    subgraph EnemyLayer["Enemies"]
        BaseEnemy[BaseEnemy]
        Boss[Boss Behaviors]
        Strategy[Movement Strategy]
        Fleet[FleetController]
    end

    subgraph PowerupLayer["Power-ups"]
        BoostMgr[BoostManager]
        PowerUp[power_up.gd]
    end

    subgraph UILayer["UI"]
        HUD[HUD]
        StartMenu[StartMenu]
        GameOver[GameOverScreen]
    end

    subgraph Projectiles["Projectiles"]
        Laser[Laser]
        EnemyLaser[EnemyLaser]
        Meteor[MeteorProjectile]
    end

    GM --> Stage
    GM --> Wave
    GM --> Parallax
    GM --> Player
    GM --> HUD
    GM --> StartMenu
    GM --> GameOver
    GM --> Save

    Player --> Input
    Player --> Boosts
    Player --> Laser

    BaseEnemy --> Strategy
    Fleet --> BaseEnemy
    Boss --> BaseEnemy

    BoostMgr --> PowerUp
    Player --> BoostMgr

    HUD --> GM
    StartMenu --> GM
    GameOver --> GM
```

---

## Scene Hierarchy (Simplified)

```
Game (game.tscn)
├── ParallaxBackground
│   ├── MoonLayer, EarthLayer, MarsLayer, ...
│   └── (Planetary sprites)
├── Player (or PlayerSpawnPos)
├── EnemyContainer
├── LaserContainer
├── PowerupContainer (created at runtime)
├── FleetController (created at runtime)
├── BoostManager (created at runtime)
├── Camera2D
├── UILayer
│   ├── HUD
│   ├── StartMenu
│   └── GameOverScreen
├── IntroEarth
├── DeathBlur, DeathFlash
└── SFX (HitSound, ExplodeSound, MusicPlayer, ...)
```

---

## Signal Flow

```mermaid
sequenceDiagram
    participant StartMenu
    participant Game
    participant Player
    participant HUD
    participant Enemies
    participant BoostManager

    StartMenu->>Game: start_game
    StartMenu->>Game: countdown_started
    Game->>Player: enable
    Game->>HUD: show

    loop Gameplay
        Player->>Game: laser_shot (optional)
        Player->>Game: killed
        Enemies->>Game: killed(points, pos)
        Enemies->>Game: hit
        PowerUp->>Player: apply_boost
        Player->>BoostManager: boost_collected / boost_expired
    end

    Player->>Game: killed (lives=0)
    Game->>HUD: GameOverScreen.show_screen()
```

---

## Movement Strategy Pattern

```mermaid
classDiagram
    class MovementStrategy {
        <<abstract>>
        update(meteor, delta)
    }
    class SimpleMovement {
        update(meteor, delta)
    }
    class DiamondStrategy {
        update(meteor, delta)
    }
    class FleetMovement {
        update(meteor, delta)
    }
    class DiveMovement {
        update(meteor, delta)
    }
    class MeteorProjectile {
        movement_strategy
    }
    class BaseEnemy {
        movement_strategy
    }

    MovementStrategy <|-- SimpleMovement
    MovementStrategy <|-- DiamondStrategy
    MovementStrategy <|-- FleetMovement
    MovementStrategy <|-- DiveMovement
    MeteorProjectile --> MovementStrategy
    BaseEnemy --> MovementStrategy
```

---

## Stage Progression Flow

```mermaid
flowchart LR
    SPACE -->|10k| MOON
    MOON -->|25k| MARS
    MARS -->|35k| ASTEROID_BELT
    ASTEROID_BELT -->|50k| JUPITER
    JUPITER -->|75k| SATURN
    SATURN -->|90k| URANUS
    URANUS -->|105k| NEPTUNE
    NEPTUNE -->|125k| SCATTERED
    SCATTERED -->|140k| KUIPER_BELT
    KUIPER_BELT -->|160k| OORT_CLOUD
```
