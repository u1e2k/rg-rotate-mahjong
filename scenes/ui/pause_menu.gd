extends CanvasLayer
class_name PauseMenu

signal resumed()
signal restarted()
signal title_requested()

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var btn_resume: Button = $CenterContainer/PanelContainer/VBoxContainer/BtnResume
@onready var btn_restart: Button = $CenterContainer/PanelContainer/VBoxContainer/BtnRestart
@onready var btn_title: Button = $CenterContainer/PanelContainer/VBoxContainer/BtnTitle

var is_open: bool = false

func _ready() -> void:
	# 必須要件1: ポーズメニュー自身はポーズ中でも動作するよう PROCESS_MODE_ALWAYS に設定
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	# 各ボタンのシグナル接続
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_title.pressed.connect(_on_title_pressed)
	
	# フォーカス音の接続
	btn_resume.focus_entered.connect(_on_focus_entered)
	btn_restart.focus_entered.connect(_on_focus_entered)
	btn_title.focus_entered.connect(_on_title_entered)
	
	# 必須要件5: フォーカスロスト対策 (循環ループ)
	_setup_focus_loop()

func _setup_focus_loop() -> void:
	# 上下移動でUI外へフォーカスが抜けないように明示指定
	btn_resume.focus_neighbor_top = btn_title.get_path()
	btn_resume.focus_neighbor_bottom = btn_restart.get_path()
	
	btn_restart.focus_neighbor_top = btn_resume.get_path()
	btn_restart.focus_neighbor_bottom = btn_title.get_path()
	
	btn_title.focus_neighbor_top = btn_restart.get_path()
	btn_title.focus_neighbor_bottom = btn_resume.get_path()
	
	# 左右キーでのフォーカスロストも防止
	btn_resume.focus_neighbor_left = btn_resume.get_path()
	btn_resume.focus_neighbor_right = btn_resume.get_path()
	btn_restart.focus_neighbor_left = btn_restart.get_path()
	btn_restart.focus_neighbor_right = btn_restart.get_path()
	btn_title.focus_neighbor_left = btn_title.get_path()
	btn_title.focus_neighbor_right = btn_title.get_path()

func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	
	# 必須要件1: ツリー全体をポーズ状態にする
	get_tree().paused = true
	
	if AudioManager:
		AudioManager.play_cancel() # ポーズオープン音
	
	# 必須要件2: 開いた瞬間にRESUMEボタンへフォーカスを明示
	# 1フレーム待たずに直ちにフォーカスを付与
	btn_resume.grab_focus()

func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	
	# 必須要件4: フォーカス解放とポーズ解除
	var focused = get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	
	get_tree().paused = false
	resumed.emit()

# 必須要件3: ポーズ中の入力を _unhandled_input で捕捉し、set_input_as_handled() で背後への貫通を物理遮断
func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	
	# STARTボタン、または ui_cancel (Bボタン) でポーズ解除
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if AudioManager:
			AudioManager.play_select()
		close()
		return
	
	# ゲームプレイ操作系のアクション（重力反転や移動）がポーズ中に漏洩しないよう消費
	if event.is_action("action_gravity") or event.is_action("move_left") or event.is_action("move_right") or event.is_action("move_up") or event.is_action("move_down"):
		get_viewport().set_input_as_handled()
		return

func _on_focus_entered() -> void:
	if AudioManager and is_open:
		AudioManager.play_focus()

func _on_title_entered() -> void:
	if AudioManager and is_open:
		AudioManager.play_focus()

func _on_resume_pressed() -> void:
	if AudioManager:
		AudioManager.play_select()
	close()

func _on_restart_pressed() -> void:
	if AudioManager:
		AudioManager.play_select()
	is_open = false
	visible = false
	var focused = get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	get_tree().paused = false
	restarted.emit()
	get_tree().reload_current_scene()

func _on_title_pressed() -> void:
	if AudioManager:
		AudioManager.play_select()
	is_open = false
	visible = false
	var focused = get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	get_tree().paused = false
	title_requested.emit()
	get_tree().change_scene_to_file("res://scenes/title/title_screen.tscn")
