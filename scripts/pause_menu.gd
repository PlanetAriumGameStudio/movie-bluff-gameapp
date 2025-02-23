extends PanelContainer

func _process(delta:float) -> void:
	if Input.is_action_just_pressed("pause"):
		_toggle_visibility()

func _toggle_visibility():
	visible = not visible
	get_tree().paused = not get_tree().paused

func _navigate_to_main_menu():
	_toggle_visibility()
	TransitionManager.change_scene("res://scenes/menus/main_menu/main_menu.tscn", 1)

func _on_options_button_pressed() -> void:
	var options_panel = load("res://scenes/options_panel.tscn").instantiate()
	add_child(options_panel)
