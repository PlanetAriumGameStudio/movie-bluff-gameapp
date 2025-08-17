extends Control

# This script will manage the list of ongoing competitive games for the player.

const GameListEntry = preload("res://scenes/game_scenes/game_list_entry.tscn")
@onready var game_list_vbox = %GameListVBox

func _ready() -> void:
	print("Competitive Game List Ready")
	# Connect to API signals
	ApiClient.competitive_game_list_received.connect(_on_api_game_list_received)
	ApiClient.request_failed.connect(_on_api_request_failed)

	# Fetch the list of games when the scene loads
	_fetch_game_list()

func _fetch_game_list() -> void:
	print("Fetching competitive game list...")
	# Clear any existing entries while we wait for the new list
	for child in game_list_vbox.get_children():
		child.queue_free()
	
	# TODO: Show a loading indicator
	
	ApiClient.fetch_competitive_game_list()

# --- API Signal Handlers ---

func _on_api_game_list_received(games: Array) -> void:
	print("Received game list: ", games)
	# TODO: Hide loading indicator

	# Clear the list again just in case
	for child in game_list_vbox.get_children():
		child.queue_free()
	
	# Populate the list with the games from the server
	for game_data in games:
		var entry = GameListEntry.instantiate()
		
		# NOTE: This path depends on the structure of your game_list_entry.tscn
		# You will likely need to adjust the keys ("opponent_name", "turn_status") to match your actual API response.
		entry.get_node("MarginContainer/HBoxContainer/GameInfoVBox/OpponentLabel").text = "vs. " + game_data.get("opponent_name", "Unknown Player")
		entry.get_node("MarginContainer/HBoxContainer/GameInfoVBox/TurnStatusLabel").text = game_data.get("turn_status", "Unknown Status")
		
		# Connect the button to a function, passing the game_id
		var options_button = entry.get_node("MarginContainer/HBoxContainer/OptionsButton")
		options_button.pressed.connect(_on_game_selected.bind(game_data.get("id", "")))
		
		game_list_vbox.add_child(entry)

func _on_api_request_failed(message: String) -> void:
	print("API Error: ", message)
	# TODO: Hide loading indicator
	# TODO: Show a user-facing error message (e.g., a popup or a label)

# --- UI Event Handlers ---

func _on_game_selected(game_id: String) -> void:
	if game_id.is_empty():
		print("Error: Invalid game ID for selection.")
		return

	print("Selected game: ", game_id)
	# TODO: Store the selected game ID globally or pass it to the scene
	# For example: GlobalState.selected_competitive_game_id = game_id
	TransitionManager.change_scene("res://scenes/game_scenes/competitive_bluff.tscn", 1)

func _on_new_game_button_pressed() -> void:
	print("Starting new game...")
	# This now calls our unified API client
	ApiClient.create_new_competitive_game()
	# We should probably show a loading indicator here and wait for the 
	# competitive_new_game_created signal before transitioning.

func _on_back_button_pressed() -> void:
	TransitionManager.change_scene("res://scenes/menus/main_menu/main_menu.tscn", 1)
