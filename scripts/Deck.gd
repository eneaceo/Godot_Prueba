extends Node2D

const CardBase = preload("res://scenes/Card.tscn")

signal empty_deck

const _colors: Array = ["Red", "Blue", "Green", "Yellow"]
const _special: Array = ["skip"]
const _min_number : int = 0
const _max_number : int = 9

var _deck : Array = []

func _init() -> void:
	for color in _colors:
		for number in range(_min_number, _max_number + 1):
			print ("Deck card " + String(number) + " " + color)
			var new_card = CardBase.instance()
			new_card._init_Card(number, color)
			new_card.state = new_card.STATES.onDeck
			_deck.append(new_card)
	_deck.shuffle()

func draw_Card():
	if _deck.size() > 0 :
		if _deck.size() == 1 :
			emit_signal("empty_deck")
		return _deck.pop_back()

func deck_Size() -> int :
	return _deck.size()

