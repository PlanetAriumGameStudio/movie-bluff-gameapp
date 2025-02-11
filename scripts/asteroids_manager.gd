extends Node2D

const asteroid_prefab:PackedScene = preload("res://scenes/asteroid.tscn")

var player_score:int

@onready var score_label: Label = $GUI/MarginContainer/Score

func _ready() -> void:
	player_score = 0
	for i in range(0,5):
		var new_asteroid = asteroid_prefab.instantiate()
		new_asteroid.position = Vector2(Globals.RNG.randi_range(0,Globals.SCREEN_SIZE.x), Globals.RNG.randi_range(0,Globals.SCREEN_SIZE.y))
		new_asteroid.connect("asteroid_shot", update_score)
		self.add_child(new_asteroid)

func update_score():
	player_score += 100
	score_label.text = str("Score: ", player_score)
