class_name AsteroidsGame
extends Node2D

const PLAYER_SCENE : PackedScene = preload("res://scenes/game_scenes/asteroids/player.tscn")
const ASTEROIDS_MUSIC : AudioStream = preload("res://audio/music/2021-10-19_-_Funny_Bit_-_FesliyanStudios_-_David_Renda.mp3")

var asteroids_music_player : AudioStreamPlayer
var _spawn_timer : Timer
var _player_ref : Player
var _player_score : int
var _player_lives : int

@onready var spawn_box : Area2D =  $SpawnBox
@onready var score_label : Label = $GUI/MarginContainer/Score
@onready var lives_label : Label = $GUI/MarginContainer/Lives
@onready var respawn_timer_label : Label = $GUI/MarginContainer/RespawnTimer
@onready var game_over_menu : PanelContainer = $GUI/GameOverMenu
@onready var asteroids_manager : AsteroidsManager = $AsteroidsManager

func _ready():
	game_over_menu.visible = false
	respawn_timer_label.visible = false
	_spawn_timer = Timer.new()
	spawn_box.monitoring = false
	_spawn_timer.connect("timeout", _on_spawn_timer_timeout)
	add_child(_spawn_timer)

	_init_audio()
	_init_player()

func _process(delta: float) -> void: 
	if respawn_timer_label.visible: 
		respawn_timer_label.text = str("Respawning: ", _spawn_timer.time_left)

func update_score(value : int):
	_player_score += value
	score_label.text = str("Score: ", _player_score)
	
func update_lives():
	_player_lives -= 1
	if _player_lives <= 0:
		_game_over()
		_player_ref.queue_free()
	else:
		spawn_box.monitoring = true
		lives_label.text = str("Lives: ", _player_lives)
		_player_ref.position = Vector2(Globals.SCREEN_SIZE.x/2, Globals.SCREEN_SIZE.y/2)
		_spawn_timer.start(2.0)
		respawn_timer_label.visible = true

func _game_over():
	game_over_menu.visible = true

func _init_player():
	# This is hacky and needs to be reworked
	_player_lives = 3
	_player_score = 0
	update_score(0)
	
	if _player_ref == null:
		_player_ref = PLAYER_SCENE.instantiate()
		_player_ref.connect("player_exploded", update_lives)
		add_child(_player_ref)
	_player_ref.position = Vector2(Globals.SCREEN_SIZE.x/2, Globals.SCREEN_SIZE.y/2)
	
func _init_audio():
	if asteroids_music_player == null:
		asteroids_music_player = AudioStreamPlayer.new()
		asteroids_music_player.stream = ASTEROIDS_MUSIC
		asteroids_music_player.autoplay = true
		asteroids_music_player.bus = "Music"
		add_child(asteroids_music_player)
	else:
		asteroids_music_player.seek(0)

func _on_main_menu_button_pressed() -> void:
	if get_tree().paused: 
		get_tree().paused = not get_tree().paused
	TransitionManager.change_scene("res://scenes/menus/main_menu/main_menu.tscn", 1)
	
func _on_try_again_button_pressed() -> void:
	_ready()
	asteroids_manager.init_asteroids()

func _on_asteroids_manager_level_cleared() -> void:
	_game_over()

func _on_asteroids_manager_player_scored() -> void:
	update_score(100)

func _on_spawn_timer_timeout():
	_player_ref.ready_player()
	respawn_timer_label.visible = false
	spawn_box.monitoring = false
	_spawn_timer.stop()

func _on_spawn_box_area_entered(area: Area2D) -> void:
	_spawn_timer.start(2.0)
	_spawn_timer.paused = true

func _on_spawn_box_area_exited(area: Area2D) -> void:
	if !spawn_box.has_overlapping_areas():
		_spawn_timer.paused = false
	
