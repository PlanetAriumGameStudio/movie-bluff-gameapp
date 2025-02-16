extends CharacterBody2D
class_name Player

signal player_exploded

var ship: PackedVector2Array
var booster: PackedVector2Array
var coords_ship: Array = [[-8, 10], [-8, -10],[15, 0]]
var coords_booster: Array = [[-8, 5], [-8, -5],[-13, 0]]

@export var bullet_prefab: PackedScene

const MAX_SPEED = 150.0
const THRUST = 300.0
const ROTATION_SPEED = 5.0
const BULLET_SPEED = 250.0

var rotation_direction = 0
var acceleration = 0
var shoot = false

func _ready():
	velocity = Vector2(0,0)
	ship = float_array_to_Vector2Array(coords_ship)
	booster = float_array_to_Vector2Array(coords_booster)
	
func float_array_to_Vector2Array(coords : Array) -> PackedVector2Array:
	# Convert the array of floats into a PackedVector2Array.
	var array : PackedVector2Array = []
	for coord in coords:
		array.append(Vector2(coord[0], coord[1]))
	return array

func _process(delta: float) -> void:
	if shoot:
		var new_bullet = bullet_prefab.instantiate()
		new_bullet.global_position = position
		new_bullet.rotation = rotation
		var direction = Vector2.RIGHT.rotated(rotation)
		get_tree().root.add_child(new_bullet)
		shoot = false
		

func _physics_process(delta: float) -> void:
	# Get the input direction and handle the acceleration and rotation changes.
	get_input()
	rotation += rotation_direction * ROTATION_SPEED * delta
	velocity += transform.x * acceleration * delta
	velocity = velocity.limit_length(MAX_SPEED)	
	
	queue_redraw()
	move_and_slide()
	screen_wrap()

	
func _draw():
	var godot_blue: Color = Color("478cbf")
	if acceleration > 0:
		var booster_red: Color = Color("ff8cbf")
		draw_polygon(booster, [booster_red])
	draw_polygon(ship, [godot_blue])
	
	
func screen_wrap():
	position.x = wrapf(position.x, 0, Globals.SCREEN_SIZE.x)
	position.y = wrapf(position.y, 0, Globals.SCREEN_SIZE.y)
	
func get_input():
	rotation_direction = Input.get_axis("left", "right")
	acceleration = Input.get_axis("down", "up") * THRUST
	shoot = Input.is_action_just_pressed("ui_accept")

func blow_up():
	player_exploded.emit()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("asteroids"):
		blow_up()
