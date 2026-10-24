class_name TileRenderer
extends RefCounted

# 実在の本格麻雀ゲーム（雀魂、セガNET麻雀MJ、天鳳）基準の
# 視認性・美しさを極めたベクター描画レンダラー

# カラーパレット
const COL_FACE = Color(0.97, 0.96, 0.93)       # 象牙色の牌面
const COL_FACE_LIGHT = Color(1.0, 1.0, 0.98) # 上部ハイライト
const COL_FACE_DARK = Color(0.84, 0.82, 0.76)  # 陰影・面取り
const COL_BACK = Color(0.92, 0.65, 0.15)      # 背面（竹・山吹色）
const COL_BORDER = Color(0.50, 0.46, 0.40)    # 外枠線

const COL_RED = Color(0.82, 0.10, 0.12)       # 朱赤（萬・中・赤ドラ・赤ピン）
const COL_BLUE = Color(0.10, 0.32, 0.72)      # 藍色・群青（筒子・風牌）
const COL_GREEN = Color(0.08, 0.52, 0.22)     # 深緑・翡翠色（索子・發）
const COL_BLACK = Color(0.12, 0.12, 0.14)     # 墨黒（字牌・漢数字）
const COL_HAKU_FRAME = Color(0.48, 0.62, 0.78, 0.85) # 白の美麗フレーム

static func draw_tile(ci: CanvasItem, rect: Rect2, tile_id: int, is_selected: bool, is_hidden: bool) -> void:
	var w = rect.size.x
	var h = rect.size.y
	var pos = rect.position

	# ドロップシャドウ
	ci.draw_rect(Rect2(pos.x + 2, pos.y + 3, w - 2, h - 2), Color(0, 0, 0, 0.35), true)

	if is_hidden:
		# 伏せ牌（背面: 竹色とハイライト）
		ci.draw_rect(Rect2(pos.x, pos.y, w, h), COL_BACK, true)
		ci.draw_rect(Rect2(pos.x + 1, pos.y + 1, w - 2, h * 0.45), Color(0.98, 0.76, 0.25), true)
		ci.draw_rect(Rect2(pos.x, pos.y, w, h), Color(0.35, 0.22, 0.05), false, 1.2)
		return

	# 牌の立体面取り（Bevel）
	ci.draw_rect(Rect2(pos.x, pos.y, w, h), COL_FACE_DARK, true)
	ci.draw_rect(Rect2(pos.x, pos.y, w - 1.5, h - 2), COL_FACE_LIGHT, true)
	ci.draw_rect(Rect2(pos.x + 1.5, pos.y + 1.5, w - 3, h - 3), COL_FACE, true)

	# 枠線（選択時は発光シアン）
	var border_col = Color(0.2, 0.95, 1.0) if is_selected else COL_BORDER
	var border_width = 2.0 if is_selected else 1.0
	ci.draw_rect(Rect2(pos.x, pos.y, w, h), border_col, false, border_width)

	# 牌の絵柄描画
	var inner_rect = Rect2(pos.x + 2, pos.y + 2, w - 4, h - 4)
	_draw_pattern(ci, inner_rect, tile_id)

	# 選択時のハイライト枠
	if is_selected:
		ci.draw_rect(Rect2(pos.x, pos.y, w, h), Color(0.2, 0.95, 1.0, 0.25), true)

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
	
	# 手牌(h=58)と捨牌(h=25)でバランス調整
	var is_small = r.size.y < 35.0
	var font_sz = int(r.size.y * (0.42 if is_small else 0.44))
	
	# 本物基準: 漢数字は墨黒、下部の「萬」は鮮烈な朱赤
	var col_num = COL_BLACK
	var col_wan = COL_RED

	# 上段漢数字 (完全中央配置)
	var y_num = r.position.y + r.size.y * (0.38 if is_small else 0.40)
	ci.draw_string(font, Vector2(r.position.x, y_num), char_num, HORIZONTAL_ALIGNMENT_CENTER, int(r.size.x), font_sz, col_num)

	# 下段「萬」
	var y_wan = r.position.y + r.size.y * (0.84 if is_small else 0.88)
	ci.draw_string(font, Vector2(r.position.x, y_wan), "萬", HORIZONTAL_ALIGNMENT_CENTER, int(r.size.x), font_sz, col_wan)

