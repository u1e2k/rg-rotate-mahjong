class_name TileRenderer
extends RefCounted

# 麻雀牌の本物に近い意匠をベクター・プロシージャル描画するレンダラー

# カラーパレット (実物麻雀牌基準)
const COL_FACE = Color(0.97, 0.96, 0.92) # 象牙色の表面
const COL_FACE_LIGHT = Color(1.0, 1.0, 0.98) # ハイライト
const COL_FACE_DARK = Color(0.85, 0.83, 0.78) # 影
const COL_BACK = Color(0.92, 0.68, 0.18) # 竹・黄色の背面
const COL_BORDER = Color(0.48, 0.44, 0.38)

const COL_RED = Color(0.85, 0.12, 0.15) # 深い朱赤
const COL_BLUE = Color(0.12, 0.35, 0.75) # 藍色・青
const COL_GREEN = Color(0.1, 0.55, 0.22) # 深緑・翡翠色
const COL_BLACK = Color(0.12, 0.12, 0.15) # 墨黒

static func draw_tile(ci: CanvasItem, rect: Rect2, tile_id: int, is_selected: bool, is_hidden: bool) -> void:
	var w = rect.size.x
	var h = rect.size.y
	var pos = rect.position

	# ドロップシャドウ
	ci.draw_rect(Rect2(pos.x + 2, pos.y + 3, w - 2, h - 2), Color(0, 0, 0, 0.3), true)

	if is_hidden:
		# 伏せ牌（背面: 竹色とプラスチックの光沢）
		ci.draw_rect(Rect2(pos.x, pos.y, w, h), COL_BACK, true)
		ci.draw_rect(Rect2(pos.x + 1, pos.y + 1, w - 2, h - 2), Color(0.98, 0.75, 0.25), true)
		ci.draw_rect(Rect2(pos.x, pos.y, w, h), Color(0.35, 0.25, 0.05), false, 1.2)
		return

	# 牌の立体面取り（Bevel）と表面
	ci.draw_rect(Rect2(pos.x, pos.y, w, h), COL_FACE_DARK, true)
	ci.draw_rect(Rect2(pos.x, pos.y, w - 1.5, h - 2), COL_FACE_LIGHT, true)
	ci.draw_rect(Rect2(pos.x + 1.5, pos.y + 1.5, w - 3, h - 3), COL_FACE, true)

	# 枠線
	var border_col = Color(0.2, 0.9, 1.0) if is_selected else COL_BORDER
	var border_width = 2.0 if is_selected else 1.0
	ci.draw_rect(Rect2(pos.x, pos.y, w, h), border_col, false, border_width)

	# 牌の絵柄描画
	var inner_rect = Rect2(pos.x + 2, pos.y + 3, w - 4, h - 6)
	_draw_pattern(ci, inner_rect, tile_id)

	# 選択時のハイライト枠
	if is_selected:
		ci.draw_rect(Rect2(pos.x, pos.y, w, h), Color(0.2, 0.9, 1.0, 0.2), true)

static func _draw_pattern(ci: CanvasItem, r: Rect2, tile_id: int) -> void:
	var suit = MahjongDefs.id_to_suit(tile_id)
	var num = MahjongDefs.id_to_num(tile_id)

	if suit == MahjongDefs.Suit.MAN:
		_draw_manzu(ci, r, num)
	elif suit == MahjongDefs.Suit.PIN:
		_draw_pinzu(ci, r, num)
	elif suit == MahjongDefs.Suit.SOU:
		_draw_souzu(ci, r, num)
	else:
		_draw_jihai(ci, r, tile_id - 27)

# ---------------- 萬子 (Manzu) ----------------
static func _draw_manzu(ci: CanvasItem, r: Rect2, num: int) -> void:
	var font = ThemeDB.fallback_font
	if not font:
		return

	var num_chars = ["一", "二", "三", "四", "五", "六", "七", "八", "九"]
	var char_num = num_chars[num - 1]
	var font_sz = int(r.size.y * 0.42)
	var col_num = COL_RED if num == 1 or num == 5 or num == 7 or num == 9 else COL_BLACK

	# 上段の漢数字
	var pos_num = Vector2(r.position.x + r.size.x * 0.5 - font_sz * 0.45, r.position.y + r.size.y * 0.42)
	ci.draw_string(font, pos_num, char_num, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, col_num)

	# 下段の「萬」
	var pos_wan = Vector2(r.position.x + r.size.x * 0.5 - font_sz * 0.45, r.position.y + r.size.y * 0.90)
	ci.draw_string(font, pos_wan, "萬", HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, COL_RED)

