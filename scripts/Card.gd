extends Control

# VARIABLES ###########################################################

var card_size : Vector2 = Vector2.ZERO

var color: String = ""
var number: int = 0
var special : String = ""

enum STATES {
	onDeck,
	onMovingToHand,
	onMovingToAI,
	onMovingToCenter,
	onPlayerHand,
	onAIHand,
	onMouse,
	onPlayed
	}

var state = STATES.onDeck

var start_position : Vector2 = Vector2.ZERO
var target_position : Vector2 = Vector2.ZERO
var time : float = 0

var mouse_over_card : bool = false
var last_position_when_picked: Vector2 = Vector2.ZERO
var scale : Vector2 = Vector2.ONE

# INITIALIZATION ###########################################################

func init_card(card_number: int, card_color: String) -> void:
	color = card_color
	number = card_number
	_init_card_textures()

func init_special_card(card_color: String, card_special: String) -> void:
	color = card_color
	number = -1
	special = card_special
	_init_card_textures()

func _init_card_textures() -> void :
	card_size = Global.card_size
	rect_size = card_size
	$Background.rect_size = card_size
	$Background/Border.rect_size = card_size
	$Number.rect_size = card_size/10
	$Number.rect_position = Vector2($Number.rect_size.x, $Number.rect_size.y)
	$NumberUp.rect_size = card_size/20
	$NumberUp.rect_position = Vector2(card_size.x/6 - $Number.rect_size.x, card_size.y/6 - $Number.rect_size.y)
	$CardBack.scale = card_size/$CardBack.texture.get_size()
	$CardBack.position = Vector2(card_size.x/2, card_size.y/2)
	
	match (color):
		"Red":
			$Background.color = Color(1, 0, 0, 1)
		"Green":
			$Background.color = Color(0, 1, 0, 1)
		"Blue":
			$Background.color = Color(0, 0, 1, 1)
		"Yellow":
			$Background.color = Color(1, 1, 0, 1)
	if number != -1 :
		$Number.set_text(String(number))
		$NumberUp.set_text(String(number))
	else :
		$Number.set_text(special)
		$NumberUp.set_text(special)

#When a card is added to scene we want to always appear visible at the deck position
func _ready() -> void:
	rect_position = Global.deck_position

###########################################################

func _physics_process(delta: float) -> void:
	match state:
		STATES.onDeck:
			pass
		STATES.onPlayed:
			pass
		STATES.onMovingToHand:
			if _move_card_to(delta) :
				$CardBack.visible = false
				time = 0
				state = STATES.onPlayerHand
				Global.play_scene.update_cards_in_hand_position (true)
		STATES.onMovingToAI:
			if _move_card_to(delta) :
				time = 0
				state = STATES.onAIHand
				Global.play_scene.update_cards_in_hand_position (false)
		STATES.onMovingToCenter:
			if _move_card_to(delta) :
				$CardBack.visible = false
				time = 0
				state = STATES.onPlayed
		STATES.onPlayerHand:
			if mouse_over_card:
				$Background/Border.border_color = Color(1,0.5,0,1)
				if rect_scale != scale * 1.25 :
					rect_scale = lerp(rect_scale, scale * 1.25, delta * 4)
			else:
				$Background/Border.border_color = Color(1,1,1,1)
				if rect_scale != scale :
					rect_scale = lerp(rect_scale, scale, delta * 8)
			if Input.is_action_just_pressed("left_click") and mouse_over_card and Global.play_scene.player_turn and !Global.play_scene.game_finished :
				last_position_when_picked = rect_position
				rect_scale = scale
				$Background/Border.border_color = Color(1,1,1,1)
				state = STATES.onMouse
		STATES.onMouse:
			set_global_position(get_global_mouse_position() - rect_size/2)
			if Input.is_action_just_pressed("left_click"):
				if Global.play_scene.mouse_over_card_placement and Global.play_scene.try_to_put_card(number, color):
					Global.play_scene.play_card(self, true)
				else :
					mouse_over_card = false
					rect_position = last_position_when_picked
					state = STATES.onPlayerHand


# Reset card to onDeck state and back visible
func reset_card() -> void :
	$CardBack.visible = true
	mouse_over_card = false
	rect_position = Global.deck_position
	state = STATES.onDeck


func _move_card_to(delta : float) -> bool :
	time = time + delta
	rect_position = lerp(start_position, target_position, time * 2)
	return rect_position == target_position


func set_position_in_scene(position : Vector2) -> void:
	rect_position = position

# SIGNALS ###########################################################

func _on_Focus_mouse_entered() -> void:
	if state == STATES.onPlayerHand :
		mouse_over_card = true


func _on_Focus_mouse_exited() -> void:
	if state == STATES.onPlayerHand :
		mouse_over_card = false
