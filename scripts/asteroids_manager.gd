extends Node2D

const asteroid_prefab:PackedScene = preload("res://scenes/asteroid.tscn")

func _ready() -> void:
	for i in range(0,5):
		var new_asteroid = asteroid_prefab.instantiate()
		new_asteroid.position = Vector2(Globals.RNG.randi_range(0,Globals.SCREEN_SIZE.x), Globals.RNG.randi_range(0,Globals.SCREEN_SIZE.y))
		get_tree().root.add_child(new_asteroid)
