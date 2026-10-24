---
name: rg-rotate-godot
description: >-
  Comprehensive guide and workflow for developing 2D Godot 4.x games optimized for the ANBERNIC RG Rotate handheld console.
  Covers 720x720 square display layout, 100% physical gamepad navigation, pause menu input separation (set_input_as_handled),
  focus loss prevention, Android APK export, and automated ADB deployment pipeline.
---

# ANBERNIC RG Rotate - Godot 4.x Development Guide

This skill provides full guidelines, templates, and best practices for developing 2D games targeting the **ANBERNIC RG Rotate** (Android-based square display handheld console) using **Godot Engine 4.x**.

---

## 1. Target Hardware & Display Specifications

- **Device**: ANBERNIC RG Rotate (Android)
- **Display Resolution**: 720 × 720 pixels (Aspect Ratio 1:1, Square)
- **Renderer**: `gl_compatibility` (OpenGL ES 3.0 / Compatibility mode is strongly recommended for high performance and low battery consumption)
- **Orientation**: Fixed (Portrait / Landscape). Keep orientation fixed (`handheld/orientation = 1`) to avoid unnecessary mechanical stress on the physical rotating hinge.
- **Input Hardware**: Built-in physical gamepad
  - D-Pad (Up, Down, Left, Right)
  - Analog Sticks (Left Stick: Axis 0/1, Right Stick: Axis 2/3)
  - Action Buttons (A, B, X, Y)
  - Shoulder / Trigger Buttons (L1, R1, L2, R2)
  - System Buttons (START, SELECT)
- **Input Principle**: **100% Physical Controller Navigation**. Never rely on touch screen interaction. All menus, HUDs, dialogs, and gameplay must be fully controllable using only physical buttons.

---

## 2. Project Settings (`project.godot`)

### Window & Rendering Settings
```ini
[display]
window/size/viewport_width=720
window/size/viewport_height=720
window/size/window_width_override=720
window/size/window_height_override=720
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
window/handheld/orientation=1

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/vram_compression/import_etc2_astc=true
```

### Gamepad Input Mapping (Project Settings Input Map)
Configure logical action events in `project.godot`:

Action Name | Physical Controls
:--- | :---
`move_left` | Joypad D-Pad Left (Button 13), Left Stick X- (Axis 0, -1.0), Keyboard Left, A
`move_right` | Joypad D-Pad Right (Button 14), Left Stick X+ (Axis 0, 1.0), Keyboard Right, D
`move_up` | Joypad D-Pad Up (Button 11), Left Stick Y- (Axis 1, -1.0), Keyboard Up, W
`move_down` | Joypad D-Pad Down (Button 12), Left Stick Y+ (Axis 1, 1.0), Keyboard Down, S
`ui_accept` | Joypad Button 0 (A button), Keyboard Enter, Space
`ui_cancel` | Joypad Button 1 (B button), Keyboard Escape
`ui_up` | Joypad Button 11, Left Stick Y-, Keyboard Up
`ui_down` | Joypad Button 12, Left Stick Y+, Keyboard Down
`ui_left` | Joypad Button 13, Left Stick X-, Keyboard Left
`ui_right` | Joypad Button 14, Left Stick X+, Keyboard Right
`pause` | Joypad Button 6 (START), Joypad Button 4 (SELECT), Keyboard Escape, P

---

## 3. UI Navigation & Focus Management (Critical Rules)

On handheld consoles without a mouse or touch pointer, focus loss results in a softlock where the player cannot press any buttons. Follow these strict rules:

1. **Initial Focus**:
   In `_ready()`, always explicitly call `grab_focus()` on the default button (e.g., `btn_start.grab_focus()`).