# ---------------- 筒子 (Pinzu) ----------------
static func _draw_pinzu(ci: CanvasItem, r: Rect2, num: int) -> void:
	var cx = r.position.x + r.size.x * 0.5
	var cy = r.position.y + r.size.y * 0.5
	var w = r.size.x
	var h = r.size.y

	if num == 1:
		# 一筒 (雀魂・MJ基準の絢爛な菊花大車輪紋様)
		var rad = mini(int(w * 0.38), int(h * 0.38))
		# 外輪: 赤
		ci.draw_circle(Vector2(cx, cy), rad, COL_RED)
		ci.draw_circle(Vector2(cx, cy), rad * 0.82, COL_FACE)
		# 中環: 藍色
		ci.draw_circle(Vector2(cx, cy), rad * 0.68, COL_BLUE)
		ci.draw_circle(Vector2(cx, cy), rad * 0.50, COL_FACE)
		# 菊花弁 (8枚の菊の花びら)
		if w > 25.0:
			for i in range(8):
				var angle = i * (PI / 4.0)
				var petal_pos = Vector2(cx + cos(angle) * (rad * 0.36), cy + sin(angle) * (rad * 0.36))
				var petal_col = COL_RED if (i % 2 == 0) else COL_GREEN
				ci.draw_circle(petal_pos, rad * 0.12, petal_col)
		# 中心核: 赤
		ci.draw_circle(Vector2(cx, cy), rad * 0.22, COL_RED)
		ci.draw_circle(Vector2(cx, cy), rad * 0.08, Color.WHITE)
		return

	# 2〜9筒: 正統な菊花リング（二重輪＋中心点）
	var rad = mini(int(w * 0.13), int(h * 0.11))
	var lx = r.position.x + w * 0.30
	var rx = r.position.x + w * 0.70
	var ty = r.position.y + h * 0.24
	var my = r.position.y + h * 0.50
	var by = r.position.y + h * 0.76

	match num:
		2:
			_draw_pin_ring(ci, Vector2(cx, ty + 4), rad, COL_GREEN)
			_draw_pin_ring(ci, Vector2(cx, by - 4), rad, COL_BLUE)
		3:
			_draw_pin_ring(ci, Vector2(lx, ty), rad, COL_BLUE)
			_draw_pin_ring(ci, Vector2(cx, my), rad * 1.05, COL_RED)
			_draw_pin_ring(ci, Vector2(rx, by), rad, COL_GREEN)
		4:
			_draw_pin_ring(ci, Vector2(lx, ty), rad, COL_BLUE)
			_draw_pin_ring(ci, Vector2(rx, ty), rad, COL_GREEN)
			_draw_pin_ring(ci, Vector2(lx, by), rad, COL_GREEN)
			_draw_pin_ring(ci, Vector2(rx, by), rad, COL_BLUE)
		5:
			_draw_pin_ring(ci, Vector2(lx, ty), rad, COL_BLUE)
			_draw_pin_ring(ci, Vector2(rx, ty), rad, COL_GREEN)
			_draw_pin_ring(ci, Vector2(cx, my), rad * 1.15, COL_RED)
			_draw_pin_ring(ci, Vector2(lx, by), rad, COL_GREEN)
			_draw_pin_ring(ci, Vector2(rx, by), rad, COL_BLUE)
		6:
			_draw_pin_ring(ci, Vector2(lx, ty), rad, COL_GREEN)
			_draw_pin_ring(ci, Vector2(rx, ty), rad, COL_GREEN)
			_draw_pin_ring(ci, Vector2(lx, my), rad, COL_RED)
			_draw_pin_ring(ci, Vector2(rx, my), rad, COL_RED)
			_draw_pin_ring(ci, Vector2(lx, by), rad, COL_RED)
			_draw_pin_ring(ci, Vector2(rx, by), rad, COL_RED)
		7:
			_draw_pin_ring(ci, Vector2(lx - 2, ty - 2), rad * 0.95, COL_GREEN)
			_draw_pin_ring(ci, Vector2(cx, my - 6), rad * 0.95, COL_GREEN)
			_draw_pin_ring(ci, Vector2(rx + 2, my + 6), rad * 0.95, COL_GREEN)
			_draw_pin_ring(ci, Vector2(lx, my + 14), rad * 0.95, COL_RED)
			_draw_pin_ring(ci, Vector2(rx, my + 14), rad * 0.95, COL_RED)
			_draw_pin_ring(ci, Vector2(lx, by), rad * 0.95, COL_RED)
			_draw_pin_ring(ci, Vector2(rx, by), rad * 0.95, COL_RED)
		8:
			var y1 = r.position.y + h * 0.17
			var y2 = r.position.y + h * 0.38
			var y3 = r.position.y + h * 0.60
			var y4 = r.position.y + h * 0.81
			_draw_pin_ring(ci, Vector2(lx, y1), rad * 0.9, COL_BLUE)
			_draw_pin_ring(ci, Vector2(rx, y1), rad * 0.9, COL_BLUE)
			_draw_pin_ring(ci, Vector2(lx, y2), rad * 0.9, COL_BLUE)
			_draw_pin_ring(ci, Vector2(rx, y2), rad * 0.9, COL_BLUE)
			_draw_pin_ring(ci, Vector2(lx, y3), rad * 0.9, COL_BLUE)
			_draw_pin_ring(ci, Vector2(rx, y3), rad * 0.9, COL_BLUE)
			_draw_pin_ring(ci, Vector2(lx, y4), rad * 0.9, COL_BLUE)
			_draw_pin_ring(ci, Vector2(rx, y4), rad * 0.9, COL_BLUE)
		9:
			_draw_pin_ring(ci, Vector2(lx, ty), rad * 0.95, COL_BLUE)
			_draw_pin_ring(ci, Vector2(cx, ty), rad * 0.95, COL_BLUE)
			_draw_pin_ring(ci, Vector2(rx, ty), rad * 0.95, COL_BLUE)
			_draw_pin_ring(ci, Vector2(lx, my), rad * 0.95, COL_RED)
			_draw_pin_ring(ci, Vector2(cx, my), rad * 0.95, COL_RED)
			_draw_pin_ring(ci, Vector2(rx, my), rad * 0.95, COL_RED)
			_draw_pin_ring(ci, Vector2(lx, by), rad * 0.95, COL_GREEN)
			_draw_pin_ring(ci, Vector2(cx, by), rad * 0.95, COL_GREEN)
			_draw_pin_ring(ci, Vector2(rx, by), rad * 0.95, COL_GREEN)

