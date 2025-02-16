extends Area2D

@export var SPEED: float = 200.0

func _process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(rotation) * SPEED * delta
	check_clean_up()
	pass

func check_clean_up():
	if position.x > Globals.SCREEN_SIZE.x || position.x < 0 || position.y > Globals.SCREEN_SIZE.y || position.y < 0:
		queue_free() 
