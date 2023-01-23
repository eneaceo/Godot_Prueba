extends Node2D

# VARIABLES ##########################################################

var initial_number_of_cards : int = 7

var card_size : Vector2 = Vector2.ZERO
var center_cards_position : Vector2 = Vector2.ZERO

var uno_button_default_scale : Vector2 = Vector2(0.1, 0.1)
var player_uno: bool = false
var ai_uno : bool = false

var player_turn : bool = true
var game_finished : bool = false

var finish_timer : Timer = Timer.new()

const uno_time_to_press : float = 5.0
const ai_timer : float = 0.5 #Delay AI actions to better game feel

var player_draw_cards: int = 0
var ai_draw_cards: int = 0

var mouse_over_card_placement: bool = false

var played_cards = []
var last_card_played

# INITIALIZATION ##########################################################

func _ready() -> void:
	
	Global.play_scene = self
	Global.deck_position = $DeckPlacement/DeckPlacementButton.rect_position
	center_cards_position = Vector2($CardPlacement/CardPlacementButton.rect_position.x + $CardPlacement/CardPlacementButton.rect_size.x/4, $CardPlacement/CardPlacementButton.rect_position.y + $CardPlacement/CardPlacementButton.rect_size.y/4)
	
	$UnoTimer.connect("timeout",self,"ai_uno_pressed")
	$AITimer.connect("timeout",self,"ai_start_turn")
	$AuxAITimer.connect("timeout",self,"ai_turn")
	
	# Initializate scene graphics
	card_size = Global.card_size
	$Background.scale = get_viewport().size/$Background.texture.get_size()
	$Background.position = Vector2(get_viewport().size.x/2, get_viewport().size.y/2)
	$Background/PlayerHandPosition.position = Vector2(get_viewport().size.x/2 - card_size.x/2, get_viewport().size.y - card_size.y * 0.75)
	$Background/AIHandPosition.position = Vector2(get_viewport().size.x/2 - card_size.x/2, -card_size.y * 0.25)
	$UNO.rect_scale = uno_button_default_scale
	$UNO.disabled = true
	$PlayedCards.z_index = 1
	# Start game - Draw first card
	Deck.init()
	
	var card_draw = Deck.draw_card()
	card_draw.start_position = $DeckPlacement/DeckPlacementButton.rect_position
	card_draw.target_position = Vector2($CardPlacement/CardPlacementButton.rect_position.x + $CardPlacement/CardPlacementButton.rect_size.x/4, $CardPlacement/CardPlacementButton.rect_position.y + $CardPlacement/CardPlacementButton.rect_size.y/4)
	card_draw.state = card_draw.STATES.onMovingToCenter
	last_card_played = card_draw
	$PlayedCards.add_child(card_draw)
	print ("First Card PLayed: " + String(card_draw.number) + " " + card_draw.color)
	
	# Limit the number of initial cards
	if initial_number_of_cards > 10:
		initial_number_of_cards = 10
	
	draw_card(initial_number_of_cards, true)
	draw_card(initial_number_of_cards, false)
	
	print("Finished Initialization - Play Scene")

# GAME LOGIC ##########################################################

func draw_card(num : int, player : bool) -> void :
	print ("Draw: " + String(num) + " " + String(player))
	if Deck.deck_size() < num :
		refill_deck()
	var card_draw
	if player :
		if player_uno:
			player_uno = false
			stop_uno_timer()
		for i in num:
			player_draw_cards += 1
			card_draw = Deck.draw_card()
			$PlayerCards.add_child(card_draw)
			card_draw.start_position = $DeckPlacement/DeckPlacementButton.rect_position
			card_draw.target_position = $Background/PlayerHandPosition.position
			card_draw.state = card_draw.STATES.onMovingToHand
			print ("Card Draw: " + String(card_draw.number) + " " + card_draw.color)
	else :
		if ai_uno:	
			ai_uno = false
			stop_uno_timer()
		for i in num:
			ai_draw_cards += 1
			card_draw = Deck.draw_card()
			$AICards.add_child(card_draw)
			card_draw.start_position = $DeckPlacement/DeckPlacementButton.rect_position
			card_draw.target_position = $Background/AIHandPosition.position
			card_draw.state = card_draw.STATES.onMovingToAI
			print ("Card Draw: " + String(card_draw.number) + " " + card_draw.color)


func try_to_put_card(number : int, color: String) -> bool:
	return last_card_played.color == color or last_card_played.number == number


func play_card(card, player: bool) -> void:
	played_cards.append(card)
	last_card_played = card
	print("Played Card : " + String(card.number) + " " + card.color)
	if player : 
		player_draw_cards -= 1
		$PlayerCards.remove_child(card)
		card.state = card.STATES.onPlayed
	else :
		ai_draw_cards -= 1
		card.start_position = card.rect_position
		card.target_position = center_cards_position 
		$AICards.remove_child(card)
		card.state = card.STATES.onMovingToCenter
	$PlayedCards.add_child(card)
	
	check_if_game_finished()
	check_if_uno()
	var check : String = check_if_special_card_played()
	
	match(check):
		"Skip":
			if !player_turn and !game_finished:
				if $UnoTimer.is_stopped():
					ai_turn()
				else :
					$AuxAITimer.start()
		_:
			player_turn = !player_turn
			if !player_turn and !game_finished:
				if $UnoTimer.is_stopped():
					ai_turn()
				else :
					$AuxAITimer.start()
		


