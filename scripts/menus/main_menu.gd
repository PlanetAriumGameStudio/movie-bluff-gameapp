extends MainMenu

func _on_competitive_button_pressed() -> void:
	TransitionManager.change_scene("res://scenes/game_scenes/competitive_game_list.tscn", 1)
