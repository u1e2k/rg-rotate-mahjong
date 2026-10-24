class_name MahjongGame
extends RefCounted

signal state_changed()
signal tile_drawn(player_idx: int, tile_id: int)
signal tile_discarded(player_idx: int, tile_id: int, is_tsumogiri: bool)
signal agari_declared(winner_idx: int, loser_idx: int, result: YakuEvaluator.AgariResult)
signal game_round_ended(reason: String)

var is_sanma: bool = false # false: 4人麻雀, true: 3人麻雀
var num_players: int = 4

# 山と牌
var wall: Array[int] = []
var dead_wall: Array[int] = []
var dora_indicators: Array[int] = []

# 各プレイヤーデータ: Array[int]
# 0: 自身 (南/東/プレイヤー), 1: 下家, 2: 対面, 3: 上家 (サンマ時は0, 1, 2)
var hands: Array[Array] = [] # hands[p] = Array[int]
var discards: Array[Array] = [] # discards[p] = Array[int]
var scores: Array[int] = []
var is_riichi: Array[bool] = []
var is_ippatsu: Array[bool] = []

var current_turn: int = 0
var current_drawn_tile: int = -1
var dealer_idx: int = 0
var round_wind: int = 0 # 0: 東, 1: 南
var round_num: int = 1  # 東1局

func initialize_game(sanma: bool) -> void:
	is_sanma = sanma
	num_players = 3 if is_sanma else 4
	scores.clear()
	for i in range(num_players):
		scores.append(35000 if is_sanma else 25000)
	dealer_idx = 0
	round_wind = 0
	round_num = 1
	start_round()

func start_round() -> void:
	# 牌山の作成
	wall.clear()
	dead_wall.clear()
	dora_indicators.clear()

	for tile_id in range(34):
		if is_sanma and MahjongDefs.is_sanma_excluded(tile_id):
			continue # サンマは2m〜8mなし
		for copy in range(4):
			wall.append(tile_id)

	wall.shuffle()

	# 王牌 14枚
	for i in range(14):
		dead_wall.append(wall.pop_back())
	dora_indicators.append(dead_wall[4]) # 第1ドラ表示牌

	# 手牌と河の初期化
	hands.clear()
	discards.clear()
	is_riichi.clear()
	is_ippatsu.clear()

	for i in range(num_players):
		hands.append([])
		discards.append([])
		is_riichi.append(false)
		is_ippatsu.append(false)

	# 配牌 (各13枚)
	for i in range(13):
		for p in range(num_players):
			hands[p].append(wall.pop_back())

	# 理牌 (ソート)
	for p in range(num_players):
		sort_hand(p)

	current_turn = dealer_idx
	state_changed.emit()
	
	# 親の第1ツモ
	draw_tile(current_turn)

func sort_hand(p: int) -> void:
	hands[p].sort()

func draw_tile(p: int) -> void:
	if wall.is_empty():
		# 流局
		game_round_ended.emit("流局 (荒牌平局)")
		return

	var tile = wall.pop_back()
	current_drawn_tile = tile
	hands[p].append(tile)
	tile_drawn.emit(p, tile)

	# プレイヤー0（自身）の手番なら入力待ち、CPUなら自動打牌
	if p != 0:
		_process_cpu_turn(p)

func discard_tile(p: int, tile_idx: int) -> void:
	if tile_idx < 0 or tile_idx >= hands[p].size():
		return

	var tile = hands[p][tile_idx]
	var is_tsumogiri = (tile == current_drawn_tile and tile_idx == hands[p].size() - 1)
	hands[p].remove_at(tile_idx)
	discards[p].append(tile)
	sort_hand(p)
	current_drawn_tile = -1

	# 一発消去
	is_ippatsu[p] = false

	tile_discarded.emit(p, tile, is_tsumogiri)

	# ロン和了チェック（他プレイヤー）
	if _check_ron(p, tile):
		return

	# 次の番へ
	current_turn = (current_turn + 1) % num_players
	draw_tile(current_turn)

func _process_cpu_turn(p: int) -> void:
	# CPUの簡易打牌: シャンテン数を維持または下げる牌、または不要な字牌・孤立牌を切る
	var best_idx = _select_cpu_discard(p)
	# 少し間を置いて打牌
	discard_tile(p, best_idx)

func _select_cpu_discard(p: int) -> int:
	var hand = hands[p]
	# ツモ和了できるならツモ
	var eval = YakuEvaluator.evaluate_hand(hand, current_drawn_tile, true, is_riichi[p], is_ippatsu[p], dora_indicators, p == dealer_idx)
	if eval.is_agari:
		agari_declared.emit(p, -1, eval)
		return -1

	# テンパイしたらリーチ
	var counts: Array[int] = []
	counts.resize(34)
	counts.fill(0)
	for t in hand:
		counts[t] += 1

	# 最も有効牌が多い打牌を選択
	var best_discard_idx = hand.size() - 1 # デフォルトはツモ切り
	var min_shanten = 99
	for i in range(hand.size()):
		var test_counts = counts.duplicate()
		test_counts[hand[i]] -= 1
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

# プレイヤーのツモ和了チェック
func can_player_tsumo() -> bool:
	if current_turn != 0 or current_drawn_tile == -1:
		return false
	var eval = YakuEvaluator.evaluate_hand(hands[0], current_drawn_tile, true, is_riichi[0], is_ippatsu[0], dora_indicators, dealer_idx == 0)
	return eval.is_agari

# プレイヤーの立直チェック
func can_player_riichi() -> bool:
	if current_turn != 0 or is_riichi[0] or scores[0] < 1000:
		return false
	# 手牌14枚のどれかを切ってテンパイ（シャンテン数0）になるか
	var counts: Array[int] = []
	counts.resize(34)
	counts.fill(0)
	for t in hands[0]:
		counts[t] += 1
	for t in hands[0]:
		counts[t] -= 1
		if YakuEvaluator.calculate_shanten(counts) == 0:
			counts[t] += 1
			return true
		counts[t] += 1
	return false
