# Movement Controller

First-person character controller for Godot 4.6 with polished movement mechanics.

## Features

### Core Movement
- **Walk / Sprint / Crouch** - Three base movement speeds with smooth transitions
- **Slide** - Momentum-based sliding triggered by crouching during sprint
- **Jump** - With coyote time (0.1s grace period) and input buffering for responsive platforming
- **Headroom Detection** - Prevents standing up in tight spaces

### Camera & View
- **Dynamic FOV** - Increases during sprint (85°) and slide (93.5°) for speed sensation
- **Smooth Camera Height** - Adjusts based on stance (standing/crouching/sliding)
- **Leaning** - Tilt left/right to peek around corners with collision detection
- **Mouse Look** - First-person camera control

### Polish Features
- **Weapon Retraction** - Automatically pulls weapon back when near walls using raycasting
- **Jump Buffering** - Pre-landing jump inputs register for 0.1s, improving responsiveness
- **State Preservation** - Landing restores your previous movement state intelligently
- **Smooth Interpolation** - All visual transitions use lerping for polished feel

## Controls

| Action | Keys | Description |
|--------|------|-------------|
| Move | WASD | Forward/Back/Strafe |
| Jump | Space | Jump (buffered & with coyote time) |
| Sprint | Shift | Toggle between walk and sprint |
| Crouch | C or Ctrl | Crouch (or slide from sprint) |
| Lean | Q / E | Lean left/right |
| Look | Mouse | First-person camera |
| Capture Mouse | Left Click | Lock cursor for look control |
| Release Mouse | Escape | Free cursor |

## Quick Start

1. Add [player.tscn](player.tscn) to your scene
2. Ensure your level has collision geometry (layer 2)
3. Click in-game to capture mouse, then use WASD + Space + Shift

## Scene Structure

```
CharacterBody3D (PlayerController)
├── Collider (CollisionShape3D - CapsuleShape3D)
└── Head (Node3D)
    ├── Camera3D
    │   ├── Hands (Node3D with weapon model)
    │   └── WeaponTip (Marker3D for raycast endpoint)
    ├── HeadroomChecker (ShapeCast3D)
    ├── LeanLeftChecker (ShapeCast3D)
    └── LeanRightChecker (ShapeCast3D)
```

## Technical Notes

- Built on `CharacterBody3D` with kinematic physics
- Uses Godot's built-in gravity and `move_and_slide()`
- 6-state machine: WALK, SPRINT, CROUCH, SLIDE, JUMP, FALL
- Configured for Jolt Physics
- Godot 4.6 • Forward Plus renderer
