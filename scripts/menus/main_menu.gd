extends MainMenu

func _on_competitive_button_pressed() -> void:
	TransitionManager.change_scene("res://scenes/game_scenes/competitive_game_list.tscn", 1)


func _on_refactor_button_pressed() -> void:
	TransitionManager.change_scene("res://scenes/game_scenes/daily_game_refactor.tscn", 1)
