class_name PauseMenu
extends PanelContainer

func _process(delta:float) -> void:
	if Input.is_action_just_pressed("pause"):
		_toggle_visibility()

func _toggle_visibility():
	visible = not visible
	get_tree().paused = not get_tree().paused

func _navigate_to_main_menu():
	_toggle_visibility()
	TransitionManager.change_scene("res://scenes/main_menu.tscn", 1)
