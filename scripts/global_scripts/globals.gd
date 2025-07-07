extends Node2D

@onready var SCREEN_SIZE:Vector2 = get_viewport_rect().size
@onready var RNG:RandomNumberGenerator = RandomNumberGenerator.new()
@onready var BLUFF_API_BASE_ADDRESS:String = "http://127.0.0.1"
@onready var BLUFF_API_PORT:int = 8080

@onready var IMAGE_BASE_URL = ""
@onready var MOVIE_POSTER_SIZES = []
@onready var PERSON_PROFILE_SIZES = []
	
func set_image_base_url(image_base:String):
	IMAGE_BASE_URL = image_base
	
# This will be a string representation of an array of values
func set_movie_poster_sizes(sizes:Array):
	MOVIE_POSTER_SIZES = sizes

func set_person_profile_sizes(sizes:Array):
	PERSON_PROFILE_SIZES = sizes
