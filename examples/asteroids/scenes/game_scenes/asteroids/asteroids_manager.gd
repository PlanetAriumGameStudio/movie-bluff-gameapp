class_name AsteroidsManager
extends Node2D

signal player_scored
signal level_cleared

const asteroid_prefab:PackedScene = preload("uid://bp8i034tdnk40")

@export var init_asteroid_count := 6
@export var init_asteroid_size := 4

var _asteroid_count : int

@onready var asteroid_spawn_path:PathFollow2D = $AsteroidSpawnPath/PathFollow2D

func _ready() -> void:
	init_asteroids()
	
func init_asteroids():
	var children = get_children()
	for index in children.size():
		if children[index].is_in_group("asteroids"):
			children[index].queue_free()
	
	_asteroid_count = 0
	for i in range(0, init_asteroid_count):
		generate_asteroid()

func generate_asteroid():
	asteroid_spawn_path.set_progress_ratio(Globals.RNG.randf())
	generate_asteroid_at_position(asteroid_spawn_path.position, init_asteroid_size)

func generate_asteroid_at_position(spawn_position : Vector2, size : int):
	_asteroid_count += 1
	var new_asteroid = asteroid_prefab.instantiate()
	new_asteroid.position = spawn_position
	new_asteroid.size = size
	new_asteroid.connect("asteroid_shot", _on_asteroid_shot)
	add_child(new_asteroid)
	
func _on_asteroid_shot(new_position : Vector2, new_size : int): 
	_asteroid_count -= 1
	player_scored.emit()
	if new_size > 1:
		for i in randi_range(2, Globals.RNG.randi_range(2,3)):
			generate_asteroid_at_position(new_position, new_size)
	if _asteroid_count == 0:
		level_cleared.emit()
