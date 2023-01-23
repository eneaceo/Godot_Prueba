extends Node2D

var initial_number_of_cards : int = 15
var player_turn : bool = true
var ai_timer = Timer.new() #AI plays so fast the cards it messes with the Z-Index and tree behavior
var uno_timer = Timer.new()

var card_size : Vector2 = Vector2(100,150)
var player_draw_cards: int = 0
var ai_draw_cards: int = 0
var mouse_over_card_placement: bool = false
var played_cards = []
var last_card_played

func _ready() -> void:
	
	#initializate scene
	Global.play_scene = self
	$Background.scale = get_viewport().size/$Background.texture.get_size()
	$Background.position = Vector2(get_viewport().size.x/2, get_viewport().size.y/2)
	$Background/PlayerHandPosition.position = Vector2(get_viewport().size.x/2 - card_size.x/2, get_viewport().size.y - card_size.y * 0.75)
	$Background/AIHandPosition.position = Vector2(get_viewport().size.x/2 - card_size.x/2, -card_size.y * 0.25)
	card_size = Card.card_size
	
	$UNO.disabled = true
	
	Deck._init()
	
	var card_draw = Deck.draw_Card()
	card_draw.start_position = $DeckPlacement/DeckPlacementButton.rect_position
	card_draw.target_position = Vector2($CardPlacement/CardPlacementButton.rect_position.x + $CardPlacement/CardPlacementButton.rect_size.x/4, $CardPlacement/CardPlacementButton.rect_position.y + $CardPlacement/CardPlacementButton.rect_size.y/4)
	card_draw.state = card_draw.STATES.onMovingToCenter
	last_card_played = card_draw
	$PlayedCards.add_child(card_draw)
	
	if initial_number_of_cards > 10:
		initial_number_of_cards = 10
	
	for i in range (initial_number_of_cards):
		player_draw_cards += 1
		card_draw = Deck.draw_Card()
		$PlayerCards.add_child(card_draw)
		card_draw.start_position = $DeckPlacement/DeckPlacementButton.rect_position
		card_draw.target_position = $Background/PlayerHandPosition.position
		card_draw.state = card_draw.STATES.onMovingToHand
		
	for i in range (initial_number_of_cards):
		ai_draw_cards += 1
		card_draw = Deck.draw_Card()
		$AICards.add_child(card_draw)
		card_draw.start_position = $DeckPlacement/DeckPlacementButton.rect_position
		card_draw.target_position = $Background/AIHandPosition.position
		card_draw.state = card_draw.STATES.onMovingToAI
	
	print("Finished initialization")

func update_player_cards_position() -> void :
	var center_x = $Background/PlayerHandPosition.position.x
	var first_position_x = center_x - $PlayerCards.get_child_count() * card_size.x/$PlayerCards.get_child_count() * 5
	var y = $Background/PlayerHandPosition.position.y
	var num_card = 0
	for card in $PlayerCards.get_children() :
		var x = first_position_x + num_card * card_size.x/$PlayerCards.get_child_count() * 10
		card.set_position_in_scene(Vector2(x, y))
		num_card += 1

func update_ai_cards_position() -> void :
	var center_x = $Background/AIHandPosition.position.x
	var first_position_x = center_x - $AICards.get_child_count() * card_size.x/$AICards.get_child_count() * 5
	var y = $Background/AIHandPosition.position.y
	var num_card = 0
	for card in $AICards.get_children() :
		var x = first_position_x + num_card * card_size.x/$AICards.get_child_count() * 10
		card.set_position_in_scene(Vector2(x, y))
		num_card += 1

func try_to_put_card(number : int, color: String) -> bool:
	return last_card_played.card_color == color or last_card_played.card_number == number

