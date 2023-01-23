extends Node2D

const card_base = preload("res://scenes/Card.tscn")

const _colors: Array = ["Red", "Blue", "Green", "Yellow"]
const _special: Array = ["Skip"]
const _min_number : int = 0
const _max_number : int = 9

var _deck : Array = []

func init() -> void:
	_deck.clear()
	for color in _colors:
		for number in range(_min_number, _max_number + 1):
			print ("Deck Card:  " + String(number) + " " + color)
			var new_card = card_base.instance()
			new_card.init_card(number, color)
			new_card.state = new_card.STATES.onDeck
			_deck.append(new_card)
	for color in _colors:
		for special in _special:
			print ("Deck Card:  " + special + " " + color)
			var new_card = card_base.instance()
			new_card.init_special_card(color, special)
			new_card.state = new_card.STATES.onDeck
			_deck.append(new_card)
	randomize()
	_deck.shuffle()


func draw_card():
	if _deck.size() > 0 :
		return _deck.pop_back()


func deck_size() -> int :
	return _deck.size()


func add_card_to_deck(card) -> void :
	_deck.append(card)

func shuffle_deck() -> void :
	randomize()
	_deck.shuffle()
