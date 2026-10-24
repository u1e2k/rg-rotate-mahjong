extends Control
class_name TileNode

@export var tile_id: int = 0
@export var is_selected: bool = false
@export var is_hidden: bool = false
@export var is_horizontal: bool = false # リーチ宣言牌などの横向き表示

func _ready() -> void:
	queue_redraw()

func set_tile(id: int, hidden: bool = false, horizontal: bool = false) -> void:
	tile_id = id
	is_hidden = hidden
	is_horizontal = horizontal
	queue_redraw()

func set_selected(selected: bool) -> void:
	if is_selected != selected:
		is_selected = selected
		var target_y = -10.0 if is_selected else 0.0
		var tween = create_tween()
		tween.tween_property(self, "position:y", target_y, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		queue_redraw()

func _draw() -> void:
	if is_horizontal:
		draw_set_transform(Vector2(size.x, 0), PI * 0.5, Vector2.ONE)
		TileRenderer.draw_tile(self, Rect2(Vector2.ZERO, Vector2(size.y, size.x)), tile_id, is_selected, is_hidden)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		TileRenderer.draw_tile(self, Rect2(Vector2.ZERO, size), tile_id, is_selected, is_hidden)
