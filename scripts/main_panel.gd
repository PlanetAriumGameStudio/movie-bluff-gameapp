extends PanelContainer

const DODGEBALL_WORLD_SCENE = "res://scenes/asteroids_world.tscn"
const CREDITS_SCENE = "res://scenes/credits_panel.tscn"
const OPTIONS_SCENE = "res://scenes/options.tscn"

func _on_start_game_button_down() -> void:
	TransitionManager.change_scene(DODGEBALL_WORLD_SCENE, TransitionManager.TransitionType.ZoomOut)

func _on_options_button_down() -> void:
	print("Options Pressed")
	var options_panel = load(OPTIONS_SCENE).instantiate()
	get_tree().root.add_child(options_panel)
	#TransitionManager.change_scene(CREDITS_PANEL, TransitionManager.TransitionType.ZoomOut)


func _on_credits_button_down() -> void:
	print("Credits Pressed")
	var credits_panel = load(CREDITS_SCENE).instantiate()
	self.get_parent().add_child(credits_panel)
	credits_panel.position = Vector2(0,self.global_position.y+1720)
	
	var transition_tween = create_tween().set_parallel()
	transition_tween.set_trans(Tween.TRANS_EXPO)
	#transition_tween.tween_property(self, "global_position", Vector2(get_viewport().get_visible_rect().size.x/2,1200), 1)
	transition_tween.tween_property(credits_panel, "global_position", Vector2(0,0), 1)
	
	
