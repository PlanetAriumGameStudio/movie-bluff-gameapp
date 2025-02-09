extends Node
# This class is running via project auto-load (At startup)
# Inspired by ThinkWithGames(https://www.youtube.com/@ThinkWithGames)
const transition_node_name = "transition_node"
var is_showing_transition = false

var function_to_call: Callable

enum TransitionType {
	ZoomOut = 1,
	SwipeRight = 2,
	FallDown = 3,
	Fade = 4
}

# Used to generate a still image of whatever is currently being displayed on the screen/viewport
func setup_sprite():
	# Create the scene that will hold our transition sprite 
	var transition_sprite = load("res://scenes/transition_sprite.tscn").instantiate() as Sprite2D
	var image = get_viewport().get_texture().get_image()
	var transition_texture = ImageTexture.create_from_image(image)
	transition_sprite.name = transition_node_name
	transition_sprite.texture = transition_texture
	transition_sprite.position = Vector2(get_viewport().get_visible_rect().size.x/2, get_viewport().get_visible_rect().size.y/2)
	return transition_sprite

# new_scene_location: Will be the path to the scene we want to load
# transition_type: for picking between transition effects
func change_scene(new_scene_location: String, transition_type: int):
	if is_showing_transition: 
		return
	is_showing_transition = true
	var transition_sprite = setup_sprite()
	get_tree().change_scene_to_file(new_scene_location)
	function_to_call = show_transition.bind(transition_sprite, transition_type)
	get_tree().node_added.connect(function_to_call)
	
func show_transition(_new_node, transition_sprite: Sprite2D, type: int):
	if get_tree().root.get_node_or_null(transition_node_name) != null:
		return
	get_tree().root.add_child(transition_sprite)
	var transition_tween = create_tween().set_parallel()
	if type == TransitionType.ZoomOut:
		transition_tween.set_trans(Tween.TRANS_CUBIC)
		transition_tween.tween_property(transition_sprite, "scale", Vector2(0.01, 0.01), 1)
	elif type == TransitionType.SwipeRight:
		transition_tween.tween_property(transition_sprite, "global_position", Vector2(1800,360), 1)
		transition_tween.tween_property(transition_sprite, "rotation", deg_to_rad(180), 1)
	elif type == TransitionType.FallDown:
		transition_tween.set_trans(Tween.TRANS_EXPO)
		transition_tween.tween_property(transition_sprite, "global_position", Vector2(get_viewport().get_visible_rect().size.x/2,1200), 1)
		
	transition_tween.finished.connect(transition_sprite.queue_free)
	await transition_tween.finished
	get_tree().node_added.disconnect(function_to_call)
	is_showing_transition = false	
