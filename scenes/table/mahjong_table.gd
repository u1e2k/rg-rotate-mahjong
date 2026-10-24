extends Node2D
class_name MahjongTable

@onready var pause_menu: PauseMenu = $PauseMenu
@onready var tile_container: HBoxContainer = $PlayerHand/Tiles
@onready var tsumo_slot: Control = $PlayerHand/TsumoSlot
@onready var discard_grid_0: GridContainer = $DiscardsContainer/Discards0
@onready var discard_grid_1: GridContainer = $DiscardsContainer/Discards1
@onready var discard_grid_2: GridContainer = $DiscardsContainer/Discards2
@onready var discard_grid_3: GridContainer = $DiscardsContainer/Discards3
@onready var dora_container: HBoxContainer = $TableCenter/DoraBox/DoraContainer
@onready var center_info_label: Label = $TableCenter/InfoBox/CenterLabel
@onready var remaining_tiles_label: Label = $TableCenter/InfoBox/RemainingLabel
@onready var score_label_0: Label = $Scores/Score0
@onready var score_label_1: Label = $Scores/Score1
@onready var score_label_2: Label = $Scores/Score2
@onready var score_label_3: Label = $Scores/Score3
@onready var action_bar: HBoxContainer = $PlayerHand/ActionBar
@onready var btn_tsumo: Button = $PlayerHand/ActionBar/BtnTsumo
@onready var btn_riichi: Button = $PlayerHand/ActionBar/BtnRiichi
@onready var btn_pass: Button = $PlayerHand/ActionBar/BtnPass
@onready var result_layer: CanvasLayer = $ResultLayer
@onready var result_title: Label = $ResultLayer/Center/Panel/VBox/TitleLabel
@onready var result_detail: Label = $ResultLayer/Center/Panel/VBox/DetailLabel
@onready var result_score: Label = $ResultLayer/Center/Panel/VBox/ScoreLabel
@onready var btn_result_next: Button = $ResultLayer/Center/Panel/VBox/BtnNext
@onready var btn_result_title: Button = $ResultLayer/Center/Panel/VBox/BtnTitle

var tile_scene = preload("res://scenes/table/tile_node.tscn")

var game: MahjongGame
var selected_tile_idx: int = 0
var tile_nodes: Array[TileNode] = []
var tsumo_node: TileNode = null
var is_action_mode: bool = false

# UI用サイズ定義
const SIZE_HAND_TILE = Vector2(42, 58)
const SIZE_DISCARD_TILE = Vector2(18, 25)
const SIZE_DORA_TILE = Vector2(24, 33)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# ポーズメニューシグナル
	pause_menu.resumed.connect(_on_pause_resumed)

	# アクションボタン接続
	btn_tsumo.pressed.connect(_on_tsumo_pressed)
	btn_riichi.pressed.connect(_on_riichi_pressed)
	btn_pass.pressed.connect(_on_pass_pressed)
	action_bar.visible = false

	# リザルトダイアログボタン接続
	result_layer.visible = false
	btn_result_next.pressed.connect(_on_result_next_pressed)
	btn_result_title.pressed.connect(_on_result_title_pressed)
	btn_result_next.focus_neighbor_top = btn_result_title.get_path()
	btn_result_next.focus_neighbor_bottom = btn_result_title.get_path()
	btn_result_title.focus_neighbor_top = btn_result_next.get_path()
	btn_result_title.focus_neighbor_bottom = btn_result_next.get_path()

	# ゲーム初期化
	var sanma = GlobalState.is_sanma if has_node("/root/GlobalState") else false
	start_game(sanma)

func start_game(sanma: bool) -> void:
	game = MahjongGame.new()
	game.tile_drawn.connect(_on_tile_drawn)
	game.tile_discarded.connect(_on_tile_discarded)
	game.agari_declared.connect(_on_agari_declared)
	game.game_round_ended.connect(_on_round_ended)
	game.initialize_game(sanma)

	# 3人麻雀なら4人目UIを非表示
	if sanma:
		score_label_3.visible = false
		discard_grid_3.visible = false

	_update_table_view()

func _update_table_view() -> void:
	_render_player_hand()
	_render_discards()
	_render_dora()
	_update_scores()
	_update_info_box()

func _render_player_hand() -> void:
	for child in tile_container.get_children():
		child.queue_free()
	for child in tsumo_slot.get_children():
		child.queue_free()
	tile_nodes.clear()
	tsumo_node = null

	var hand = game.hands[0]
	var has_tsumo = (game.current_turn == 0 and game.current_drawn_tile != -1)
	var main_count = (hand.size() - 1) if has_tsumo else hand.size()

	for i in range(main_count):
		var tn: TileNode = tile_scene.instantiate()
		tn.custom_minimum_size = SIZE_HAND_TILE
		tn.size = SIZE_HAND_TILE
		tile_container.add_child(tn)
		tn.set_tile(hand[i])
		tile_nodes.append(tn)

	# ツモ牌
	if has_tsumo and hand.size() > 0:
		var tn: TileNode = tile_scene.instantiate()
		tn.custom_minimum_size = SIZE_HAND_TILE
		tn.size = SIZE_HAND_TILE
		tsumo_slot.add_child(tn)
		tn.set_tile(hand.back())
		tile_nodes.append(tn)
		tsumo_node = tn

	selected_tile_idx = clampi(selected_tile_idx, 0, tile_nodes.size() - 1)
	_update_cursor()

func _update_cursor() -> void:
	for i in range(tile_nodes.size()):
		tile_nodes[i].set_selected(i == selected_tile_idx and not is_action_mode)

