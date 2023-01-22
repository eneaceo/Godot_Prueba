extends Node2D

var card_size : Vector2 = Vector2(100,150)
var player_draw_cards: int = 0
var mouse_over_card_placement: bool = false
var played_cards = []

func _ready() -> void:
	
	#initializate scene
	Global.play_scene = self
	$Background.scale = get_viewport().size/$Background.texture.get_size()
	$Background.position = Vector2(get_viewport().size.x/2, get_viewport().size.y/2)
	$Background/PlayerHandPosition.position = Vector2(get_viewport().size.x/2 - card_size.x/2, get_viewport().size.y - card_size.y * 0.75)
	card_size = Card.card_size
	
	Deck._init()
	Deck.connect("empty_deck", self, "on_empty_deck")
	
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
	

func try_to_put_card(number : int, color: String) -> bool:
	if(played_cards.size() > 0):
		var last_played_card = played_cards[-1]
		#print("My card " + String(number) + " " + color)
		#print("Lastcard " + String(last_played_card.card_number) + " " + last_played_card.card_color)
		#print(last_played_card.card_color == color or last_played_card.card_number == number)
		return last_played_card.card_color == color or last_played_card.card_number == number
	else:
		return true
	
func play_card(card, player: bool) -> void:
	played_cards.append(card)
	if player : 
		$PlayerCards.remove_child(card)
	$PlayedCards.add_child(card)
	card.state = card.STATES.onPlayed

func on_empty_deck():
	print ("Empty Deck")

func _on_DeckPlacementButton_pressed() -> void:
	if Deck.deck_Size() > 0 :
		player_draw_cards += 1
		var card_draw = Deck.draw_Card()
		$PlayerCards.add_child(card_draw)
		card_draw.start_position = $DeckPlacement/DeckPlacementButton.rect_position
		card_draw.target_position = $Background/PlayerHandPosition.position
		card_draw.state = card_draw.STATES.onMovingToHand

func _on_CardPlacementButton_mouse_entered() -> void:
	mouse_over_card_placement = true
	print(mouse_over_card_placement)

func _on_CardPlacementButton_mouse_exited() -> void:
	mouse_over_card_placement = false
	print(mouse_over_card_placement)
