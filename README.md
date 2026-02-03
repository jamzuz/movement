# Player Controller

A feature-rich first-person character controller for Godot 4.6 with smooth movement mechanics including walking, sprinting, crouching, sliding, and jumping with advanced polish features.

## Features

### Movement States
- **Walk** - Default movement at 3.0 m/s
- **Sprint** - Faster movement at 7.0 m/s
- **Crouch** - Slower, lower movement at 2.0 m/s
- **Slide** - High-speed momentum-based sliding from sprint
- **Jump** - Vertical jump with 4.5 m/s velocity
- **Fall** - Airborne state with reduced control

### Advanced Mechanics

#### Coyote Time
Jump grace period of 0.1 seconds after leaving the ground, allowing players to jump slightly after walking off ledges for more forgiving platforming.

#### Jump Buffering
0.1 second input buffer that registers jump inputs slightly before landing, making jumps feel more responsive.

#### Momentum-Based Sliding
- Triggers when crouching during sprint
- Initial boost of 12.0 m/s in movement direction
- Gradual friction deceleration
- 0.7 second duration
- Ends early if speed drops below 5.0 m/s or player becomes airborne
- Transitions to crouch when finished

#### Headroom Detection
Prevents standing up when there's an obstacle above using a ShapeCast3D, ensuring realistic collision behavior in tight spaces.

#### Dynamic Camera Effects
- **FOV changes** based on movement state:
  - Normal: 80°
  - Sprint: 85°
  - Slide: 93.5°
- **Camera height** adjusts smoothly for crouch and slide states
- All transitions use lerp for smooth visual feedback

#### Smooth Collider Adjustment
Character capsule height smoothly interpolates between normal (2.0) and crouched (0.8) heights for polished state transitions.

### State Transition Logic
- Sprint → Slide when crouching during sprint
- Crouch ↔ Walk/Sprint with headroom checking
- Jump preserves previous movement state for landing
- Automatic downgrade from sprint to walk when stationary
- Smart landing restoration based on pre-jump state

## Controls

| Action | Input | Description |
|--------|-------|-------------|
| Forward | W | Move forward |
| Backward | S | Move backward |
| Left | A | Strafe left |
| Right | D | Strafe right |
| Jump | Space | Jump (works in air with coyote time) |
| Sprint | Shift | Toggle sprint/walk |
| Crouch | C or Ctrl | Crouch/uncrouch (slide from sprint) |
| Look | Mouse | First-person camera control |
| Capture Mouse | Left Click | Lock mouse for camera control |
| Release Mouse | Escape | Release mouse cursor |

## Setup

### Scene Structure
```
CharacterBody3D (player.gd)
├── Collider (CollisionShape3D with CapsuleShape3D)
└── Head (Node3D)
    ├── Camera3D
    └── Headroom_checker (ShapeCast3D)
```

### Required Components
1. **CollisionShape3D** with CapsuleShape3D - Main character collider
2. **Head Node3D** - Pivot for camera rotation
3. **Camera3D** - First-person view
4. **Headroom_checker ShapeCast3D** - Detects obstacles above the player

### Input Map Configuration
Ensure the following actions are defined in your project settings:
- Forward, Backward, Left, Right - Movement
- Jump, Sprint, Crouch - Action buttons

## Technical Details

### Constants

#### Movement
| Constant | Value | Description |
|----------|-------|-------------|
| `WALK_SPEED` | 3.0 | Base walking speed |
| `SPRINT_SPEED` | 7.0 | Sprint movement speed |
| `CROUCH_SPEED` | 2.0 | Crouched movement speed |
| `GROUND_ACCEL` | 10.0 | Acceleration on ground |
| `AIR_ACCEL` | 2.0 | Reduced acceleration while airborne |
| `JUMP_VELOCITY` | 4.5 | Vertical jump force |

#### Collider Heights
| Constant | Value | Description |
|----------|-------|-------------|
| `NORMAL_HEIGHT` | 2.0 | Standing capsule height |
| `CROUCH_HEIGHT` | 0.8 | Crouched capsule height |

#### Slide
| Constant | Value | Description |
|----------|-------|-------------|
| `SLIDE_BOOST` | 12.0 | Initial slide velocity |
| `SLIDE_FRICTION` | 10.0 | Deceleration rate |
| `SLIDE_TIME` | 0.7 | Maximum slide duration |
| `SLIDE_MIN_SPEED` | 5.0 | Speed threshold to maintain slide |

#### Camera
| Constant | Value | Description |
|----------|-------|-------------|
| `NORMAL_FOV` | 80.0 | Default field of view |
| `SPRINT_FOV` | 85.0 | FOV during sprint |
| `SLIDE_FOV` | 93.5 | FOV during slide |
| `NORMAL_CAMERA_Y` | -0.5 | Standing camera height offset |
| `SLIDE_CAMERA_Y` | -0.7 | Sliding camera height offset |

### State Machine
The controller uses an enum-based state machine (`States`) with six states:
- `JUMP` - Applied jump impulse frame
- `WALK` - Standard movement
- `FALL` - Airborne without jump
- `CROUCH` - Crouched movement
- `SPRINT` - Fast movement
- `SLIDE` - Momentum-based slide

State changes are managed through `change_state()` with a 50ms cooldown to prevent rapid state spam.

### Physics
- Extends `CharacterBody3D` for kinematic character physics
- Uses Godot's built-in gravity
- Implements `move_and_slide()` for collision handling
- Different acceleration values for ground vs. air control

## Usage

1. Add [player.tscn](player.tscn) to your scene
2. Ensure your level has collision geometry
3. Configure input actions in Project Settings
4. Click to capture mouse and use WASD + Space + Shift + Ctrl/C to move

## Notes

- Mouse must be captured (left-click) for camera control
- Headroom checker prevents standing in confined spaces
- State transitions preserve movement intent where logical
- Smooth interpolation on all visual changes for polish
- Works with Jolt Physics (project configured for it)

## Version
Godot 4.6 - Forward Plus renderer