func _render_discards() -> void:
	var grids = [discard_grid_0, discard_grid_1, discard_grid_2, discard_grid_3]
	for p in range(game.num_players):
		var grid = grids[p]
		for child in grid.get_children():
			child.queue_free()
		for tile_id in game.discards[p]:
			var tn: TileNode = tile_scene.instantiate()
			tn.custom_minimum_size = SIZE_DISCARD_TILE
			tn.size = SIZE_DISCARD_TILE
			grid.add_child(tn)
			tn.set_tile(tile_id)

func _render_dora() -> void:
	for child in dora_container.get_children():
		child.queue_free()
	for ind in game.dora_indicators:
		var tn: TileNode = tile_scene.instantiate()
		tn.custom_minimum_size = SIZE_DORA_TILE
		tn.size = SIZE_DORA_TILE
		dora_container.add_child(tn)
		tn.set_tile(ind)

func _update_scores() -> void:
	var labels = [score_label_0, score_label_1, score_label_2, score_label_3]
	var names = ["自家", "下家", "対面", "上家"]
	for i in range(game.num_players):
		var mark = " [立直]" if game.is_riichi[i] else ""
		labels[i].text = "%s: %d点%s" % [names[i], game.scores[i], mark]
		if i == game.current_turn:
			labels[i].modulate = Color(1.0, 0.9, 0.2)
		else:
			labels[i].modulate = Color.WHITE

func _update_info_box() -> void:
	var mode_name = "3人麻雀" if game.is_sanma else "4人麻雀"
	center_info_label.text = "%s 東%d局" % [mode_name, game.round_num]
	remaining_tiles_label.text = "残 %d枚" % game.wall.size()

# ----------------- 入力処理 -----------------

func _unhandled_input(event: InputEvent) -> void:
	if result_layer.visible:
		return

	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		pause_menu.open()
		return

	if game.current_turn != 0 or tile_nodes.is_empty():
		return

	if is_action_mode:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_on_pass_pressed()
		return

	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		selected_tile_idx = (selected_tile_idx - 1 + tile_nodes.size()) % tile_nodes.size()
		if AudioManager:
			AudioManager.play_focus()
		_update_cursor()
		return

	if event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		selected_tile_idx = (selected_tile_idx + 1) % tile_nodes.size()
		if AudioManager:
			AudioManager.play_focus()
		_update_cursor()
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_discard_selected_tile()
		return

	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		if game.can_player_tsumo() or game.can_player_riichi():
			get_viewport().set_input_as_handled()
			_open_action_bar()

func _discard_selected_tile() -> void:
	if game.current_turn != 0:
		return
	if AudioManager:
		AudioManager.play_select()
	var idx_to_discard = selected_tile_idx
	game.discard_tile(0, idx_to_discard)

func _open_action_bar() -> void:
	is_action_mode = true
	action_bar.visible = true
	btn_tsumo.visible = game.can_player_tsumo()
	btn_riichi.visible = game.can_player_riichi()
	
	if btn_tsumo.visible:
		btn_tsumo.grab_focus()
	elif btn_riichi.visible:
		btn_riichi.grab_focus()
	else:
		btn_pass.grab_focus()
	_update_cursor()

func _close_action_bar() -> void:
	is_action_mode = false
	action_bar.visible = false
	_update_cursor()

func _on_tsumo_pressed() -> void:
	var eval = YakuEvaluator.evaluate_hand(game.hands[0], game.current_drawn_tile, true, game.is_riichi[0], game.is_ippatsu[0], game.dora_indicators, game.dealer_idx == 0)
	game.agari_declared.emit(0, -1, eval)
	_close_action_bar()

func _on_riichi_pressed() -> void:
	game.is_riichi[0] = true
	game.is_ippatsu[0] = true
	game.scores[0] -= 1000
	if AudioManager:
		AudioManager.play_flip(true)
	_close_action_bar()
	_discard_selected_tile()

func _on_pass_pressed() -> void:
	if AudioManager:
		AudioManager.play_cancel()
	_close_action_bar()

# ----------------- ゲームイベント -----------------

func _on_tile_drawn(p: int, _tile: int) -> void:
	_update_table_view()
	if p == 0:
		selected_tile_idx = tile_nodes.size() - 1
		_update_cursor()
		if game.can_player_tsumo() or game.can_player_riichi():
			_open_action_bar()

func _on_tile_discarded(_p: int, _tile: int, _is_tsumogiri: bool) -> void:
	_update_table_view()

func _on_agari_declared(winner_idx: int, loser_idx: int, result: YakuEvaluator.AgariResult) -> void:
	_update_table_view()
	if AudioManager:
		AudioManager.play_clear()

	var names = ["自家", "下家", "対面", "上家"]
	var win_name = names[winner_idx]
	if loser_idx == -1:
		result_title.text = "【%s】 ツモ和了！" % win_name
	else:
		result_title.text = "【%s】 ロン和了！ (放銃: %s)" % [win_name, names[loser_idx]]

	var detail = "\n".join(result.yaku_list)
	result_detail.text = detail
	result_score.text = result.score_text

	game.scores[winner_idx] += result.score
	if loser_idx != -1:
		game.scores[loser_idx] = maxi(0, game.scores[loser_idx] - result.score)

	result_layer.visible = true
	result_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	btn_result_next.grab_focus()

func _on_round_ended(reason: String) -> void:
	result_title.text = "【流局】"
	result_detail.text = reason
	result_score.text = ""
	result_layer.visible = true
	result_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	btn_result_next.grab_focus()

func _on_result_next_pressed() -> void:
	get_tree().paused = false
	result_layer.visible = false
	game.round_num += 1
	game.start_round()
	_update_table_view()

func _on_result_title_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title/title_screen.tscn")

func _on_pause_resumed() -> void:
	pass
