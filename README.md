[Slovensko 🇸🇮](README.sl.md)

# Makedam — Requirements Sheet

**Project:** Makedam — 2D top-down racing game, art style inspired by GTA 1/2
**Author:** Jernej Peter
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

## 2. Functional Requirements

### FR1 — Player car
- FR1.1: The player controls a car with acceleration, braking, and steering (keyboard).
- FR1.2: Car has arcade drift physics: velocity lags behind facing direction,
  grip reduces when turning at speed.
- FR1.3: Car collides with trees, rocks, and obstacles; collisions slow it down.

### FR2 — Track & checkpoints
- FR2.1: One rally stage built from a tilemap: a winding dirt/gravel road through
  grass, forest, and rocks.
- FR2.2: 6–10 checkpoints in a fixed order; the next checkpoint is visually marked.
- FR2.3: A lap = all checkpoints in order, back to start/finish line.

### FR3 — Timer & scoring
- FR3.1: Lap timer starts at the finish line and displays in-game (MM:SS.ms).
- FR3.2: Best lap time persists between sessions (saved to a local file).
- FR3.3: After each lap, show current lap time and personal best.

### FR4 — Game flow
- FR4.1: Main menu: Start Race, Quit, controls overview.
- FR4.2: Restart key returns to the start line instantly.
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

- TR1: Godot 4.x project, GDScript only, no paid plugins or assets.
- TR2: Version control: git + GitHub (https://github.com/Jero009/makedam).
- TR3: Export: Linux (X11) build + Windows build verified runnable.
- TR4: All third-party assets credited in a CREDITS file.