2. **Explicit Focus Neighbors**:
   Never rely on automatic focus guessing. Explicitly wire `focus_neighbor_top`, `focus_neighbor_bottom`, `focus_neighbor_left`, and `focus_neighbor_right` for all interactive controls:
   ```gdscript
   # Example: 3-button vertical menu loop
   btn_top.focus_neighbor_top = btn_bottom.get_path()
   btn_top.focus_neighbor_bottom = btn_middle.get_path()

   btn_middle.focus_neighbor_top = btn_top.get_path()
   btn_middle.focus_neighbor_bottom = btn_bottom.get_path()

   btn_bottom.focus_neighbor_top = btn_middle.get_path()
   btn_bottom.focus_neighbor_bottom = btn_top.get_path()

   # Prevent horizontal escape
   btn_top.focus_neighbor_left = btn_top.get_path()
   btn_top.focus_neighbor_right = btn_top.get_path()
   ```
3. **Visual Feedback**:
   Use distinct, high-contrast borders and glows for the `:focus` StyleBox so players instantly see which button is active on the 720x720 screen.

---

## 4. Pause Menu & Input Isolation Architecture

### Implementation Requirements
1. **Node Processing Modes**:
   - Pause Menu (`CanvasLayer`): Set `process_mode = PROCESS_MODE_ALWAYS`
   - Game Scene Root (`Node2D`): Set `process_mode = PROCESS_MODE_PAUSABLE`
2. **Opening Pause**:
   ```gdscript
   func open_pause_menu() -> void:
       get_tree().paused = true
       visible = true
       btn_resume.grab_focus()
   ```
3. **Input Consumption (`set_input_as_handled`)**:
   In the pause menu's `_unhandled_input(event)`, process pause dismiss actions (START or B button) and **always call `get_viewport().set_input_as_handled()`** to block events from propagating into underlying game nodes:
   ```gdscript
   func _unhandled_input(event: InputEvent) -> void:
       if not is_open:
           return
       if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
           get_viewport().set_input_as_handled()
           close()
           return
       # Consume stray game action inputs
       if event.is_action("move_left") or event.is_action("move_right") or event.is_action("ui_accept"):
           # Handled by focused button GUI or consume
           pass
   ```
4. **Closing Pause & Focus Cleanup**:
   ```gdscript
   func close() -> void:
       var focused = get_viewport().gui_get_focus_owner()
       if focused:
           focused.release_focus()
       visible = false
       get_tree().paused = false
       resumed.emit()
   ```

---

## 5. Android Build & Export Preset Configuration

In `export_presets.cfg`:
- Set `platform="Android"`
- Enable architectures: `architectures/arm64-v8a=true` and `architectures/armeabi-v7a=true`
- Specify debug keystore:
  ```ini
  keystore/debug="C:/Users/user/.android/debug.keystore"
  keystore/debug_user="androiddebugkey"
  keystore/debug_password="android"
  ```
- Fixed orientation: `screen/orientation=1`

> [!CAUTION]
> **Android Launcher Activity Gotcha**:
> In Godot 4.3+, the exported debug APK's launcher activity is `com.godot.game.GodotAppLauncher` (NOT `com.godot.game.GodotApp`).
> Attempting to launch `com.godot.game.GodotApp` via `adb shell am start` will fail with `SecurityException: Permission Denial ... not exported`.
> **Always launch**: `adb shell am start -n <package_name>/com.godot.game.GodotAppLauncher`.

---

## 6. Automated ADB Deployment Pipeline

Use a PowerShell script (`deploy.ps1`) or Bash script (`deploy.sh`) to automate the workflow:

```powershell
# 1. Device check & unauthorized detection
$deviceLine = & adb devices | Where-Object { $_ -match "^[A-Za-z0-9]+\s+(device|unauthorized)" }
# Prompt user if unauthorized:
# "Please tap 'Always allow USB debugging' on the RG Rotate screen."

# 2. Headless APK export
& godot.exe --headless --export-debug "Android" build/game.apk

# 3. Fast install
& adb install -r build/game.apk

# 4. Instant launch
& adb shell am start -n <PACKAGE_NAME>/com.godot.game.GodotAppLauncher

# 5. Live log tracking
& adb logcat -c
& adb logcat -s Godot
```
