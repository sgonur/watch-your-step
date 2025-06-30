# Watch Your Step

This project implements a single-player platform game on the Basys 3 FPGA board using Verilog. All graphics and logic are rendered through a 640x480 VGA display, and gameplay is entirely hardware-driven.

# Project Description

In **Watch Your Step**, the player controls a character that must:
- Jump over randomly placed holes in a platform.
- Collect balls that appear at random heights.
- Avoid falling to preserve lives.

The player charges jumps by holding `btnU`, powering a vertical bar that determines jump height. The longer the hold, the higher the jump. The player scores points by colliding with moving balls, and loses lives by falling into holes.

The game ends when all lives are lost and can be restarted using `btnR`.

---

# Modules Overview

### 1. `vga_sync`
Generates `Hsync`, `Vsync`, `video_on`, `hcount`, and `vcount` for 640x480 VGA signal timing.

### 2. `pixel_display`
Determines RGB values for each pixel, drawing the player, platform, hole, power bar, borders, and ball based on game state.

### 3. `player_movement`
Controls the player's position and jumping behavior using a 7-state FSM:
- `s_idle`, `s_chg`, `s_asc`, `s_desc`, `s_fall`, `s_dead`, `s_relive`

### 4. `ball_controller`
Handles ball movement, collision detection, score updates, and flashing when hit.

### 5. `hole_gen`
Randomly generates and animates platform holes with variable width (41–71 px).

### 6. `ball_gen`
Randomizes ball height (192–252 px) and moves it horizontally across the screen.

### 7. `top`
Brings together all modules, handles display output, user input, and game state coordination. Includes:
- Score/life tracking
- Collision and death detection
- Seven-segment display output

---

# Controls

 Input | Function 
------------------------
 `btnU` | Charge & perform jump 
 `btnR` | Reset the game 
 `sw[3:0]` | Set number of lives
 `btnL` | Load the Lives

---

# Build & Simulation Notes

- All design logic uses **assign-only combinational logic** and **FDREs** for flip-flops.
- No procedural blocks (`always`, `if`, `case`, etc.) used.
- Simulation was done module-by-module; `vga_sync` tested with waveform outputs.
- Frame-based timing used to flash objects and control animation pacing (~60Hz).
