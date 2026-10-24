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
@onready var bottom_hint: Label = $BottomHint
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

# 状態フラグ
var is_action_mode: bool = false
var is_riichi_selection_mode: bool = false
var riichi_candidate_indices: Array[int] = []

const SIZE_HAND_TILE = Vector2(42, 58)
const SIZE_DISCARD_TILE = Vector2(18, 25)
const SIZE_DORA_TILE = Vector2(24, 33)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	pause_menu.resumed.connect(_on_pause_resumed)

	btn_tsumo.pressed.connect(_on_tsumo_pressed)
	btn_riichi.pressed.connect(_on_riichi_pressed)
	btn_pass.pressed.connect(_on_pass_pressed)
	action_bar.visible = false

	result_layer.visible = false
	btn_result_next.pressed.connect(_on_result_next_pressed)
	btn_result_title.pressed.connect(_on_result_title_pressed)
	btn_result_next.focus_neighbor_top = btn_result_title.get_path()
	btn_result_next.focus_neighbor_bottom = btn_result_title.get_path()
	btn_result_title.focus_neighbor_top = btn_result_next.get_path()
	btn_result_title.focus_neighbor_bottom = btn_result_next.get_path()

	var sanma = GlobalState.is_sanma if has_node("/root/GlobalState") else false
	start_game(sanma)

func start_game(sanma: bool) -> void:
	game = MahjongGame.new()
	game.tile_drawn.connect(_on_tile_drawn)
	game.tile_discarded.connect(_on_tile_discarded)
	game.cpu_turn_ready.connect(_on_cpu_turn_ready)
	game.agari_declared.connect(_on_agari_declared)
	game.game_round_ended.connect(_on_round_ended)
	game.initialize_game(sanma)

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
		var is_cur = (i == selected_tile_idx and not is_action_mode)
		tile_nodes[i].set_selected(is_cur)
		
		# リーチ宣言牌選択中、テンパイにならない牌は半透明にして分かりやすくする
		if is_riichi_selection_mode:
			if i in riichi_candidate_indices:
				tile_nodes[i].modulate = Color.WHITE
			else:
				tile_nodes[i].modulate = Color(0.5, 0.5, 0.5, 0.6)
		else:
			tile_nodes[i].modulate = Color.WHITE

func _render_discards() -> void:
	var grids = [discard_grid_0, discard_grid_1, discard_grid_2, discard_grid_3]
	for p in range(game.num_players):
		var grid = grids[p]
		for child in grid.get_children():
			child.queue_free()

		var discards = game.discards[p]
		var riichi_idx = game.riichi_discard_indices[p]

		for i in range(discards.size()):
			var tile_id = discards[i]
			var is_riichi_tile = (i == riichi_idx)
			var tn: TileNode = tile_scene.instantiate()

			if is_riichi_tile:
				# リーチ宣言牌は横向き表示
				tn.custom_minimum_size = Vector2(SIZE_DISCARD_TILE.y, SIZE_DISCARD_TILE.x)
				tn.size = Vector2(SIZE_DISCARD_TILE.y, SIZE_DISCARD_TILE.x)
				grid.add_child(tn)
				tn.set_tile(tile_id, false, true)
			else:
				tn.custom_minimum_size = SIZE_DISCARD_TILE
				tn.size = SIZE_DISCARD_TILE
				grid.add_child(tn)
				tn.set_tile(tile_id, false, false)

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
	var riichi_txt = " | 供託: %d本" % game.riichi_sticks if game.riichi_sticks > 0 else ""
	center_info_label.text = "%s 東%d局%s" % [mode_name, game.round_num, riichi_txt]
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

	# アクションバー表示中 (ツモ / リーチ / パス)
	if is_action_mode:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_on_pass_pressed()
		return

	# リーチ宣言牌の選択中
	if is_riichi_selection_mode:
		_handle_riichi_selection_input(event)
		return

	# 自家がリーチ済みの場合の入力制御 (手牌変更不可、ツモ切りかツモ和了のみ)
	if game.is_riichi[0]:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			# ツモ切り
			_discard_selected_tile()
		return

	# 通常手牌カーソル移動
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

	# Aボタンで打牌
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_discard_selected_tile()
		return

	# 上キーまたはYボタンでアクションバー表示
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		if game.can_player_tsumo() or game.can_player_riichi():
			get_viewport().set_input_as_handled()
			_open_action_bar()

