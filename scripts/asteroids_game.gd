class_name AsteroidsGame
extends Node2D

const player:PackedScene = preload("res://scenes/player.tscn")

var player_score:int
var player_lives:int
var player_ref:Player
var asteroids_music:AudioStreamPlayer


@onready var score_label:Label = $GUI/MarginContainer/Score
@onready var lives_label:Label = $GUI/MarginContainer/Lives
@onready var pause_menu:PanelContainer = $GUI/PauseMenu
@onready var game_over_menu:PanelContainer = $GUI/GameOverMenu
@onready var asteroids_manager:AsteroidsManager = $AsteroidsManager

func _ready():
	game_over_menu.visible = false
	pause_menu.visible = false
	
	asteroids_music = AudioStreamPlayer.new()
	asteroids_music.stream = load("res://audio/music/2021-10-19_-_Funny_Bit_-_FesliyanStudios_-_David_Renda.mp3")
	asteroids_music.autoplay = true
	add_child(asteroids_music)
	init_player()
	
func _process(delta : float) -> void:
	_get_input()
		
func init_player():
	player_score = 0
	player_lives = 3
	player_ref = player.instantiate()
	player_ref.position = Vector2(Globals.SCREEN_SIZE.x/2, Globals.SCREEN_SIZE.y/2)
	player_ref.connect("player_exploded", update_lives)
	self.add_child(player_ref)

func update_score():
	player_score += 100
	score_label.text = str("Score: ", player_score)
	
func update_lives():
	player_lives -= 1
	player_ref.position = Vector2(Globals.SCREEN_SIZE.x/2, Globals.SCREEN_SIZE.y/2)
	lives_label.text = str("Lives: ", player_lives)
	if player_lives <= 0:
		game_over()
		player_ref.queue_free()

func game_over():
	game_over_menu.visible = true
	
func _toggle_pause():
	get_tree().paused = not get_tree().paused
	pause_menu.visible = not pause_menu.visible

func _on_main_menu_button_pressed() -> void:
	if get_tree().paused: 
		get_tree().paused = not get_tree().paused
	TransitionManager.change_scene("res://scenes/main_menu.tscn", 1)
	

func _on_try_again_button_pressed() -> void:
	_ready()
	
func _get_input():
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()
		
