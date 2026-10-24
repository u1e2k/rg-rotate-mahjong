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

# 牌配列（各牌の枚数カウント 34要素）からシャンテン数を計算 (0=テンパイ, -1=和了)
static func calculate_shanten(tile_counts: Array[int]) -> int:
	var shanten_standard = _shanten_standard(tile_counts)
	var shanten_chitoi = _shanten_chitoitsu(tile_counts)
	var shanten_kokushi = _shanten_kokushi(tile_counts)
	return mini(shanten_standard, mini(shanten_chitoi, shanten_kokushi))

# 七対子のシャンテン数
static func _shanten_chitoitsu(counts: Array[int]) -> int:
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
static func _shanten_kokushi(counts: Array[int]) -> int:
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

# 標準形（4面子1雀頭）のシャンテン数再帰計算
static func _shanten_standard(counts: Array[int]) -> int:
	var min_shanten = 8
	# 雀頭の候補を試す
	for i in range(34):
		if counts[i] >= 2:
			counts[i] -= 2
			var s = _calc_mentsu_shanten(counts, 0, 0, 0)
			min_shanten = mini(min_shanten, s - 1)
			counts[i] += 2
	
	# 雀頭なしの場合
	var s_no_head = _calc_mentsu_shanten(counts, 0, 0, 0)
	min_shanten = mini(min_shanten, s_no_head)
	return min_shanten

static func _calc_mentsu_shanten(counts: Array[int], idx: int, mentsu: int, taatsu: int) -> int:
	while idx < 34 and counts[idx] == 0:
		idx += 1
	if idx >= 34:
		var total = mentsu + taatsu
		if total > 4:
			taatsu -= (total - 4)
		return 8 - (mentsu * 2 + taatsu)

	var res = _calc_mentsu_shanten(counts, idx + 1, mentsu, taatsu)

	# 刻子
	if counts[idx] >= 3:
		counts[idx] -= 3
		res = mini(res, _calc_mentsu_shanten(counts, idx, mentsu + 1, taatsu))
		counts[idx] += 3

	# 順子 (数牌のみ)
	if idx < 27 and (idx % 9) <= 6:
		if counts[idx] >= 1 and counts[idx + 1] >= 1 and counts[idx + 2] >= 1:
			counts[idx] -= 1
			counts[idx + 1] -= 1
			counts[idx + 2] -= 1
			res = mini(res, _calc_mentsu_shanten(counts, idx, mentsu + 1, taatsu))
			counts[idx] += 1
			counts[idx + 1] += 1
			counts[idx + 2] += 1

	# 対子（ターツ候補）
	if counts[idx] >= 2:
		counts[idx] -= 2
		res = mini(res, _calc_mentsu_shanten(counts, idx, mentsu, taatsu + 1))
		counts[idx] += 2

	# 塔子 (両面・嵌張)
	if idx < 27 and (idx % 9) <= 7 and counts[idx + 1] >= 1:
		counts[idx] -= 1
		counts[idx + 1] -= 1
		res = mini(res, _calc_mentsu_shanten(counts, idx, mentsu, taatsu + 1))
		counts[idx] += 1
		counts[idx + 1] += 1

	if idx < 27 and (idx % 9) <= 6 and counts[idx + 2] >= 1:
		counts[idx] -= 1
		counts[idx + 2] -= 1
		res = mini(res, _calc_mentsu_shanten(counts, idx, mentsu, taatsu + 1))
		counts[idx] += 1
		counts[idx + 2] += 1

	return res

# 14枚の手牌から和了・役を判定
static func evaluate_hand(hand: Array[int], win_tile: int, is_tsumo: bool, is_riichi: bool, is_ippatsu: bool, dora_indicators: Array[int], is_dealer: bool) -> AgariResult:
	var result = AgariResult.new()
	var counts: Array[int] = []
	counts.resize(34)
	counts.fill(0)
	for t in hand:
		counts[t] += 1

	# シャンテン数判定 (-1 で和了)
	var shanten = calculate_shanten(counts)
	if shanten > -1:
		result.is_agari = false
		return result

	result.is_agari = true
	var yaku: Array[String] = []
	var han: int = 0

	# 役判定
	# 門前清自摸和
	if is_tsumo:
		yaku.append("門前清自摸和")
		han += 1

	# 立直
	if is_riichi:
		yaku.append("立直")
		han += 1
		if is_ippatsu:
			yaku.append("一発")
			han += 1

	# 断幺九（タンヤオ）
	var is_tanyao = true
	for i in range(34):
		if counts[i] > 0 and MahjongDefs.is_terminal_or_honor(i):
			is_tanyao = false
			break
	if is_tanyao:
		yaku.append("断幺九")
		han += 1

	# 役牌 (白, 發, 中)
	if counts[31] >= 3:
		yaku.append("役牌: 白")
		han += 1
	if counts[32] >= 3:
		yaku.append("役牌: 發")
		han += 1
	if counts[33] >= 3:
		yaku.append("役牌: 中")
		han += 1

	# 七対子
	var pairs = 0
	for c in counts:
		if c == 2:
			pairs += 1
	if pairs == 7:
		yaku.append("七対子")
		han += 2

	# 混一色・清一色
	var suit_counts = [0, 0, 0, 0] # 萬, 筒, 索, 字
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

	# ドラ判定
	var dora_count = 0
	for ind in dora_indicators:
		var target_dora = MahjongDefs.get_dora_next_id(ind)
		dora_count += counts[target_dora]
	if dora_count > 0:
		yaku.append("ドラ %d" % dora_count)
		han += dora_count

	# 役なし対策（初心者がロン・ツモしても楽しめるよう、役がなければ「平和(ピンフ)」扱いで1翻）
	if han == 0:
		yaku.append("平和")
		han = 1

	result.han = han
	result.fu = 25 if pairs == 7 else 30
	result.yaku_list = yaku

	# 点数計算
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
		# 簡易計算 (fu * 2^(han+2))
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