# リーチ牌選択専用の入力処理
func _handle_riichi_selection_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		# リーチ選択をキャンセル
		is_riichi_selection_mode = false
		bottom_hint.text = "[◀/▶]: 牌選択  |  [A]: 打牌  |  [▲]: アクション  |  [START]: ポーズ"
		_update_cursor()
		return

	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		var cur_pos = riichi_candidate_indices.find(selected_tile_idx)
		if cur_pos == -1:
			selected_tile_idx = riichi_candidate_indices[0]
		else:
			var prev_pos = (cur_pos - 1 + riichi_candidate_indices.size()) % riichi_candidate_indices.size()
			selected_tile_idx = riichi_candidate_indices[prev_pos]
		if AudioManager:
			AudioManager.play_focus()
		_update_cursor()
		return

	if event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		var cur_pos = riichi_candidate_indices.find(selected_tile_idx)
		if cur_pos == -1:
			selected_tile_idx = riichi_candidate_indices[0]
		else:
			var next_pos = (cur_pos + 1) % riichi_candidate_indices.size()
			selected_tile_idx = riichi_candidate_indices[next_pos]
		if AudioManager:
			AudioManager.play_focus()
		_update_cursor()
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		# 選択された牌で立直を確定！
		_confirm_riichi(selected_tile_idx)

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
	_close_action_bar()
	# リーチ宣言牌の選択モードに入る
	riichi_candidate_indices = game.get_riichi_discard_indices(0)
	if riichi_candidate_indices.is_empty():
		return

	is_riichi_selection_mode = true
	# 候補の最初の牌にカーソルを合わせる
	selected_tile_idx = riichi_candidate_indices[0]
	bottom_hint.text = "【立直宣言】切る牌を選択してください  |  [A]: 確定  |  [B]: 取消"
	_update_cursor()

func _confirm_riichi(discard_idx: int) -> void:
	is_riichi_selection_mode = false
	if AudioManager:
		AudioManager.play_flip(true) # リーチ効果音
	bottom_hint.text = "【立直中】オートツモ切り  |  [A]: ツモ切り  |  [START]: ポーズ"
	game.declare_riichi(0, discard_idx)

func _on_pass_pressed() -> void:
	if AudioManager:
		AudioManager.play_cancel()
	_close_action_bar()

# ----------------- ゲームイベント -----------------

func _on_tile_drawn(p: int, _tile: int) -> void:
	_update_table_view()
	if p == 0:
		# ツモ牌にカーソルを自動移動
		selected_tile_idx = tile_nodes.size() - 1
		_update_cursor()

		# ツモ和了または立直可能ならアクションバー表示
		if game.can_player_tsumo():
			_open_action_bar()
		elif not game.is_riichi[0] and game.can_player_riichi():
			_open_action_bar()
		elif game.is_riichi[0]:
			# リーチ中はツモ和了でなければオートツモ切り（0.3秒待機後に自動打牌またはA打牌）
			bottom_hint.text = "【立直中】ツモ切り  |  [A]: 打牌  |  [START]: ポーズ"
			get_tree().create_timer(0.4).timeout.connect(func():
				if game.current_turn == 0 and game.is_riichi[0] and not is_action_mode:
					_discard_selected_tile()
			)

func _on_tile_discarded(_p: int, _tile: int, _is_tsumogiri: bool, _is_riichi_action: bool = false) -> void:
	if AudioManager:
		AudioManager.play_select()
	_update_table_view()

func _on_cpu_turn_ready(p: int) -> void:
	_update_table_view()
	get_tree().create_timer(0.3).timeout.connect(func():
		if game and game.current_turn == p:
			game.execute_cpu_turn(p)
	)

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

	# 供託リーチ棒のボーナス加算
	var total_win = result.score
	if game.riichi_sticks > 0:
		var bonus = game.riichi_sticks * 1000
		total_win += bonus
		result_score.text = "%s + 供託 %d点 (計 %d点)" % [result.score_text, bonus, total_win]
		game.riichi_sticks = 0
	else:
		result_score.text = result.score_text

	game.scores[winner_idx] += total_win
	if loser_idx != -1:
		game.scores[loser_idx] = maxi(0, game.scores[loser_idx] - result.score)

	result_layer.visible = true
	result_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	btn_result_next.grab_focus()

func _on_round_ended(reason: String) -> void:
	result_title.text = "【流局】"
	result_detail.text = reason
	result_score.text = "供託リーチ棒: %d本持越し" % game.riichi_sticks if game.riichi_sticks > 0 else ""
	result_layer.visible = true
	result_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	btn_result_next.grab_focus()

func _on_result_next_pressed() -> void:
	get_tree().paused = false
	result_layer.visible = false
	is_riichi_selection_mode = false
	game.round_num += 1
	game.start_round()
	_update_table_view()

func _on_result_title_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title/title_screen.tscn")

func _on_pause_resumed() -> void:
	pass