static func _draw_pin_ring(ci: CanvasItem, pt: Vector2, rad: float, col: Color) -> void:
	# 外輪
	ci.draw_circle(pt, rad, col)
	# 内側の余白
	ci.draw_circle(pt, rad * 0.58, COL_FACE)
	# 中心の核
	ci.draw_circle(pt, rad * 0.28, col)

# ---------------- 索子 (Souzu) ----------------
static func _draw_souzu(ci: CanvasItem, r: Rect2, num: int) -> void:
	var cx = r.position.x + r.size.x * 0.5
	var cy = r.position.y + r.size.y * 0.5
	var w = r.size.x
	var h = r.size.y

	if num == 1:
		# 一索 (麻雀ゲーム伝統の孔雀・鳳凰シンボル)
		var s = mini(int(w * 0.45), int(h * 0.45))
		
		# 尾羽（扇状に広がるエメラルドグリーンの羽）
		var tail_angles = [-0.9, -0.6, -0.3, 0.0, 0.3, 0.6, 0.9]
		for a in tail_angles:
			var tip = Vector2(cx + sin(a) * (s * 0.85), cy - cos(a) * (s * 0.75))
			ci.draw_line(Vector2(cx, cy + s * 0.1), tip, COL_GREEN, 2.2)
			ci.draw_circle(tip, 1.8, COL_RED if abs(a) < 0.2 else COL_GREEN)

		# 胴体・翼 (緑のなめらかな体)
		ci.draw_circle(Vector2(cx, cy + s * 0.05), s * 0.35, COL_GREEN)
		ci.draw_circle(Vector2(cx, cy + s * 0.05), s * 0.22, COL_FACE)
		ci.draw_circle(Vector2(cx, cy + s * 0.05), s * 0.12, COL_RED)

		# 頭部・冠羽 (赤と青)
		var head_pos = Vector2(cx, cy - s * 0.30)
		ci.draw_circle(head_pos, s * 0.20, COL_RED)
		ci.draw_circle(Vector2(head_pos.x - 2, head_pos.y - 1), 1.2, Color.WHITE) # 瞳
		# くちばし
		ci.draw_line(Vector2(head_pos.x - s * 0.15, head_pos.y), Vector2(head_pos.x - s * 0.35, head_pos.y + 2), COL_BACK, 2.0)
		# 止まり木
		ci.draw_line(Vector2(cx - s * 0.45, cy + s * 0.45), Vector2(cx + s * 0.45, cy + s * 0.45), COL_BACK, 2.5)
		return

	# 2〜9索: 竹（節・赤帯リボン付き）
	var bar_w = maxf(3.2, w * 0.09)
	var bar_h = h * 0.33
	var lx = r.position.x + w * 0.28
	var rx = r.position.x + w * 0.72
	var ty = r.position.y + h * 0.18
	var by = r.position.y + h * 0.54

	match num:
		2:
			_draw_bamboo_stick(ci, Vector2(cx, ty + 2), bar_w * 1.3, bar_h * 1.1, COL_GREEN, true)
			_draw_bamboo_stick(ci, Vector2(cx, by - 2), bar_w * 1.3, bar_h * 1.1, COL_BLUE, true)
		3:
			_draw_bamboo_stick(ci, Vector2(cx, ty), bar_w * 1.1, bar_h, COL_BLUE, false)
			_draw_bamboo_stick(ci, Vector2(lx, by), bar_w * 1.1, bar_h, COL_GREEN, true)
			_draw_bamboo_stick(ci, Vector2(rx, by), bar_w * 1.1, bar_h, COL_GREEN, true)
		4:
			_draw_bamboo_stick(ci, Vector2(lx, ty), bar_w, bar_h, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(rx, ty), bar_w, bar_h, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(lx, by), bar_w, bar_h, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(rx, by), bar_w, bar_h, COL_GREEN, false)
		5:
			_draw_bamboo_stick(ci, Vector2(lx, ty), bar_w, bar_h, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(rx, ty), bar_w, bar_h, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(cx, r.position.y + h * 0.36), bar_w * 1.15, bar_h, COL_RED, true)
			_draw_bamboo_stick(ci, Vector2(lx, by), bar_w, bar_h, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(rx, by), bar_w, bar_h, COL_GREEN, false)
		6:
			_draw_bamboo_stick(ci, Vector2(lx, ty), bar_w, bar_h, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(cx, ty), bar_w, bar_h, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(rx, ty), bar_w, bar_h, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(lx, by), bar_w, bar_h, COL_BLUE, false)
			_draw_bamboo_stick(ci, Vector2(cx, by), bar_w, bar_h, COL_BLUE, false)
			_draw_bamboo_stick(ci, Vector2(rx, by), bar_w, bar_h, COL_BLUE, false)
		7:
			# 上1本（赤）、中3本（緑）、下3本（緑）
			_draw_bamboo_stick(ci, Vector2(cx, ty - 2), bar_w, bar_h * 0.85, COL_RED, true)
			_draw_bamboo_stick(ci, Vector2(lx, ty + bar_h * 0.35), bar_w, bar_h * 0.75, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(rx, ty + bar_h * 0.35), bar_w, bar_h * 0.75, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(lx, by + 2), bar_w, bar_h * 0.85, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(rx, by + 2), bar_w, bar_h * 0.85, COL_GREEN, false)
		8:
			# 日本伝統の八索: 「八」の字に広がる上4本＋下4本
			var sh = bar_h * 0.82
			_draw_bamboo_stick(ci, Vector2(lx - 2, ty), bar_w, sh, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(cx - 3, ty), bar_w, sh, COL_BLUE, false)
			_draw_bamboo_stick(ci, Vector2(cx + 3, ty), bar_w, sh, COL_BLUE, false)
			_draw_bamboo_stick(ci, Vector2(rx + 2, ty), bar_w, sh, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(lx - 2, by), bar_w, sh, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(cx - 3, by), bar_w, sh, COL_BLUE, false)
			_draw_bamboo_stick(ci, Vector2(cx + 3, by), bar_w, sh, COL_BLUE, false)
			_draw_bamboo_stick(ci, Vector2(rx + 2, by), bar_w, sh, COL_GREEN, false)
		9:
			var sh = bar_h * 0.80
			_draw_bamboo_stick(ci, Vector2(lx, ty), bar_w, sh, COL_BLUE, false)
			_draw_bamboo_stick(ci, Vector2(cx, ty), bar_w, sh, COL_RED, true)
			_draw_bamboo_stick(ci, Vector2(rx, ty), bar_w, sh, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(lx, r.position.y + h * 0.40), bar_w, sh, COL_BLUE, false)
			_draw_bamboo_stick(ci, Vector2(cx, r.position.y + h * 0.40), bar_w, sh, COL_RED, true)
			_draw_bamboo_stick(ci, Vector2(rx, r.position.y + h * 0.40), bar_w, sh, COL_GREEN, false)
			_draw_bamboo_stick(ci, Vector2(lx, by + 4), bar_w, sh, COL_BLUE, false)
			_draw_bamboo_stick(ci, Vector2(cx, by + 4), bar_w, sh, COL_RED, true)
			_draw_bamboo_stick(ci, Vector2(rx, by + 4), bar_w, sh, COL_GREEN, false)