# ---------------- 筒子 (Pinzu) ----------------
static func _draw_pinzu(ci: CanvasItem, r: Rect2, num: int) -> void:
	var cx = r.position.x + r.size.x * 0.5
	var cy = r.position.y + r.size.y * 0.5
	var w = r.size.x
	var h = r.size.y

	if num == 1:
		# 一筒 (大きな大車輪・菊花紋)
		var rad = mini(int(w * 0.38), int(h * 0.38))
		ci.draw_circle(Vector2(cx, cy), rad, COL_RED)
		ci.draw_circle(Vector2(cx, cy), rad * 0.72, COL_FACE)
		ci.draw_circle(Vector2(cx, cy), rad * 0.50, COL_BLUE)
		ci.draw_circle(Vector2(cx, cy), rad * 0.28, COL_FACE)
		ci.draw_circle(Vector2(cx, cy), rad * 0.14, COL_RED)
		return

	# 2〜9筒: 複数の円環（ピン）
	var rad = mini(int(w * 0.14), int(h * 0.12))
	var lx = r.position.x + w * 0.30
	var rx = r.position.x + w * 0.70
	var ty = r.position.y + h * 0.24
	var my = r.position.y + h * 0.50
	var by = r.position.y + h * 0.76

	match num:
		2:
			_draw_pin_circle(ci, Vector2(cx, ty + 4), rad, COL_GREEN)
			_draw_pin_circle(ci, Vector2(cx, by - 4), rad, COL_BLUE)
		3:
			_draw_pin_circle(ci, Vector2(lx, ty), rad, COL_BLUE)
			_draw_pin_circle(ci, Vector2(cx, my), rad, COL_RED)
			_draw_pin_circle(ci, Vector2(rx, by), rad, COL_GREEN)
		4:
			_draw_pin_circle(ci, Vector2(lx, ty), rad, COL_BLUE)
			_draw_pin_circle(ci, Vector2(rx, ty), rad, COL_GREEN)
			_draw_pin_circle(ci, Vector2(lx, by), rad, COL_GREEN)
			_draw_pin_circle(ci, Vector2(rx, by), rad, COL_BLUE)
		5:
			_draw_pin_circle(ci, Vector2(lx, ty), rad, COL_BLUE)
			_draw_pin_circle(ci, Vector2(rx, ty), rad, COL_GREEN)
			_draw_pin_circle(ci, Vector2(cx, my), rad * 1.1, COL_RED)
			_draw_pin_circle(ci, Vector2(lx, by), rad, COL_GREEN)
			_draw_pin_circle(ci, Vector2(rx, by), rad, COL_BLUE)
		6:
			_draw_pin_circle(ci, Vector2(lx, ty), rad, COL_GREEN)
			_draw_pin_circle(ci, Vector2(rx, ty), rad, COL_GREEN)
			_draw_pin_circle(ci, Vector2(lx, my), rad, COL_RED)
			_draw_pin_circle(ci, Vector2(rx, my), rad, COL_RED)
			_draw_pin_circle(ci, Vector2(lx, by), rad, COL_RED)
			_draw_pin_circle(ci, Vector2(rx, by), rad, COL_RED)
		7:
			_draw_pin_circle(ci, Vector2(lx - 2, ty - 2), rad * 0.9, COL_GREEN)
			_draw_pin_circle(ci, Vector2(cx, my - 6), rad * 0.9, COL_GREEN)
			_draw_pin_circle(ci, Vector2(rx + 2, my + 6), rad * 0.9, COL_GREEN)
			_draw_pin_circle(ci, Vector2(lx, my + 14), rad * 0.9, COL_RED)
			_draw_pin_circle(ci, Vector2(rx, my + 14), rad * 0.9, COL_RED)
			_draw_pin_circle(ci, Vector2(lx, by), rad * 0.9, COL_RED)
			_draw_pin_circle(ci, Vector2(rx, by), rad * 0.9, COL_RED)
		8:
			var y1 = r.position.y + h * 0.18
			var y2 = r.position.y + h * 0.39
			var y3 = r.position.y + h * 0.61
			var y4 = r.position.y + h * 0.82
			_draw_pin_circle(ci, Vector2(lx, y1), rad * 0.85, COL_BLUE)
			_draw_pin_circle(ci, Vector2(rx, y1), rad * 0.85, COL_BLUE)
			_draw_pin_circle(ci, Vector2(lx, y2), rad * 0.85, COL_BLUE)
			_draw_pin_circle(ci, Vector2(rx, y2), rad * 0.85, COL_BLUE)
			_draw_pin_circle(ci, Vector2(lx, y3), rad * 0.85, COL_BLUE)
			_draw_pin_circle(ci, Vector2(rx, y3), rad * 0.85, COL_BLUE)
			_draw_pin_circle(ci, Vector2(lx, y4), rad * 0.85, COL_BLUE)
			_draw_pin_circle(ci, Vector2(rx, y4), rad * 0.85, COL_BLUE)
		9:
			_draw_pin_circle(ci, Vector2(lx, ty), rad * 0.9, COL_BLUE)
			_draw_pin_circle(ci, Vector2(cx, ty), rad * 0.9, COL_BLUE)
			_draw_pin_circle(ci, Vector2(rx, ty), rad * 0.9, COL_BLUE)
			_draw_pin_circle(ci, Vector2(lx, my), rad * 0.9, COL_RED)
			_draw_pin_circle(ci, Vector2(cx, my), rad * 0.9, COL_RED)
			_draw_pin_circle(ci, Vector2(rx, my), rad * 0.9, COL_RED)
			_draw_pin_circle(ci, Vector2(lx, by), rad * 0.9, COL_GREEN)
			_draw_pin_circle(ci, Vector2(cx, by), rad * 0.9, COL_GREEN)
			_draw_pin_circle(ci, Vector2(rx, by), rad * 0.9, COL_GREEN)

