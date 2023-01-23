extends Control

func _on_Start_pressed() -> void:
	get_tree().change_scene("res://scenes/PlaySpace.tscn")

func _on_Quit_pressed() -> void:
	get_tree().quit()
