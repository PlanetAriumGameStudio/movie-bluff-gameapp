class_name AsteroidsManager
extends Node2D

const asteroid_prefab:PackedScene = preload("res://scenes/asteroid.tscn")

@onready var asteroid_spawn_path:PathFollow2D = $AsteroidSpawnPath/PathFollow2D

func _ready() -> void:
	init_asteroids()

func init_asteroids():
	for i in range(0,5):
		generate_asteroid()

func generate_asteroid():
	asteroid_spawn_path.set_progress_ratio(Globals.RNG.randf())
	generate_asteroid_at_position(asteroid_spawn_path.position, 3)

func generate_asteroid_at_position(spawn_position : Vector2, size : int):
	var new_asteroid = asteroid_prefab.instantiate()
	new_asteroid.position = spawn_position
	new_asteroid.size = size
	new_asteroid.connect("asteroid_shot", _on_asteroid_shot)
	self.add_child(new_asteroid)
	
func _on_asteroid_shot(new_position : Vector2, new_size : int): 
	for i in randi_range(0, Globals.RNG.randi_range(1,2)):
		print(i)
		generate_asteroid_at_position(new_position, new_size)
