extends Control

const card_size : Vector2 = Vector2(100,150)

var card_color: String = ""
var card_number: int = 0

enum STATES {
	onDeck,
	onMovingToHand,
	onPlayerHand,
	onMouse,
	onPlayed
	}
	
var state = STATES.onDeck

signal finish_draw_card
var start_position : Vector2 = Vector2.ZERO
var target_position : Vector2 = Vector2.ZERO
var time : float = 0

var mouse : bool = false
var last_position: Vector2 = Vector2.ZERO
var scale : Vector2 = Vector2.ONE

func _init_Card(number: int, color: String) -> void:
	
	card_color = color
	card_number = number
	
	_init_Card_textures()
	
	match (color):
		"Red":
			$Background.color = Color(1, 0, 0, 1)
		"Green":
			$Background.color = Color(0, 1, 0, 1)
		"Blue":
			$Background.color = Color(0, 0, 1, 1)
		"Yellow":
			$Background.color = Color(1, 1, 0, 1)
	$Number.set_text(String(number))
	$NumberUp.set_text(String(number))

func _ready() -> void:
	set_global_position(get_global_mouse_position())

func _init_Card_textures() -> void :
	rect_size = card_size
	$Background.rect_size = card_size
	$Background/Border.rect_size = card_size
	$Number.rect_size = card_size/10
	$Number.rect_position = Vector2($Number.rect_size.x, $Number.rect_size.y)
	$NumberUp.rect_size = card_size/20
	$NumberUp.rect_position = Vector2(card_size.x/6 - $Number.rect_size.x, card_size.y/6 - $Number.rect_size.y)
	$CardBack.scale = card_size/$CardBack.texture.get_size()
	$CardBack.position = Vector2(card_size.x/2, card_size.y/2)

func _physics_process(delta: float) -> void:
	match state:
		STATES.onDeck:
			pass
		STATES.onPlayed:
			pass
		STATES.onMovingToHand:
			time = time + delta
			rect_position = lerp(start_position, target_position, time)
			if rect_position == target_position :
				$CardBack.visible = false
				time = 0
				state = STATES.onPlayerHand
				Global.play_scene.update_player_cards_position()
		STATES.onPlayerHand:
			if mouse:
				$Background/Border.border_color = Color(1,0.5,0,1)
				if rect_scale != scale * 1.25 :
					rect_scale = lerp(rect_scale, scale * 1.25, delta * 4)
			else:
				$Background/Border.border_color = Color(1,1,1,1)
				if rect_scale != scale :
					rect_scale = lerp(rect_scale, scale, delta * 8)
			if Input.is_action_just_pressed("left_click") and mouse:
				last_position = rect_position
				rect_scale = scale
				$Background/Border.border_color = Color(1,1,1,1)
				state = STATES.onMouse
		STATES.onMouse:
			set_global_position(get_global_mouse_position() - rect_size/2)
			if Input.is_action_just_pressed("left_click"):
				if Global.play_scene.mouse_over_card_placement and Global.play_scene.try_to_put_card(card_number, card_color):
					Global.play_scene.play_card(self, true)
				else :
					mouse = false
					rect_position = last_position
					state = STATES.onPlayerHand

func set_position_in_scene(position : Vector2) -> void:
	rect_position = position

func _on_Focus_mouse_entered() -> void:
	if state == STATES.onPlayerHand :
		mouse = true

func _on_Focus_mouse_exited() -> void:
	if state == STATES.onPlayerHand :
		mouse = false
