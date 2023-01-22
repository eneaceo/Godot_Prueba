extends Control

func _ready() -> void:
	var card_size = $'../../.'.card_size
	rect_size = card_size * 2
	rect_position = Vector2(get_viewport().size.x/2 - card_size.x, get_viewport().size.y/2 - card_size.y)
