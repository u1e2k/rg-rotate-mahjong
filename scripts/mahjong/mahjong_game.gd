class_name MahjongGame
extends RefCounted

signal state_changed()
signal tile_drawn(player_idx: int, tile_id: int)
signal tile_discarded(player_idx: int, tile_id: int, is_tsumogiri: bool, is_riichi_action: bool)
signal cpu_turn_ready(player_idx: int)
signal agari_declared(winner_idx: int, loser_idx: int, result: YakuEvaluator.AgariResult)
signal game_round_ended(reason: String)

var is_sanma: bool = false
var num_players: int = 4

# 山と王牌
var wall: Array[int] = []
var dead_wall: Array[int] = []
var dora_indicators: Array[int] = []

# プレイヤーデータ
var hands: Array[Array] = []
var discards: Array[Array] = []
var scores: Array[int] = []
var is_riichi: Array[bool] = []
var is_ippatsu: Array[bool] = []
var riichi_discard_indices: Array[int] = []

var riichi_sticks: int = 0
var current_turn: int = 0
var current_drawn_tile: int = -1
var dealer_idx: int = 0
var round_wind: int = 0
var round_num: int = 1

func initialize_game(sanma: bool) -> void:
	is_sanma = sanma
	num_players = 3 if is_sanma else 4
	scores.clear()
	for i in range(num_players):
		scores.append(35000 if is_sanma else 25000)
	dealer_idx = 0
	round_wind = 0
	round_num = 1
	riichi_sticks = 0
	start_round()

func start_round() -> void:
	wall.clear()
	dead_wall.clear()
	dora_indicators.clear()

	for tile_id in range(34):
		if is_sanma and MahjongDefs.is_sanma_excluded(tile_id):
			continue
		for copy in range(4):
			wall.append(tile_id)

	wall.shuffle()

	# 王牌 14枚
	for i in range(14):
		dead_wall.append(wall.pop_back())
	dora_indicators.append(dead_wall[4])

	hands.clear()
	discards.clear()
	is_riichi.clear()
	is_ippatsu.clear()
	riichi_discard_indices.clear()

	for i in range(num_players):
		hands.append([])
		discards.append([])
		is_riichi.append(false)
		is_ippatsu.append(false)
		riichi_discard_indices.append(-1)

	# 配牌 (各13枚)
	for i in range(13):
		for p in range(num_players):
			hands[p].append(wall.pop_back())

	for p in range(num_players):
		sort_hand(p)

	current_turn = dealer_idx
	state_changed.emit()

	draw_tile(current_turn)

func sort_hand(p: int) -> void:
	hands[p].sort()

func draw_tile(p: int) -> void:
	if wall.is_empty():
		game_round_ended.emit("流局 (荒牌平局)")
		return

	var tile = wall.pop_back()
	current_drawn_tile = tile
	hands[p].append(tile)
	tile_drawn.emit(p, tile)

	if p != 0:
		cpu_turn_ready.emit(p)

func discard_tile(p: int, tile_idx: int, is_riichi_action: bool = false) -> void:
	if tile_idx < 0 or tile_idx >= hands[p].size():
		return

	var tile = hands[p][tile_idx]
	var is_tsumogiri = (tile == current_drawn_tile and tile_idx == hands[p].size() - 1)
	hands[p].remove_at(tile_idx)
	discards[p].append(tile)

	if is_riichi_action:
		riichi_discard_indices[p] = discards[p].size() - 1

	sort_hand(p)
	current_drawn_tile = -1

	if not is_riichi_action:
		is_ippatsu[p] = false

	tile_discarded.emit(p, tile, is_tsumogiri, is_riichi_action)

	# ロン和了判定
	if _check_ron(p, tile):
		return

	# 次の手番へ遷移
	current_turn = (current_turn + 1) % num_players
	draw_tile(current_turn)

func declare_riichi(p: int, discard_idx: int) -> void:
	is_riichi[p] = true
	is_ippatsu[p] = true
	scores[p] -= 1000
	riichi_sticks += 1
	discard_tile(p, discard_idx, true)

func execute_cpu_turn(p: int) -> void:
	if current_turn != p:
		return

	# ツモ和了チェック
	var eval = YakuEvaluator.evaluate_hand(hands[p], current_drawn_tile, true, is_riichi[p], is_ippatsu[p], dora_indicators, p == dealer_idx)
	if eval.is_agari:
		agari_declared.emit(p, -1, eval)
		return

	# リーチ済みの場合はツモ切り
	if is_riichi[p]:
		discard_tile(p, hands[p].size() - 1)
		return

	# リーチ可能ならリーチ
	var riichi_options = get_riichi_discard_indices(p)
	if riichi_options.size() > 0 and scores[p] >= 1000 and wall.size() >= 4:
		declare_riichi(p, riichi_options[0])
		return

	# 通常打牌
	var best_idx = _select_cpu_discard(p)
	discard_tile(p, best_idx)

func _select_cpu_discard(p: int) -> int:
	var hand = hands[p]
	var counts: Array[int] = []
	counts.resize(34)
	counts.fill(0)
	for t in hand:
		counts[t] += 1

	var best_discard_idx = hand.size() - 1
	var min_shanten = 99
	var checked_tiles: Dictionary = {}

	for i in range(hand.size()):
		var t = hand[i]
		if checked_tiles.has(t):
			continue
		checked_tiles[t] = true

		var test_counts = counts.duplicate()
		test_counts[t] -= 1
		var s = YakuEvaluator.calculate_shanten(test_counts)
		if s < min_shanten:
			min_shanten = s
			best_discard_idx = i

	return best_discard_idx

func _check_ron(discarder_idx: int, tile: int) -> bool:
	for p in range(num_players):
		if p == discarder_idx:
			continue
		var test_hand = hands[p].duplicate()
		test_hand.append(tile)
		var eval = YakuEvaluator.evaluate_hand(test_hand, tile, false, is_riichi[p], is_ippatsu[p], dora_indicators, p == dealer_idx)
		if eval.is_agari:
			agari_declared.emit(p, discarder_idx, eval)
			return true
	return false

# ----------------- 判定ヘルパー -----------------

func can_player_tsumo() -> bool:
	if current_turn != 0 or current_drawn_tile == -1:
		return false
	var eval = YakuEvaluator.evaluate_hand(hands[0], current_drawn_tile, true, is_riichi[0], is_ippatsu[0], dora_indicators, dealer_idx == 0)
	return eval.is_agari

func can_player_riichi() -> bool:
	if current_turn != 0 or is_riichi[0] or scores[0] < 1000 or wall.size() < 4:
		return false
	return get_riichi_discard_indices(0).size() > 0

func get_riichi_discard_indices(p: int) -> Array[int]:
	var valid_indices: Array[int] = []
	var hand = hands[p]
	if hand.size() != 14:
		return valid_indices

	var counts: Array[int] = []
	counts.resize(34)
	counts.fill(0)
	for t in hand:
		counts[t] += 1

	var checked_tiles: Dictionary = {}
	for i in range(hand.size()):
		var tile = hand[i]
		if checked_tiles.has(tile):
			if checked_tiles[tile]:
				valid_indices.append(i)
			continue

		counts[tile] -= 1
		var is_tenpai = (YakuEvaluator.calculate_shanten(counts) == 0)
		checked_tiles[tile] = is_tenpai
		if is_tenpai:
			valid_indices.append(i)
		counts[tile] += 1

	return valid_indices
