class_name MahjongDefs
extends RefCounted

# Tile Type Enums
enum Suit {
	MAN = 0,   # 萬子
	PIN = 1,   # 筒子
	SOU = 2,   # 索子
	JI = 3     # 字牌 (東南西北白發中)
}

enum Wind {
	EAST = 0,
	SOUTH = 1,
	WEST = 2,
	NORTH = 3
}

# 牌の名称・略記・漢字定義
const TILE_NAMES_JP = [
	"一萬", "二萬", "三萬", "四萬", "五萬", "六萬", "七萬", "八萬", "九萬",
	"一筒", "二筒", "三筒", "四筒", "五筒", "六筒", "七筒", "八筒", "九筒",
	"一索", "二索", "三索", "四索", "五索", "六索", "七索", "八索", "九索",
	"東", "南", "西", "北", "白", "發", "中"
]

const TILE_SHORT_JP = [
	"一", "二", "三", "四", "五", "六", "七", "八", "九",
	"①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨",
	"1", "2", "3", "4", "5", "6", "7", "8", "9",
	"東", "南", "西", "北", "白", "發", "中"
]

static func id_to_suit(tile_id: int) -> int:
	if tile_id < 9:
		return Suit.MAN
	elif tile_id < 18:
		return Suit.PIN
	elif tile_id < 27:
		return Suit.SOU
	else:
		return Suit.JI

static func id_to_num(tile_id: int) -> int:
	if tile_id < 27:
		return (tile_id % 9) + 1
	return (tile_id - 27) + 1 # 字牌: 1=東, 2=南, 3=西, 4=北, 5=白, 6=發, 7=中

static func make_tile_id(suit: int, num: int) -> int:
	if suit == Suit.MAN:
		return num - 1
	elif suit == Suit.PIN:
		return 9 + num - 1
	elif suit == Suit.SOU:
		return 18 + num - 1
	else:
		return 27 + num - 1

static func is_terminal_or_honor(tile_id: int) -> bool:
	if tile_id >= 27:
		return true
	var n = id_to_num(tile_id)
	return n == 1 or n == 9

static func is_sanma_excluded(tile_id: int) -> bool:
	# 3人麻雀では二萬〜八萬 (tile_id 1〜7) を除外
	return tile_id >= 1 and tile_id <= 7

static func get_dora_next_id(tile_id: int) -> int:
	# 表示牌の次の牌がドラ
	if tile_id < 9:
		return (tile_id + 1) if tile_id < 8 else 0
	elif tile_id < 18:
		return (tile_id + 1) if tile_id < 17 else 9
	elif tile_id < 27:
		return (tile_id + 1) if tile_id < 26 else 18
	elif tile_id < 31: # 東南西北
		return 27 + ((tile_id - 27 + 1) % 4)
	else: # 白發中
		return 31 + ((tile_id - 31 + 1) % 3)
