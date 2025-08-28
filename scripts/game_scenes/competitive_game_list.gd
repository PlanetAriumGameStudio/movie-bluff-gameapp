extends Control

# This script will manage the list of ongoing and completed competitive games.

const GameListEntry = preload("res://scenes/game_scenes/game_list_entry.tscn")

@onready var active_games_list = %ActiveGamesList
@onready var completed_games_list = %CompletedGamesList

func _ready() -> void:
	print("Competitive Game List Ready")
	# Connect to API signals
	ApiClient.active_game_list_received.connect(_on_active_game_list_received)
	ApiClient.completed_game_list_received.connect(_on_completed_game_list_received)
	ApiClient.competitive_new_game_created.connect(_on_new_game_created)
	ApiClient.request_failed.connect(_on_api_request_failed)

	# Fetch the lists of games when the scene loads
	_fetch_game_lists()

func _fetch_game_lists() -> void:
	# TODO: Show a loading indicator
	ApiClient.fetch_active_game_list()
	ApiClient.fetch_completed_game_list()

# --- API Signal Handlers ---

func _on_active_game_list_received(games: Array) -> void:
	print("Received active game list: ", games)
	# TODO: Hide loading indicator
	_populate_game_list(active_games_list, games, true)

func _on_completed_game_list_received(games: Array) -> void:
	print("Received completed game list: ", games)
	# TODO: Hide loading indicator
	_populate_game_list(completed_games_list, games, false)

func _on_new_game_created(game_id: int) -> void:
	print("New game created with ID: ", game_id)
	# TODO: Hide loading indicator
	_on_game_selected(game_id)

func _on_api_request_failed(message: String) -> void:
	print("API Error: ", message)
	# TODO: Hide loading indicator
	# TODO: Show a user-facing error message

# --- UI Population ---

func _populate_game_list(list_node: VBoxContainer, games: Array, is_active_list: bool) -> void:
	# Clear any existing entries
	for child in list_node.get_children():
		child.queue_free()

	# Populate the list with the games from the server
	for game_data in games:
		var entry = GameListEntry.instantiate()
		
		var opponent_name = game_data.get("opponentUsername", "Unknown Player")
		entry.get_node("MarginContainer/HBoxContainer/GameInfoVBox/OpponentLabel").text = "vs. " + opponent_name

		var turn_status_label = entry.get_node("MarginContainer/HBoxContainer/GameInfoVBox/TurnStatusLabel")
		if is_active_list:
			var is_your_turn = game_data.get("isYourTurn", false)
			turn_status_label.text = "Your Turn" if is_your_turn else "Opponent's Turn"
		else:
			# You might want to show the winner or final score here
			turn_status_label.text = "Game Over"

		var game_id = game_data.get("gameId", -1)
		if game_id != -1:
			var options_button = entry.get_node("MarginContainer/HBoxContainer/OptionsButton")
			options_button.pressed.connect(_on_game_selected.bind(game_id))
		
		list_node.add_child(entry)

# --- UI Event Handlers ---

func _on_game_selected(game_id: int) -> void:
	if game_id == -1:
		print("Error: Invalid game ID for selection.")
		return

	print("Selected game: ", game_id)
	# TODO: Store the selected game ID globally or pass it to the scene
	# For example: GlobalState.selected_competitive_game_id = game_id
	TransitionManager.change_scene("res://scenes/game_scenes/competitive_bluff.tscn", 1)

func _on_new_game_button_pressed() -> void:
	print("Starting new game...")
	# TODO: Show a loading indicator
	ApiClient.create_new_competitive_game()

func _on_back_button_pressed() -> void:
	TransitionManager.change_scene("res://scenes/menus/main_menu/main_menu.tscn", 1)
