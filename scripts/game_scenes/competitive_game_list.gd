extends Control

# This script will manage the list of ongoing competitive games for the player.

const GameListEntry = preload("res://scenes/game_scenes/game_list_entry.tscn")
@onready var game_list_vbox = %GameListVBox


# Placeholder for the API client. We'll need this to fetch the game list.
# @onready var api_client = %CompetitiveBluffAPI

func _ready() -> void:
	print("Competitive Game List Ready")
	# Connect to API signals here
	# api_client.game_list_received.connect(_on_api_game_list_received)
	# api_client.request_failed.connect(_on_api_request_failed)

	# Fetch the list of games when the scene loads
	# _fetch_game_list() 
	_populate_dummy_list() # Use dummy data for now

func _populate_dummy_list() -> void:
	# Clear any existing entries
	for child in game_list_vbox.get_children():
		child.queue_free()

	# Create a few dummy entries
	var dummy_data = [
		{"opponent": "PlayerOne", "status": "Their Turn"},
		{"opponent": "PlayerTwo", "status": "Your Turn"},
		{"opponent": "PlayerThree", "status": "Game Over"},
		{"opponent": "PlayerFour", "status": "Your Turn"}
	]

	for data in dummy_data:
		var entry = GameListEntry.instantiate()
		# NOTE: This path depends on the structure of your game_list_entry.tscn
		entry.get_node("MarginContainer/HBoxContainer/GameInfoVBox/OpponentLabel").text = "vs. " + data.opponent
		entry.get_node("MarginContainer/HBoxContainer/GameInfoVBox/TurnStatusLabel").text = data.status
		game_list_vbox.add_child(entry)

		# Example of how to connect a signal for when an entry is pressed
		# entry.get_node("MarginContainer/HBoxContainer/OptionsButton").pressed.connect(func(): _on_game_options_pressed(data.opponent))


func _fetch_game_list() -> void:
	print("Fetching game list...")
	# TODO: Call the API to get the player's active games
	# api_client.fetch_game_list()

# --- API Signal Handlers ---

func _on_api_game_list_received(games: Array) -> void:
	print("Received game list: ", games)
	# TODO: Clear the existing list
	# for child in game_list_vbox.get_children():
	# 	child.queue_free()
	
	# TODO: Populate the list with the games from the server
	# for game_data in games:
	# 	 var entry = GameListEntry.instantiate()
	# 	 entry.set_game_data(game_data) # You would create this function in the entry's script
	# 	 entry.pressed.connect(func(): _on_game_selected(game_data.id))
	# 	 game_list_vbox.add_child(entry)

func _on_api_request_failed(message: String) -> void:
	print("API Error: ", message)
	# TODO: Show an error message to the user

# --- UI Event Handlers ---

func _on_game_selected(game_id: String) -> void:
	print("Selected game: ", game_id)
	# TODO: Store the selected game ID globally or pass it to the scene
	# TransitionManager.selected_game_id = game_id
	TransitionManager.change_scene("res://scenes/game_scenes/competitive_bluff.tscn", 1)

func _on_new_game_button_pressed() -> void:
	print("Starting new game...")
	# TODO: This could transition to a matchmaking scene or directly create a new game
	# For now, let's assume it goes to the competitive bluff scene
	TransitionManager.change_scene("res://scenes/game_scenes/competitive_bluff.tscn", 1)

func _on_back_button_pressed() -> void:
	TransitionManager.change_scene("res://scenes/menus/main_menu/main_menu.tscn", 1)
