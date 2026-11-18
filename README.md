# Makedam — Requirements Sheet

**Project:** Makedam — 2D top-down racing game, art style inspired by GTA 1/2
**Author:** Jernej Peter
**Date:** 2026-11-18 (v0.3 — rally scope)
**Status:** v0.3 — rally-style stage, city dropped
**Repository:** https://github.com/Jero009/makedam

---

## 1. Project Overview

A single-player, top-down 2D rally racing game in the visual style of Grand Theft Auto 1/2
(low-resolution pixel-art sprites, flat top-down perspective, muted rural color palette).
The player drives a rally car along a dirt/gravel stage through countryside and forest,
passing checkpoints in order and racing against the clock. Lap times are recorded;
the goal is a personal best.

- **Engine:** Godot 4.x (GDScript), Compatibility renderer (OpenGL — enables Web export)
- **Platform:** Linux + Windows desktop export (Web export as stretch)
- **Team:** Solo
- **Target playtime per session:** 3–10 minutes (single track, repeated attempts)

## 2. Functional Requirements

### FR1 — Player car
- FR1.1: Player controls a car with acceleration, braking, and steering (keyboard).
- FR1.2: Car has arcade drift physics: velocity lags behind facing direction,
  grip reduces when turning at speed.
- FR1.3: Car collides with trees, rocks, and obstacles; collisions slow it down,
  never trap the player (no getting stuck).

### FR2 — Track & checkpoints
- FR2.1: One rally stage built from tilemap: a winding dirt/gravel road through
  grass, forest, and rocks (rally terrain, no city).
- FR2.2: 6–10 checkpoints in a fixed order; the next checkpoint is visually marked.
- FR2.3: A lap = all checkpoints in order, back to start/finish line.

### FR3 — Timer & scoring
- FR3.1: Lap timer starts at the finish line and displays in-game (MM:SS.ms).
- FR3.2: Best lap time persists between sessions (saved to a local file).
- FR3.3: After each lap, show current lap time and personal best.

### FR4 — Game flow
- FR4.1: Main menu: Start Race, Quit, controls overview.
- FR4.2: Restart key returns to the start line instantly (< 1 second).
- FR4.3: Pause menu (Esc): Resume, Restart, Quit to menu.

### FR5 — Audio (basic)
- FR5.1: Engine sound whose pitch follows speed.
- FR5.2: Checkpoint pass "ping" and lap-complete sound.
- FR5.3: Background music loop (menu + gameplay).

## 3. Art & Audio Requirements

- **Style:** GTA 1/2 look — top-down pixel art, ~32×16 px car sprites,
  limited palette (≤ 16 colors), muted rural tones (grass greens, dirt browns,
  gray rocks, dark forest greens).
- **Player-facing resolution:** low-res pixel art upscaled with nearest-neighbor
  (integer zoom, no blurring).
- **Required assets:** 1 rally car (4 rotation states or free rotation),
  countryside tileset (~8–12 tiles: grass, dirt road, gravel, trees, rocks,
  hay bales), checkpoint marker, UI font (pixel font).
- **Tools:** LibreSprite (pixel art), jsfxr (SFX), free music loop (OpenGameArt / LMMS).

## 4. Technical Requirements

- TR1: Godot 4.x project, GDScript only (no C#), no paid plugins or assets.
- TR2: Version control: git + GitHub (https://github.com/Jero009/makedam),
  meaningful commits.
- TR3: Stable 60 FPS on a mid-range laptop.
- TR4: Export: Linux (X11) build + Windows build verified runnable.
- TR5: All third-party assets credited in a CREDITS file.

## 5. Scope Control (MVP vs Stretch)

**MVP (must ship):** FR1, FR2, FR3, FR4.1–4.2, TR1–TR4, one track, one car.

**Stretch goals (only after MVP works):**
- S1: Second car color/variant or opponent car (ghost).
- S2: Second track.
- S3: Minimap.
- S4: Web export (itch.io page).
- S5: Point-to-point stage mode (start → finish, instead of laps).

**Explicitly out of scope:** pedestrians, weapons, police, traffic, story,
multiplayer, city environments, saves beyond best-lap times.

## 6. Milestones (to be dated once the real deadline is set)

| # | Milestone | Deliverable |
|---|---|---|
| M1 | Project setup ✅ | Godot project, git repo, player car drives with drift physics |
| M2 | Track playable | Tilemap track + checkpoints + lap timer working |
| M3 | Game feel | Menu, restart, pause, sounds, collision polish |
| M4 | Ship | Exports verified, best-time saving, credits, docs |

## 7. Risks

| Risk | Mitigation |
|---|---|
| Art takes longer than code | Limited palette rule; tiles before decoration; placeholder grayboxes allowed in M1–M2 |
| Physics feel bad (car slides weird) | Simple velocity-lerp model, tune with 3 constants (grip, accel, turn rate) |
| Scope creep (wanting GTA features) | Section 5 is the contract; stretch goals only after M3 |

## 8. Acceptance Criteria

The project is "done" when: a person who has never seen it can launch the export,
read the controls from the menu, and complete a lap with a timer running —
without asking the developer anything.
