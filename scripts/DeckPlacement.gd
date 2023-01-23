extends TextureButton

func _ready() -> void:
	var card_size = Global.card_size
	rect_scale = card_size/rect_size
	rect_position = Vector2(get_viewport().size.x/10 - card_size.x/2, get_viewport().size.y/2 - card_size.y/2)
