extends Control
class_name TileNode

@export var tile_id: int = 0
@export var is_selected: bool = false
@export var is_hidden: bool = false # 対戦相手の伏せ牌

func _ready() -> void:
	queue_redraw()

func set_tile(id: int, hidden: bool = false) -> void:
	tile_id = id
	is_hidden = hidden
	queue_redraw()

func set_selected(selected: bool) -> void:
	if is_selected != selected:
		is_selected = selected
		var target_y = -10.0 if is_selected else 0.0
		var tween = create_tween()
		tween.tween_property(self, "position:y", target_y, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		queue_redraw()

func _draw() -> void:
	TileRenderer.draw_tile(self, Rect2(Vector2.ZERO, size), tile_id, is_selected, is_hidden)
