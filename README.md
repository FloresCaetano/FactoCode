# CodeFactory

A 2D automation game built in **Godot 4.6** where the player doesn't control drones directly — they *program* them. Drones and the base Core are driven by short scripts written in a custom Python-like language, transpiled at runtime into sandboxed GDScript. Enemy difficulty is adjusted dynamically by a local prediction API based on how the player is actually playing.

---

## Core Systems

### Custom Transpiler
[`ExperimentalTranspiler`](mobiles-p/core/transpiler/experimental_transpiler.gd) is a hand-written lexer/parser that converts player-authored Python-style code (`if`, `elif`, `while`, `for`, assignments, function calls) into valid GDScript, line by line:

*   **Sandboxed variable access:** every user variable is rewritten into a dictionary lookup (`drone.vars["x"]`) instead of a real GDScript variable, so player code can't touch anything outside its own scope.
*   **Security blacklist:** rejects code containing `OS.`, `FileAccess`, `load(`, `preload(`, `queue_free`, `ClassDB`, `Engine.`, or scene changes, before it's ever compiled.
*   **Static validation:** unbalanced parentheses and unclosed strings are caught with the offending line number before transpilation even starts.
*   **Target-aware function set:** drones expose `move()`, `build()`, `extract()`; the Core exposes `craft_drone()`. Each call is translated into its real, `await`-based GDScript equivalent (e.g. `move(Vector2(2,1))` → `drone.move(Vector2(2,1)); await drone.move_finished`).
*   **Async-safe loops:** `while`/`for` blocks automatically get a small `await get_tree().create_timer(...).timeout` injected, so a player's infinite loop can't freeze the game.

The compiled script is instantiated as a standalone node whose `drone`/`core` reference is injected before it runs — the transpiler never touches the game's real objects directly.

### Adaptive Difficulty
[`waves_controller.gd`](mobiles-p/shared/components/waves_controller/waves_controller.gd) sends the current run state — core health, number of times the player used the AI helper, drones built — to a local prediction API (`POST /predict`) and receives back how many enemies to spawn and how much HP they should have, instead of using a fixed wave curve.

### AI Code Feedback
[`ia_helper.gd`](mobiles-p/shared/components/ia_helper.gd) sends the player's current code and last error to a local LLM endpoint (`POST /ask_ia`) and displays the response inline next to the code editor, so a struggling player gets a contextual hint instead of a raw error message.

> **Note:** the Python backend serving `/predict` and `/ask_ia` is a separate service and is not included in this repository — this repo covers the Godot/client side only.

### In-Editor Code Completion & Syntax Highlighting
Both [`drone.gd`](mobiles-p/entities/drones/drone.gd) and [`core.gd`](mobiles-p/structures/core/core.gd) configure a `CodeEdit` with custom autocomplete entries and a `CodeHighlighter` tuned to the mini-language's actual vocabulary (`move`, `build`, `extract`, `craft_drone`, control-flow keywords), so the in-game editor feels like a real (if tiny) IDE rather than a plain text box.

---

## Gameplay Loop

1. The Core crafts drones by consuming minerals (`brown_mineral`, `blue_mineral`).
2. The player writes a short script for a drone to move across a grid, extract minerals, or build structures (`turret`, `barrier`).
3. Waves of enemies spawn based on the adaptive-difficulty prediction; turrets and drones defend the Core.
4. If the player's code fails, the transpiler reports the exact line and reason, and the AI helper can suggest a fix.

---

## Requirements & Running the Project

*   **Engine:** Godot Engine **4.6**.
*   **Project root:** the actual Godot project lives in [`mobiles-p/`](mobiles-p) — open that folder from the Project Manager.
*   **Optional backend:** the adaptive difficulty and AI-help features expect a local Python API on `http://<host>:5000` exposing `/predict` and `/ask_ia` ([`GLOBAL.gd`](mobiles-p/core/singletones/GLOBAL.gd)). Without it, those two features fail silently (waves fall back to a default enemy count/HP, and the AI helper reports a failed request) but the rest of the game runs normally.

---

## Project Structure

```
mobiles-p/
├── core/
│   ├── transpiler/          # ExperimentalTranspiler (active) and PythonTranspiler (WIP alternative)
│   └── singletones/         # GLOBAL (API config, run state) and PATHS (scene reference registry)
├── entities/
│   ├── drones/               # Drone: in-game code editor, movement, build, extraction
│   └── enemies/              # Insect enemies spawned per wave
├── structures/
│   ├── core/                 # Core: drone crafting, inventory, its own programmable API
│   ├── turret/, barrier/, minerals/
├── shared/
│   ├── components/           # waves_controller (adaptive difficulty), ia_helper (AI feedback), hit/damage components
│   └── narrator/              # Tutorial narration system
└── gui/                       # HUD, inventory viewer
```

---

## Status

This is a technical prototype focused on the transpiler, adaptive difficulty, and tooling-for-players systems rather than final art or full level content — built to test whether a "program your units" mechanic could work as a teaching tool for programming logic.