func refill_deck():
	print ("Refill Deck")
	for card in $PlayedCards.get_children():
		if card != last_card_played:
			$PlayedCards.remove_child(card)
			Deck.add_card_to_deck(card)
			card.reset_card()
	played_cards.clear()
	played_cards.append(last_card_played)
	Deck.shuffle_deck()
	print("Deck size after refill: " + String(Deck.deck_size()))


func check_if_game_finished() -> void :
	if $PlayerCards.get_child_count() == 0 or $AICards.get_child_count() == 0:
		finish_game()


func check_if_uno() -> void :
	if $PlayerCards.get_child_count() == 1  and player_turn or $AICards.get_child_count() == 1 and !player_turn:
		$UNO.disabled = false
		$UnoAnimation.play("UNO")
		$UnoTimer.start()
		if player_turn:
			player_uno = true
			ai_uno = false
		else:
			player_uno = false
			ai_uno = true
		
func check_if_special_card_played() -> String :
	if last_card_played.number == -1 :
		print("Special Card Played: " + last_card_played.special)
		return last_card_played.special
	return ""
	
	
func check_if_can_play_card() -> bool :
	var played_card : bool = false
	for card in $PlayerCards.get_children():
		if try_to_put_card(card.number, card.color):
			played_card = true
			break
	return played_card
	
func stop_uno_timer() -> void :
		$UnoAnimation.stop(true)
		$UNO.rect_scale = uno_button_default_scale
		$UnoTimer.stop()
		$UNO.disabled = true

# AI LOGIC #########################################################
	
func ai_turn() -> void :
	$AuxAITimer.stop()
	$AITimer.start()
	
func ai_start_turn() -> void :
	$AITimer.stop()
	var played_card : bool = false
	for card in $AICards.get_children():
		if try_to_put_card(card.number, card.color):
			play_card(card, false)
			played_card = true
			break
	if !played_card:
		if !$UnoTimer.is_stopped() and $AICards.get_child_count() == 1:
			stop_uno_timer()
		draw_card(1, false)
		player_turn = !player_turn

# FINISH GAME ##########################################################

func finish_game() -> void:
	game_finished = true
	$PlayedCards.z_index = 0
	if $PlayerCards.get_child_count() == 0:
		$Win/WinText.set_text("YOU WIN")
	else :
		$Win/WinText.set_text("YOU LOSE")
	$Win.popup()
	print("GAME FINISHED")
	if !$UnoTimer.is_stopped():
		stop_uno_timer()
	finish_timer.connect("timeout",self,"go_to_menu")
	finish_timer.wait_time = 5
	finish_timer.one_shot = true
	add_child(finish_timer)
	finish_timer.start()
	
	
func go_to_menu() -> void:
	get_tree().change_scene("res://scenes/Menu.tscn")

# GRAPHIC FUNCTIONS ##########################################################

func update_cards_in_hand_position (player : bool) -> void :
	
	var center_x : float = 0.0
	var first_position_x : float = 0.0
	var y_position : float = 0.0 
	var total_cards_in_hand : int = 0
	var cards_in_hand
	
	if player :
		total_cards_in_hand = $PlayerCards.get_child_count()
		cards_in_hand = $PlayerCards.get_children()
		center_x = $Background/PlayerHandPosition.position.x
		first_position_x = center_x - total_cards_in_hand * card_size.x/total_cards_in_hand * 5
		y_position = $Background/PlayerHandPosition.position.y
	else :
		total_cards_in_hand = $AICards.get_child_count()
		cards_in_hand = $AICards.get_children()
		center_x = $Background/AIHandPosition.position.x
		first_position_x = center_x - total_cards_in_hand * card_size.x/total_cards_in_hand * 5
		y_position = $Background/AIHandPosition.position.y
	
	var num_card : int = 0
	var x_position : float = 0.0
	for card in cards_in_hand :
		x_position = first_position_x + num_card * card_size.x/total_cards_in_hand * 10
		card.set_position_in_scene(Vector2(x_position, y_position))
		num_card += 1

# SIGNALS ##########################################################

func _on_DeckPlacementButton_pressed() -> void:
	if player_turn and !game_finished and !check_if_can_play_card():
		if !$UnoTimer.is_stopped() and $PlayerCards.get_child_count() == 1:
			stop_uno_timer()
		print("Deck size: " + String(Deck.deck_size()))
		draw_card(1, true)
		player_turn = !player_turn
		ai_turn()


func _on_CardPlacementButton_mouse_entered() -> void:
	mouse_over_card_placement = true


func _on_CardPlacementButton_mouse_exited() -> void:
	mouse_over_card_placement = false


func _on_UNO_pressed() -> void:
	print("UNO -> Player Pressed")
	stop_uno_timer()
	if $AICards.get_child_count() == 1 and ai_uno:
		draw_card(2, false)

# TIMERS ##########################################################

func ai_uno_pressed() -> void:
	print("UNO -> AI Pressed")
	stop_uno_timer()
	if $PlayerCards.get_child_count() == 1 and player_uno:
		draw_card(2, true)