func play_card(card, player: bool) -> void:
	played_cards.append(card)
	last_card_played = card
	if player : 
		player_draw_cards -= 1
		$PlayerCards.remove_child(card)
		card.state = card.STATES.onPlayed
		if $PlayerCards.get_child_count() == 1:
			$UNO.disabled = false
			uno_timer.connect("timeout",self,"ai_uno_pressed")
			uno_timer.wait_time = 5
			uno_timer.one_shot = true
			add_child(uno_timer)
			uno_timer.start()
		if $PlayerCards.get_child_count() == 0:
			get_tree().change_scene("res://scenes/Menu.tscn")
		else:
			ai_turn()
	else :
		ai_draw_cards -= 1
		card.start_position = card.rect_position
		card.target_position = Vector2($CardPlacement/CardPlacementButton.rect_position.x + $CardPlacement/CardPlacementButton.rect_size.x/4, $CardPlacement/CardPlacementButton.rect_position.y + $CardPlacement/CardPlacementButton.rect_size.y/4)
		$AICards.remove_child(card)
		if $AICards.get_child_count() == 1:
			$UNO.disabled = false
			uno_timer.connect("timeout",self,"ai_uno_pressed")
			uno_timer.wait_time = 5
			uno_timer.one_shot = true
			add_child(uno_timer)
			uno_timer.start()
		if $PlayerCards.get_child_count() == 0:
			get_tree().change_scene("res://scenes/Menu.tscn")
		card.state = card.STATES.onMovingToCenter
	$PlayedCards.add_child(card)
	player_turn = !player_turn
	
func ai_turn() -> void :
	print("AI Turn")
	ai_timer.connect("timeout",self,"ai_turn_start")
	ai_timer.wait_time = 1
	ai_timer.one_shot = true
	add_child(ai_timer)
	ai_timer.start()
	
func ai_turn_start() -> void :
	ai_timer.stop()
	var played_card : bool = false
	for card in $AICards.get_children():
		if try_to_put_card(card.card_number, card.card_color):
			play_card(card, false)
			played_card = true
			break
	if !played_card:
		if Deck.deck_Size() > 0 :
			ai_draw_cards += 1
			var card_draw = Deck.draw_Card()
			$AICards.add_child(card_draw)
			card_draw.start_position = $DeckPlacement/DeckPlacementButton.rect_position
			card_draw.target_position = $Background/AIHandPosition.position
			card_draw.state = card_draw.STATES.onMovingToAI
		else:
			on_empty_deck()
		player_turn = !player_turn

func on_empty_deck():
	print ("Empty Deck")
	for card in $PlayedCards.get_children():
		if card != last_card_played:
			$PlayedCards.remove_child(card)
			Deck.add_card_to_deck(card)
			card.reset_card()
	played_cards.clear()
	played_cards.append(last_card_played)
	print("Deck size after refill: " + String(Deck.deck_Size()))

func _on_DeckPlacementButton_pressed() -> void:
	if player_turn:
		print("Deck size: " + String(Deck.deck_Size()))
		if Deck.deck_Size() > 0 :
			if $DeckPlacement/AnimationPlayer.is_playing():
				$DeckPlacement/AnimationPlayer.stop()
			player_draw_cards += 1
			var card_draw = Deck.draw_Card()
			if Deck.deck_Size() == 0:
				$DeckPlacement/AnimationPlayer.play("DeckEmpty")
				on_empty_deck()
			$PlayerCards.add_child(card_draw)
			card_draw.start_position = $DeckPlacement/DeckPlacementButton.rect_position
			card_draw.target_position = $Background/PlayerHandPosition.position
			card_draw.state = card_draw.STATES.onMovingToHand
			player_turn = !player_turn
			ai_turn()
		else:
			on_empty_deck()

func _on_CardPlacementButton_mouse_entered() -> void:
	mouse_over_card_placement = true

func _on_CardPlacementButton_mouse_exited() -> void:
	mouse_over_card_placement = false

func ai_uno_pressed() -> void:
	print("UNO")
	$UNO.disabled = true

func _on_UNO_pressed() -> void:
	print("UNO")
	$UNO.disabled = true
