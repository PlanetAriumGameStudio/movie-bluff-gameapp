class_name Player
extends CharacterBody2D

# To let things know when we explode
signal player_exploded

# Player constants
const MAX_SPEED = 150.0
const THRUST = 300.0
const ROTATION_SPEED = 5.0
const BULLET_SPEED = 250.0

# Player states
enum PLAYER_STATES {
	INACTIVE,
	ACTIVE
}

# Load in bullet prefab for easy shooting of anything 
@export var bullet_prefab: PackedScene

#Runtime state private variables
var _pstate : PlayerState = PlayerState.new()

# Basic vertex coordinate representations, will be converted to Vector2Arrays
var _coords_ship: Array = [[-4, 5], [-4, -5],[8, 0]]
var _drawable_ship: PackedVector2Array
var _coords_booster: Array = [[-4, 2], [-4, -2],[-7, 0]]
var _drawable_booster: PackedVector2Array
var _coords_reverse_booster: Array = [[-4, 5], [6, 3],[-4, 0], [6,-3], [-4,-5]]
var _drawable_reverse_booster: PackedVector2Array

# Ship sound streams
var _thruster_asp : AudioStreamPlayer2D
var _thruster_stream: AudioStream = preload("uid://diopf6l766lvg")
var _laser_asp : AudioStreamPlayer2D
var _laser_stream: AudioStream = preload("uid://c1r6gmiqnirw3")

func _ready():
	velocity = Vector2.ZERO
	
	# Convert coords into Vector2Array's to be used in the _draw() call
	_drawable_ship = Utils.float_array_to_Vector2Array(_coords_ship)
	_drawable_booster = Utils.float_array_to_Vector2Array(_coords_booster)
	_drawable_reverse_booster = Utils.float_array_to_Vector2Array(_coords_reverse_booster)
	
	# Load player sound effects into their AudioStreams
	_thruster_asp = AudioStreamPlayer2D.new()
	_thruster_asp.name = 'Thruster_ASP'
	_thruster_asp.stream = _thruster_stream
	_thruster_asp.bus = "SFX"
	add_child(_thruster_asp)
	
	_laser_asp = AudioStreamPlayer2D.new()
	_laser_asp.name = 'Laser_ASP'
	_laser_asp.stream = _laser_stream
	_laser_asp.bus = "SFX"
	add_child(_laser_asp)
	
	ready_player()

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

func ready_player():
	_pstate.current_state = PLAYER_STATES.ACTIVE

func blow_up():
	velocity = Vector2.ZERO
	_pstate.zero()
	player_exploded.emit()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if _pstate.current_state != PLAYER_STATES.INACTIVE && area.is_in_group("asteroids"):
		blow_up()

func _process(delta: float) -> void:
	if _pstate.current_state == PLAYER_STATES.ACTIVE:
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
	if _pstate.current_state == PLAYER_STATES.ACTIVE:
		get_input()
		move_and_slide()
		queue_redraw()
		screen_wrap()
		rotation += _pstate.rotation_direction * ROTATION_SPEED * delta
		velocity += transform.x * _pstate.acceleration * delta
		velocity = velocity.limit_length(MAX_SPEED)	
	
func _draw():
	var godot_blue: Color = Color("478cbf")
	if _pstate.acceleration > 0:
		var booster_red: Color = Color("ff8cbf")
		draw_polygon(_drawable_booster, [booster_red])
	elif _pstate.acceleration < 0:
		var booster_red: Color = Color("ff8cbf")
		draw_polygon(_drawable_reverse_booster, [booster_red])
	draw_polygon(_drawable_ship, [godot_blue])

class PlayerState:
	var current_state : PLAYER_STATES = PLAYER_STATES.INACTIVE
	var acceleration := 0.0
	var rotation_direction := 0
	var shoot := false
	
	func zero():
		current_state = PLAYER_STATES.INACTIVE
		acceleration = 0.0
