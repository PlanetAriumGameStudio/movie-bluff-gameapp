extends RigidBody2D

var asteroid: PackedVector2Array
var asteroid_coords: Array

const MAX_SPEED = 150.0
@export var MIN_ROTATION_SPEED = 2.0
@export var MAX_ROTATION_SPEED = 5.0

var rotation_speed:float
var rotation_direction:int

@onready var collision_poly = $CollisionPolygon2D

func _ready() -> void:
	# We want bespoke asteroids, so we will generate their shapes randomly
	generate_shape()
	generate_velocity()
	asteroid = float_array_to_Vector2Array(asteroid_coords)
	collision_poly.polygon = asteroid

func float_array_to_Vector2Array(coords : Array) -> PackedVector2Array:
	# Convert the array of floats into a PackedVector2Array.
	var array : PackedVector2Array = []
	for coord in coords:
		array.append(Vector2(coord[0], coord[1]))
	return array

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	screen_wrap()

func generate_velocity():
	# Generate rotation
	rotation_speed = Globals.RNG.randf_range(MIN_ROTATION_SPEED, MAX_ROTATION_SPEED) 
	rotation_direction = 1 
	inertia = 2
	apply_torque_impulse( rotation_direction * rotation_speed * 2)
	
	#Generate Direction and Velocity
	var new_force = Vector2.UP.rotated(deg_to_rad(Globals.RNG.randi_range(0, 360)))
	new_force *= 100
	apply_impulse(new_force)
	pass
	
func _draw():
	var asteroid_grey: Color = Color("220000")
	draw_polygon(asteroid, [asteroid_grey])

func screen_wrap():
	position.x = wrapf(position.x, 0, Globals.SCREEN_SIZE.x)
	position.y = wrapf(position.y, 0, Globals.SCREEN_SIZE.y)

func generate_shape():
	var rng = RandomNumberGenerator.new()
	var vertices = rng.randi_range(5, 9)
	
	# Create a "semi" circular shape
	var degrees_per_point = 360 / vertices
	for point in range(0, vertices):
		var length_from_center = rng.randi_range(20,40)
		var new_point = Vector2.UP * length_from_center
		new_point = new_point.rotated(deg_to_rad(point*degrees_per_point)) 
		asteroid_coords.append([new_point.x, new_point.y])
	