static func _draw_bamboo_stick(ci: CanvasItem, pos: Vector2, w: float, h: float, col: Color, has_red_ribbon: bool) -> void:
	# 本物の竹節バー: 丸みと節の膨らみ
	var half_w = w * 0.5
	# メインの竹柱
	ci.draw_rect(Rect2(pos.x - half_w, pos.y, w, h), col, true)
	
	# 上下の節頭
	ci.draw_circle(Vector2(pos.x, pos.y + 1), half_w * 1.15, col)
	ci.draw_circle(Vector2(pos.x, pos.y + h - 1), half_w * 1.15, col)

	# 中央の節（白ハイライト＋節のリング）
	var mid_y = pos.y + h * 0.5
	ci.draw_rect(Rect2(pos.x - half_w - 0.8, mid_y - 1.2, w + 1.6, 2.4), COL_FACE, true)
	
	# 中央のリボン（赤アクセントまたは節ライン）
	var ribbon_col = COL_RED if has_red_ribbon else col
	ci.draw_rect(Rect2(pos.x - half_w - 0.5, mid_y - 0.6, w + 1.0, 1.2), ribbon_col, true)

# ---------------- 字牌 (Jihai) ----------------
static func _draw_jihai(ci: CanvasItem, r: Rect2, idx: int) -> void:
	# idx: 0=東, 1=南, 2=西, 3=北, 4=白, 5=發, 6=中
	if idx == 4:
		# 白 (実在ゲームの洗練されたダブルレリーフ枠)
		var pad_x = r.size.x * 0.20
		var pad_y = r.size.y * 0.16
		var outer_r = Rect2(r.position.x + pad_x, r.position.y + pad_y, r.size.x - pad_x * 2, r.size.y - pad_y * 2)
		ci.draw_rect(outer_r, COL_HAKU_FRAME, false, 1.8)
		ci.draw_rect(Rect2(outer_r.position.x + 2, outer_r.position.y + 2, outer_r.size.x - 4, outer_r.size.y - 4), Color(0.70, 0.82, 0.95, 0.5), false, 1.0)
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

	var is_small = r.size.y < 35.0
	var font_sz = int(r.size.y * (0.64 if is_small else 0.66))
	var baseline_y = r.position.y + r.size.y * (0.75 if is_small else 0.77)

	# 完全中央揃えで堂々と描画
	ci.draw_string(font, Vector2(r.position.x, baseline_y), ch, HORIZONTAL_ALIGNMENT_CENTER, int(r.size.x), font_sz, col)
