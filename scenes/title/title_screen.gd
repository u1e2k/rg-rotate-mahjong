extends Control

@onready var btn_yonma: Button = $VBoxContainer/BtnYonma
@onready var btn_sanma: Button = $VBoxContainer/BtnSanma
@onready var btn_settings: Button = $VBoxContainer/BtnSettings
@onready var btn_quit: Button = $VBoxContainer/BtnQuit
@onready var settings_popup: CanvasLayer = $SettingsPopup
@onready var btn_close_settings: Button = $SettingsPopup/Center/Panel/VBox/BtnClose
@onready var logo_label: Label = $LogoContainer/TitleLogo

var float_phase: float = 0.0

func _ready() -> void:
	settings_popup.visible = false
	
	# ボタン接続
	btn_yonma.pressed.connect(_on_yonma_pressed)
	btn_sanma.pressed.connect(_on_sanma_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_close_settings.pressed.connect(_on_close_settings_pressed)
	
	# フォーカス音
	btn_yonma.focus_entered.connect(_on_focus_entered)
	btn_sanma.focus_entered.connect(_on_focus_entered)
	btn_settings.focus_entered.connect(_on_focus_entered)
	btn_quit.focus_entered.connect(_on_focus_entered)
	btn_close_settings.focus_entered.connect(_on_focus_entered)
	
	# フォーカスループの明示設定（フォーカスロスト防止）
	btn_yonma.focus_neighbor_top = btn_quit.get_path()
	btn_yonma.focus_neighbor_bottom = btn_sanma.get_path()
	
	btn_sanma.focus_neighbor_top = btn_yonma.get_path()
	btn_sanma.focus_neighbor_bottom = btn_settings.get_path()
	
	btn_settings.focus_neighbor_top = btn_sanma.get_path()
	btn_settings.focus_neighbor_bottom = btn_quit.get_path()
	
	btn_quit.focus_neighbor_top = btn_settings.get_path()
	btn_quit.focus_neighbor_bottom = btn_yonma.get_path()
	
	# 左右抜け防止
	btn_yonma.focus_neighbor_left = btn_yonma.get_path()
	btn_yonma.focus_neighbor_right = btn_yonma.get_path()
	btn_sanma.focus_neighbor_left = btn_sanma.get_path()
	btn_sanma.focus_neighbor_right = btn_sanma.get_path()
	btn_settings.focus_neighbor_left = btn_settings.get_path()
	btn_settings.focus_neighbor_right = btn_settings.get_path()
	btn_quit.focus_neighbor_left = btn_quit.get_path()
	btn_quit.focus_neighbor_right = btn_quit.get_path()
	
	# デフォルトで最上部「4人麻雀」ボタンにフォーカス
	btn_yonma.grab_focus()

func _process(delta: float) -> void:
	float_phase += delta * 2.0
	if logo_label:
		logo_label.position.y = sin(float_phase) * 5.0

func _unhandled_input(event: InputEvent) -> void:
	if settings_popup.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
			_on_close_settings_pressed()

func _on_focus_entered() -> void:
	if AudioManager:
		AudioManager.play_focus()

func _on_yonma_pressed() -> void:
	if AudioManager:
		AudioManager.play_select()
	GlobalState.is_sanma = false
	get_tree().change_scene_to_file("res://scenes/table/mahjong_table.tscn")

func _on_sanma_pressed() -> void:
	if AudioManager:
		AudioManager.play_select()
	GlobalState.is_sanma = true
	get_tree().change_scene_to_file("res://scenes/table/mahjong_table.tscn")

func _on_settings_pressed() -> void:
	if AudioManager:
		AudioManager.play_select()
	settings_popup.visible = true
	btn_close_settings.grab_focus()

func _on_close_settings_pressed() -> void:
	if AudioManager:
		AudioManager.play_cancel()
	settings_popup.visible = false
	btn_settings.grab_focus()

func _on_quit_pressed() -> void:
	if AudioManager:
		AudioManager.play_cancel()
	get_tree().quit()
