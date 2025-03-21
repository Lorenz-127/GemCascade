# GemCascade

A modern implementation of the classic match-3 puzzle game in Godot 4.4 Engine.

(WIP Screenshot)
![GemCascade Game](gemcascade-gameview.png)

## Project Summary

GemCascade is a modern implementation of the classic match-3 puzzle game Bejewelled, where players match gems of the same type to score points and create special gems with powerful effects. The game features a grid-based board filled with colorful gems, chain reactions, and various game modes to engage players in addictive puzzle gameplay.

### Core Gameplay

- Swap adjacent gems to create matches of three or more identical gems
- Matched gems disappear, causing gems above to fall and new gems to appear
- Create special gems by matching four or more gems in specific patterns
- Chain reactions and cascades provide bonus points
- Play in Classic mode until no valid moves remain

## Project Architecture

GemCascade uses a component-based architecture where distinct responsibilities are separated into specialized components that communicate via signals. This architecture makes the codebase more maintainable, testable, and extensible.

### Component Structure

The game is built around the following key components:

#### GridManager

- Handles grid creation and coordinate management
- Manages the 8x8 game board structure
- Converts between grid and pixel coordinates
- Renders grid visualization

#### GemManager

- Manages gem creation and properties
- Handles gem type differentiation
- Controls initial board population
- Implements gem pooling for performance

#### InputHandler

- Processes player input and gem selection
- Manages gem highlighting and selection states
- Validates swap attempts between gems
- Provides feedback for valid/invalid moves

#### MatchDetector

- Identifies valid matches on the board
- Detects horizontal and vertical matches
- Finds special patterns (L, T shapes)
- Marks gems for removal after matching

#### BoardController

- Manages board state and gem movements
- Controls gem falling mechanics
- Handles board refilling
- Processes turn sequences and cascades

#### ScoreManager

- Tracks and displays player score
- Calculates points based on match types
- Shows score animations and feedback
- Manages high score tracking

### Signal-Based Communication

Components communicate through a signal system that promotes loose coupling:

```
InputHandler → signals gem selection → BoardController
MatchDetector → signals matches found → BoardController
BoardController → signals score update → ScoreManager
```

## Setup Instructions

### Requirements

- Godot Engine 4.4

### Installation

1. Clone this repository
2. Open the project in Godot Engine
3. Open the main scene (`scenes/game/GameBoard.tscn`)
4. Press F5 or click the Play button to run the game

## Development Roadmap

The project is currently entering Sprint 3, which will focus on:

- [ ] Special gem implementation (line-blast, color-bomb)
- [ ] Special gem effects and combinations
- [ ] Advanced match patterns (L, T, + shapes)
- [ ] Classic mode implementation
- [ ] Score tracking enhancements

Future plans include:

- Desktop Version
- Timed mode implementation
- More game modes (Endless, Zen, etc.)
- Progressive difficulty system
- Additional special gem types
- Mobile Version
- Achievements system
- User profiles and high scores

## Credits

Developed by Lorenz B.

## License

This project is open source and available under the [MIT License](LICENSE.txt).

---

© 2025 Kalgorian Game Studio