static func _draw_pin_circle(ci: CanvasItem, pt: Vector2, rad: float, col: Color) -> void:
	ci.draw_circle(pt, rad, col)
	ci.draw_circle(pt, rad * 0.45, COL_FACE)
	ci.draw_circle(pt, rad * 0.20, col)

# ---------------- 索子 (Souzu) ----------------
static func _draw_souzu(ci: CanvasItem, r: Rect2, num: int) -> void:
	var cx = r.position.x + r.size.x * 0.5
	var cy = r.position.y + r.size.y * 0.5
	var w = r.size.x
	var h = r.size.y

	if num == 1:
		# 一索 (鳥・孔雀の美しいシンボル)
		var bird_r = mini(int(w * 0.36), int(h * 0.36))
		# 尾羽
		ci.draw_arc(Vector2(cx, cy + 4), bird_r * 0.75, PI * 0.8, PI * 2.2, 16, COL_GREEN, 3.0)
		ci.draw_circle(Vector2(cx, cy), bird_r * 0.45, COL_GREEN)
		# 胸・頭
		ci.draw_circle(Vector2(cx, cy - bird_r * 0.35), bird_r * 0.30, COL_RED)
		ci.draw_circle(Vector2(cx - 2, cy - bird_r * 0.4), 1.5, Color.WHITE) # 目
		# 冠羽
		ci.draw_line(Vector2(cx, cy - bird_r * 0.6), Vector2(cx, cy - bird_r * 0.9), COL_BLUE, 2.0)
		return

	# 2〜9索: 竹（バー）の描画
	var bar_w = maxf(3.0, w * 0.08)
	var bar_h = h * 0.32
	var lx = r.position.x + w * 0.28
	var rx = r.position.x + w * 0.72
	var ty = r.position.y + h * 0.18
	var by = r.position.y + h * 0.54

	match num:
		2:
			_draw_bamboo_stick(ci, Vector2(cx, ty + 2), bar_w * 1.2, bar_h * 1.1, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(cx, by - 2), bar_w * 1.2, bar_h * 1.1, COL_BLUE)
		3:
			_draw_bamboo_stick(ci, Vector2(cx, ty), bar_w, bar_h, COL_BLUE)
			_draw_bamboo_stick(ci, Vector2(lx, by), bar_w, bar_h, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(rx, by), bar_w, bar_h, COL_GREEN)
		4:
			_draw_bamboo_stick(ci, Vector2(lx, ty), bar_w, bar_h, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(rx, ty), bar_w, bar_h, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(lx, by), bar_w, bar_h, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(rx, by), bar_w, bar_h, COL_GREEN)
		5:
			_draw_bamboo_stick(ci, Vector2(lx, ty), bar_w, bar_h, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(rx, ty), bar_w, bar_h, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(cx, r.position.y + h * 0.36), bar_w * 1.1, bar_h, COL_RED)
			_draw_bamboo_stick(ci, Vector2(lx, by), bar_w, bar_h, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(rx, by), bar_w, bar_h, COL_GREEN)
		6:
			_draw_bamboo_stick(ci, Vector2(lx, ty), bar_w, bar_h, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(cx, ty), bar_w, bar_h, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(rx, ty), bar_w, bar_h, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(lx, by), bar_w, bar_h, COL_BLUE)
			_draw_bamboo_stick(ci, Vector2(cx, by), bar_w, bar_h, COL_BLUE)
			_draw_bamboo_stick(ci, Vector2(rx, by), bar_w, bar_h, COL_BLUE)
		7:
			_draw_bamboo_stick(ci, Vector2(cx, ty - 2), bar_w, bar_h * 0.9, COL_RED)
			_draw_bamboo_stick(ci, Vector2(lx, ty + bar_h * 0.3), bar_w, bar_h * 0.8, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(rx, ty + bar_h * 0.3), bar_w, bar_h * 0.8, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(lx, by + 2), bar_w, bar_h * 0.9, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(rx, by + 2), bar_w, bar_h * 0.9, COL_GREEN)
		8:
			var sh = bar_h * 0.8
			_draw_bamboo_stick(ci, Vector2(lx - 2, ty), bar_w, sh, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(cx - 3, ty), bar_w, sh, COL_BLUE)
			_draw_bamboo_stick(ci, Vector2(cx + 3, ty), bar_w, sh, COL_BLUE)
			_draw_bamboo_stick(ci, Vector2(rx + 2, ty), bar_w, sh, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(lx - 2, by), bar_w, sh, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(cx - 3, by), bar_w, sh, COL_BLUE)
			_draw_bamboo_stick(ci, Vector2(cx + 3, by), bar_w, sh, COL_BLUE)
			_draw_bamboo_stick(ci, Vector2(rx + 2, by), bar_w, sh, COL_GREEN)
		9:
			var sh = bar_h * 0.8
			_draw_bamboo_stick(ci, Vector2(lx, ty), bar_w, sh, COL_BLUE)
			_draw_bamboo_stick(ci, Vector2(cx, ty), bar_w, sh, COL_RED)
			_draw_bamboo_stick(ci, Vector2(rx, ty), bar_w, sh, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(lx, r.position.y + h * 0.40), bar_w, sh, COL_BLUE)
			_draw_bamboo_stick(ci, Vector2(cx, r.position.y + h * 0.40), bar_w, sh, COL_RED)
			_draw_bamboo_stick(ci, Vector2(rx, r.position.y + h * 0.40), bar_w, sh, COL_GREEN)
			_draw_bamboo_stick(ci, Vector2(lx, by + 4), bar_w, sh, COL_BLUE)
			_draw_bamboo_stick(ci, Vector2(cx, by + 4), bar_w, sh, COL_RED)
			_draw_bamboo_stick(ci, Vector2(rx, by + 4), bar_w, sh, COL_GREEN)

