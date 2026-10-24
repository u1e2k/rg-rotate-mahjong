class_name YakuEvaluator
extends RefCounted

# 和了判定結果
class AgariResult:
	var is_agari: bool = false
	var han: int = 0
	var fu: int = 30
	var yaku_list: Array[String] = []
	var score: int = 0
	var score_text: String = ""

# シャンテン数計算 (0=テンパイ, -1=和了)
static func calculate_shanten(tile_counts: Array) -> int:
	var shanten_standard = _shanten_standard(tile_counts)
	var shanten_chitoi = _shanten_chitoitsu(tile_counts)
	var shanten_kokushi = _shanten_kokushi(tile_counts)
	return mini(shanten_standard, mini(shanten_chitoi, shanten_kokushi))

# 七対子のシャンテン数
static func _shanten_chitoitsu(counts: Array) -> int:
	var pairs = 0
	var kinds = 0
	for c in counts:
		if c >= 2:
			pairs += 1
		if c >= 1:
			kinds += 1
	var shanten = 6 - pairs
	if kinds < 7:
		shanten += 7 - kinds
	return shanten

# 国士無双のシャンテン数
static func _shanten_kokushi(counts: Array) -> int:
	var terminals = [0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33]
	var kinds = 0
	var has_pair = false
	for t in terminals:
		if counts[t] >= 1:
			kinds += 1
		if counts[t] >= 2:
			has_pair = true
	var shanten = 13 - kinds - (1 if has_pair else 0)
	return shanten

# ----------------- 高速標準形シャンテン数 (スート分割法 & Vector2i最適化) -----------------

static func _shanten_standard(counts: Array) -> int:
	var min_shanten = 8

	# 1. 雀頭ありのケース
	for i in range(34):
		if counts[i] >= 2:
			counts[i] -= 2
			var mt = _calc_total_mentsu_taatsu(counts)
			var m = mt.x
			var t = mt.y
			if m + t > 4:
				t = 4 - m
			var s = 8 - (m * 2 + t) - 1
			min_shanten = mini(min_shanten, s)
			counts[i] += 2

	# 2. 雀頭なしのケース
	var mt_nh = _calc_total_mentsu_taatsu(counts)
	var m_nh = mt_nh.x
	var t_nh = mt_nh.y
	if m_nh + t_nh > 4:
		t_nh = 4 - m_nh
	var s_nh = 8 - (m_nh * 2 + t_nh)
	min_shanten = mini(min_shanten, s_nh)

	return min_shanten

static func _calc_total_mentsu_taatsu(counts: Array) -> Vector2i:
	var man = _calc_suit_mentsu_taatsu(counts, 0)
	var pin = _calc_suit_mentsu_taatsu(counts, 9)
	var sou = _calc_suit_mentsu_taatsu(counts, 18)

	var ji_m = 0
	var ji_t = 0
	for i in range(27, 34):
		if counts[i] >= 3:
			ji_m += 1
		elif counts[i] == 2:
			ji_t += 1

	return Vector2i(
		man.x + pin.x + sou.x + ji_m,
		man.y + pin.y + sou.y + ji_t
	)

static func _calc_suit_mentsu_taatsu(counts: Array, offset: int) -> Vector2i:
	var sub: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0]
	var total_tiles = 0
	for i in range(9):
		var c = counts[offset + i]
		sub[i] = c
		total_tiles += c

	if total_tiles == 0:
		return Vector2i.ZERO

	return _search_sub_suit(sub, 0, 0, 0)

static func _search_sub_suit(sub: Array, idx: int, m: int, t: int) -> Vector2i:
	while idx < 9 and sub[idx] == 0:
		idx += 1
	if idx >= 9:
		return Vector2i(m, t)

	var best = Vector2i(m, t)
	var best_score = m * 10 + t

	# 刻子
	if sub[idx] >= 3:
		sub[idx] -= 3
		var res = _search_sub_suit(sub, idx, m + 1, t)
		sub[idx] += 3
		var sc = res.x * 10 + res.y
		if sc > best_score:
			best = res
			best_score = sc

	# 順子
	if idx <= 6 and sub[idx] >= 1 and sub[idx + 1] >= 1 and sub[idx + 2] >= 1:
		sub[idx] -= 1
		sub[idx + 1] -= 1
		sub[idx + 2] -= 1
		var res = _search_sub_suit(sub, idx, m + 1, t)
		sub[idx] += 1
		sub[idx + 1] += 1
		sub[idx + 2] += 1
		var sc = res.x * 10 + res.y
		if sc > best_score:
			best = res
			best_score = sc

	# 対子
	if sub[idx] >= 2:
		sub[idx] -= 2
		var res = _search_sub_suit(sub, idx, m, t + 1)
		sub[idx] += 2
		var sc = res.x * 10 + res.y
		if sc > best_score:
			best = res
			best_score = sc

	# 嵌張/両面
	if idx <= 7 and sub[idx + 1] >= 1:
		sub[idx] -= 1
		sub[idx + 1] -= 1
		var res = _search_sub_suit(sub, idx, m, t + 1)
		sub[idx] += 1
		sub[idx + 1] += 1
		var sc = res.x * 10 + res.y
		if sc > best_score:
			best = res
			best_score = sc

	if idx <= 6 and sub[idx + 2] >= 1:
		sub[idx] -= 1
		sub[idx + 2] -= 1
		var res = _search_sub_suit(sub, idx, m, t + 1)
		sub[idx] += 1
		sub[idx + 2] += 1
		var sc = res.x * 10 + res.y
		if sc > best_score:
			best = res
			best_score = sc

	# スキップ
	var res_skip = _search_sub_suit(sub, idx + 1, m, t)
	var sc_skip = res_skip.x * 10 + res_skip.y
	if sc_skip > best_score:
		best = res_skip

	return best

