class_name Player
extends CharacterBody2D

# To let things know when we explode
signal player_exploded

const MAX_SPEED = 150.0
const THRUST = 300.0
const ROTATION_SPEED = 5.0
const BULLET_SPEED = 250.0

# Load in bullet prefab for easy shooting of anything 
@export var bullet_prefab: PackedScene

#Runtime state private variables
var _pstate = PlayerState.new()

# Basic vertex coordinate representations, will be converted to Vector2Arrays
var _coords_ship: Array = [[-8, 10], [-8, -10],[15, 0]]
var _drawable_ship: PackedVector2Array
var _coords_booster: Array = [[-8, 5], [-8, -5],[-13, 0]]
var _drawable_booster: PackedVector2Array
var _coords_reverse_booster: Array = [[-8, 10], [12, 7],[-8, 0], [12,-7], [-8,-10]]
var _drawable_reverse_booster: PackedVector2Array

# Ship sound streams
var _thruster_asp : AudioStreamPlayer2D
var _thruster_stream: AudioStream = preload("res://audio/sound_effects/rocketthrustmaxx-100019.mp3")
var _laser_asp : AudioStreamPlayer2D
var _laser_stream: AudioStream = preload("res://audio/sound_effects/retro-laser.mp3")

func _ready():
	velocity = Vector2(0,0)
	
	# Convert coords into Vector2Array's to be used in the _draw() call
	_drawable_ship = Utils.float_array_to_Vector2Array(_coords_ship)
	_drawable_booster = Utils.float_array_to_Vector2Array(_coords_booster)
	_drawable_reverse_booster = Utils.float_array_to_Vector2Array(_coords_reverse_booster)
	
	# Load player sound effects into their AudioStreams
	_thruster_asp = AudioStreamPlayer2D.new()
	_thruster_asp.name = 'Thruster_ASP'
	_thruster_asp.stream = _thruster_stream
	add_child(_thruster_asp)
	
	_laser_asp = AudioStreamPlayer2D.new()
	_laser_asp.name = 'Laser_ASP'
	_laser_asp.stream = _laser_stream
	add_child(_laser_asp)

func _process(delta: float) -> void:
	if _pstate.shoot:
		var new_bullet = bullet_prefab.instantiate()
		new_bullet.global_position = position
		new_bullet.rotation = rotation
		var direction = Vector2.RIGHT.rotated(rotation)
		get_tree().root.add_child(new_bullet)
		_laser_asp.playing = true
		_pstate.shoot = false
		

func _physics_process(delta: float) -> void:
	# Get the input direction and handle the acceleration and rotation changes.
	get_input()
	rotation += _pstate.rotation_direction * ROTATION_SPEED * delta
	velocity += transform.x * _pstate.acceleration * delta
	velocity = velocity.limit_length(MAX_SPEED)	
	
	queue_redraw()
	move_and_slide()
	screen_wrap()

	
func _draw():
	var godot_blue: Color = Color("478cbf")
	if _pstate.acceleration > 0:
		var booster_red: Color = Color("ff8cbf")
		draw_polygon(_drawable_booster, [booster_red])
	elif _pstate.acceleration < 0:
		var booster_red: Color = Color("ff8cbf")
		draw_polygon(_drawable_reverse_booster, [booster_red])
	draw_polygon(_drawable_ship, [godot_blue])
	
	
func screen_wrap():
	position.x = wrapf(position.x, 0, Globals.SCREEN_SIZE.x)
	position.y = wrapf(position.y, 0, Globals.SCREEN_SIZE.y)

# Get all Input updates here and assign them to state
func get_input():
	_pstate.rotation_direction = Input.get_axis("left", "right")
	_pstate.acceleration = Input.get_axis("down", "up") * THRUST
	if Input.is_action_just_pressed("up") || Input.is_action_just_pressed("down"):
		_thruster_asp.playing = true
	elif Input.is_action_just_released("up") || Input.is_action_just_released("down"):
		_thruster_asp.playing = false
	_pstate.shoot = Input.is_action_just_pressed("ui_accept")

func blow_up():
	player_exploded.emit()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("asteroids"):
		blow_up()

class PlayerState:
	var acceleration := 0.0
	var rotation_direction := 0
	var shoot := false