static func _draw_bamboo_stick(ci: CanvasItem, pos: Vector2, w: float, h: float, col: Color) -> void:
	# 竹の節のある棒を描画
	var half_w = w * 0.5
	ci.draw_rect(Rect2(pos.x - half_w, pos.y, w, h), col, true)
	# 節 (中央と上下のリング)
	ci.draw_rect(Rect2(pos.x - half_w - 0.8, pos.y + h * 0.48, w + 1.6, 2.0), COL_FACE, true)
	ci.draw_rect(Rect2(pos.x - half_w - 0.8, pos.y, w + 1.6, 1.5), col, true)
	ci.draw_rect(Rect2(pos.x - half_w - 0.8, pos.y + h - 1.5, w + 1.6, 1.5), col, true)

# ---------------- 字牌 (Jihai) ----------------
static func _draw_jihai(ci: CanvasItem, r: Rect2, idx: int) -> void:
	# idx: 0=東, 1=南, 2=西, 3=北, 4=白, 5=發, 6=中
	if idx == 4:
		# 白 (完全無地、または実物牌の上品な凹み/細枠)
		# 実物麻雀牌の「白」は無地
		return

	var font = ThemeDB.fallback_font
	if not font:
		return

	var chars = ["東", "南", "西", "北", "", "發", "中"]
	var ch = chars[idx]
	var col = COL_BLACK
	if idx == 5:
		col = COL_GREEN # 發
	elif idx == 6:
		col = COL_RED   # 中

	var font_sz = int(r.size.y * 0.68)
	var pos = Vector2(r.position.x + r.size.x * 0.5 - font_sz * 0.48, r.position.y + r.size.y * 0.75)
	ci.draw_string(font, pos, ch, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, col)