# ----------------- 和了・役評価 -----------------

static func evaluate_hand(hand: Array, win_tile: int, is_tsumo: bool, is_riichi: bool, is_ippatsu: bool, dora_indicators: Array, is_dealer: bool) -> AgariResult:
	var result = AgariResult.new()
	var counts: Array[int] = []
	counts.resize(34)
	counts.fill(0)
	for t in hand:
		counts[t] += 1

	var shanten = calculate_shanten(counts)
	if shanten > -1:
		result.is_agari = false
		return result

	result.is_agari = true
	var yaku: Array[String] = []
	var han: int = 0

	if is_tsumo:
		yaku.append("門前清自摸和")
		han += 1

	if is_riichi:
		yaku.append("立直")
		han += 1
		if is_ippatsu:
			yaku.append("一発")
			han += 1

	var is_tanyao = true
	for i in range(34):
		if counts[i] > 0 and MahjongDefs.is_terminal_or_honor(i):
			is_tanyao = false
			break
	if is_tanyao:
		yaku.append("断幺九")
		han += 1

	if counts[31] >= 3:
		yaku.append("役牌: 白")
		han += 1
	if counts[32] >= 3:
		yaku.append("役牌: 發")
		han += 1
	if counts[33] >= 3:
		yaku.append("役牌: 中")
		han += 1

	var pairs = 0
	for c in counts:
		if c == 2:
			pairs += 1
	if pairs == 7:
		yaku.append("七対子")
		han += 2

	var suit_counts = [0, 0, 0, 0]
	for i in range(34):
		if counts[i] > 0:
			suit_counts[MahjongDefs.id_to_suit(i)] += counts[i]
	var num_suits = 0
	for s in range(3):
		if suit_counts[s] > 0:
			num_suits += 1
	if num_suits == 1:
		if suit_counts[3] > 0:
			yaku.append("混一色")
			han += 3
		else:
			yaku.append("清一色")
			han += 6

	var dora_count = 0
	for ind in dora_indicators:
		var target_dora = MahjongDefs.get_dora_next_id(ind)
		dora_count += counts[target_dora]
	if dora_count > 0:
		yaku.append("ドラ %d" % dora_count)
		han += dora_count

	if han == 0:
		yaku.append("平和")
		han = 1

	result.han = han
	result.fu = 25 if pairs == 7 else 30
	result.yaku_list = yaku

	_calculate_score(result, is_dealer, is_tsumo)
	return result

static func _calculate_score(res: AgariResult, is_dealer: bool, _is_tsumo: bool) -> void:
	var h = res.han
	var base_points = 0
	var title = ""

	if h >= 13:
		base_points = 8000
		title = "数え役満"
	elif h >= 11:
		base_points = 6000
		title = "三倍満"
	elif h >= 8:
		base_points = 4000
		title = "倍満"
	elif h >= 6:
		base_points = 3000
		title = "跳満"
	elif h >= 5 or (h == 4 and res.fu >= 40) or (h == 3 and res.fu >= 70):
		base_points = 2000
		title = "満貫"
	else:
		base_points = mini(2000, res.fu * int(pow(2, h + 2)))

	var total_score = 0
	if is_dealer:
		total_score = int(ceil(float(base_points * 6) / 100.0)) * 100
	else:
		total_score = int(ceil(float(base_points * 4) / 100.0)) * 100

	res.score = total_score
	if title != "":
		res.score_text = "%s (%d翻 %d点)" % [title, h, total_score]
	else:
		res.score_text = "%d翻 %d符 (%d点)" % [h, res.fu, total_score]
