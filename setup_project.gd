@tool
extends SceneTree

func _init():
	print("Configuring Mahjong Project Settings & Autoloads...")

	# --- Window & Display ---
	ProjectSettings.set_setting("application/config/name", "RG Rotate Mahjong")
	ProjectSettings.set_setting("application/config/description", "3-Player & 4-Player Mahjong for ANBERNIC RG Rotate")
	ProjectSettings.set_setting("application/config/version", "1.0.0")
	ProjectSettings.set_setting("application/run/main_scene", "res://scenes/title/title_screen.tscn")
	
	ProjectSettings.set_setting("display/window/size/viewport_width", 720)
	ProjectSettings.set_setting("display/window/size/viewport_height", 720)
	ProjectSettings.set_setting("display/window/size/window_width_override", 720)
	ProjectSettings.set_setting("display/window/size/window_height_override", 720)
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
	ProjectSettings.set_setting("display/window/stretch/aspect", "keep")
	ProjectSettings.set_setting("display/window/handheld/orientation", 1) # Portrait / Fixed
	
	ProjectSettings.set_setting("rendering/renderer/rendering_method", "gl_compatibility")
	ProjectSettings.set_setting("rendering/renderer/rendering_method.mobile", "gl_compatibility")
	ProjectSettings.set_setting("textures/vram_compression/import_etc2_astc", true)
	ProjectSettings.set_setting("rendering/environment/defaults/default_clear_color", Color(0.06, 0.16, 0.1, 1.0))

	# --- Autoloads ---
	ProjectSettings.set_setting("autoload/GlobalState", "*res://scripts/global_state.gd")
	ProjectSettings.set_setting("autoload/AudioManager", "*res://scripts/audio_manager.gd")

	# --- Helper to register action ---
	var register_action = func(action_name: String, events: Array):
		var setting_name = "input/" + action_name
		var action_dict = {
			"deadzone": 0.3,
			"events": events
		}
		ProjectSettings.set_setting(setting_name, action_dict)

	# Keyboard keys
	var key_a = InputEventKey.new(); key_a.physical_keycode = KEY_A
	var key_d = InputEventKey.new(); key_d.physical_keycode = KEY_D
	var key_w = InputEventKey.new(); key_w.physical_keycode = KEY_W
	var key_s = InputEventKey.new(); key_s.physical_keycode = KEY_S
	var key_left = InputEventKey.new(); key_left.physical_keycode = KEY_LEFT
	var key_right = InputEventKey.new(); key_right.physical_keycode = KEY_RIGHT
	var key_up = InputEventKey.new(); key_up.physical_keycode = KEY_UP
	var key_down = InputEventKey.new(); key_down.physical_keycode = KEY_DOWN
	var key_space = InputEventKey.new(); key_space.physical_keycode = KEY_SPACE
	var key_enter = InputEventKey.new(); key_enter.physical_keycode = KEY_ENTER
	var key_escape = InputEventKey.new(); key_escape.physical_keycode = KEY_ESCAPE
	var key_p = InputEventKey.new(); key_p.physical_keycode = KEY_P
	var key_z = InputEventKey.new(); key_z.physical_keycode = KEY_Z
	var key_x = InputEventKey.new(); key_x.physical_keycode = KEY_X
	var key_c = InputEventKey.new(); key_c.physical_keycode = KEY_C

	# Joypad: RG Rotate mappings
	var joy_btn = func(idx: JoyButton):
		var b = InputEventJoypadButton.new()
		b.button_index = idx
		return b

	var joy_axis = func(axis: JoyAxis, val: float):
		var m = InputEventJoypadMotion.new()
		m.axis = axis
		m.axis_value = val
		return m

	# 1. move_left
	register_action.call("move_left", [
		key_left, key_a,
		joy_btn.call(JOY_BUTTON_DPAD_LEFT),
		joy_axis.call(JOY_AXIS_LEFT_X, -1.0)
	])

	# 2. move_right
	register_action.call("move_right", [
		key_right, key_d,
		joy_btn.call(JOY_BUTTON_DPAD_RIGHT),
		joy_axis.call(JOY_AXIS_LEFT_X, 1.0)
	])

	# 3. move_up
	register_action.call("move_up", [
		key_up, key_w,
		joy_btn.call(JOY_BUTTON_DPAD_UP),
		joy_axis.call(JOY_AXIS_LEFT_Y, -1.0),
		joy_btn.call(JOY_BUTTON_Y),
		joy_btn.call(JOY_BUTTON_X)
	])

	# 4. move_down
	register_action.call("move_down", [
		key_down, key_s,
		joy_btn.call(JOY_BUTTON_DPAD_DOWN),
		joy_axis.call(JOY_AXIS_LEFT_Y, 1.0)
	])

	# 5. action_gravity / action_select
	register_action.call("action_gravity", [
		key_space, key_z,
		joy_btn.call(JOY_BUTTON_A)
	])

	# 6. ui_accept
	register_action.call("ui_accept", [
		key_enter, key_space, key_z,
		joy_btn.call(JOY_BUTTON_A)
	])

	# 7. ui_cancel
	register_action.call("ui_cancel", [
		key_escape, key_x,
		joy_btn.call(JOY_BUTTON_B)
	])

	# 8. ui_up
	register_action.call("ui_up", [
		key_up, key_w,
		joy_btn.call(JOY_BUTTON_DPAD_UP),
		joy_axis.call(JOY_AXIS_LEFT_Y, -1.0)
	])

	# 9. ui_down
	register_action.call("ui_down", [
		key_down, key_s,
		joy_btn.call(JOY_BUTTON_DPAD_DOWN),
		joy_axis.call(JOY_AXIS_LEFT_Y, 1.0)
	])

	# 10. ui_left
	register_action.call("ui_left", [
		key_left, key_a,
		joy_btn.call(JOY_BUTTON_DPAD_LEFT),
		joy_axis.call(JOY_AXIS_LEFT_X, -1.0)
	])

	# 11. ui_right
	register_action.call("ui_right", [
		key_right, key_d,
		joy_btn.call(JOY_BUTTON_DPAD_RIGHT),
		joy_axis.call(JOY_AXIS_LEFT_X, 1.0)
	])

	# 12. pause
	register_action.call("pause", [
		key_escape, key_p,
		joy_btn.call(JOY_BUTTON_START),
		joy_btn.call(JOY_BUTTON_BACK)
	])

	var err = ProjectSettings.save()
	if err == OK:
		print("Successfully configured and saved Mahjong project.godot!")
	else:
		printerr("Failed to save project.godot: ", err)

	quit()
