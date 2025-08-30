extends Control

### [STATE TRACKING]
enum State {INIT, WAITING_FOR_OPPONENT, PLAYING, SUBMITTING, COMPLETED}
var current_state: State

# This will be important for an async game
var player_is_active: bool = false

# Placeholder for the API client for competitive mode
# We will likely need a new one, e.g., "CompetitiveGameAPI"
# @onready var api_client = %CompetitiveGameAPI

func _ready() -> void:
	print("Competitive Game Ready")
	set_state(State.INIT)

# --- State Machine ---

func set_state(new_state: State) -> void:
	if current_state == new_state and current_state != State.INIT:
		return

	# Exit logic for the current state
	match current_state:
		State.WAITING_FOR_OPPONENT:
			_exit_waiting_for_opponent()
		State.PLAYING:
			_exit_playing()
		State.SUBMITTING:
			_exit_submitting()
		State.COMPLETED:
			_exit_completed()
			
	current_state = new_state

	# Enter logic for the new state
	match current_state:
		State.INIT:
			_enter_init()
		State.WAITING_FOR_OPPONENT:
			_enter_waiting_for_opponent()
		State.PLAYING:
			_enter_playing()
		State.SUBMITTING:
			_enter_submitting()
		State.COMPLETED:
			_enter_completed()

# --- State Enter/Exit Logic ---

func _enter_init():
	print("Entering INIT state")
	# TODO: Reset all game variables to their defaults
	
	# TODO: Connect to all signals from our API client
	# api_client.game_state_received.connect(_on_api_game_state_received)
	# api_client.submission_succeeded.connect(_on_api_submission_succeeded)
	# api_client.request_failed.connect(_on_api_request_failed)

	# TODO: Initial fetch of the game state from the server
	# api_client.fetch_game_state()
	
	# For now, we'll just transition to waiting
	set_state(State.WAITING_FOR_OPPONENT)


func _enter_waiting_for_opponent():
	print("Entering WAITING_FOR_OPPONENT state")
	# TODO: Show UI indicating we are waiting for the other player
	# This could be a waiting spinner, or a message.
	# We might need a timer to periodically check the game state.

func _exit_waiting_for_opponent():
	print("Exiting WAITING_FOR_OPPONENT state")
	# TODO: Hide the waiting UI

func _enter_playing():
	print("Entering PLAYING state")
	# TODO: Enable UI elements for gameplay
	# This is where the player will make their moves.

func _exit_playing():
	print("Exiting PLAYING state")
	# TODO: Disable UI to prevent input when not in the PLAYING state

func _enter_submitting():
	print("Entering SUBMITTING state")
	# TODO: Show a loading indicator while we send the data to the server

func _exit_submitting():
	print("Exiting SUBMITTING state")
	# TODO: Hide the loading indicator

func _enter_completed():
	print("Entering COMPLETED state")
	# TODO: Show the game over screen with results
	# %GameCompletionPopupPanel.popup()

func _exit_completed():
	print("Exiting COMPLETED state")

# --- API Signal Handlers ---

# func _on_api_game_state_received(game_state: Dictionary):
# 	# TODO: Process the game state from the server
# 	# This will determine if it's our turn, what the current path is, etc.
# 	if game_state.get("game_over", false):
# 		set_state(State.COMPLETED)
# 	elif game_state.get("is_current_player_turn", false):
# 		set_state(State.PLAYING)
# 	else:
# 		set_state(State.WAITING_FOR_OPPONENT)

# func _on_api_submission_succeeded(response: Dictionary):
# 	# The server has confirmed our move, now we wait for the opponent
# 	set_state(State.WAITING_FOR_OPPONENT)

# func _on_api_request_failed(message: String):
# 	# TODO: Implement a user-facing error popup
# 	print("API Error: ", message)
# 	# We might want to return to the PLAYING state to allow the user to retry
# 	if current_state == State.SUBMITTING:
# 		set_state(State.PLAYING)


# --- UI Event Handlers ---

func _on_submit_button_pressed() -> void:
	if current_state != State.PLAYING:
		return
	
	print("Submitting move...")
	# TODO: Gather the data from the UI
	# var move_data = ... 
	
	# Transition to the submitting state
	set_state(State.SUBMITTING)
	
	# TODO: Call the API to submit the move
	# api_client.submit_move(move_data)

func _on_back_button_pressed() -> void:
	# TODO: Add logic to safely leave the game
	# You might want to confirm with the user if they want to forfeit
	TransitionManager.change_scene("res://scenes/menus/main_menu/main_menu.tscn", 1)
