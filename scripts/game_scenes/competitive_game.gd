extends BaseGame

@onready var current_pair: MoviePersonPair = %CurrentPair
@onready var waiting_overlay: PanelContainer = %WaitingOverlay
@onready var history_panel: PanelContainer = %HistoryPanel
@onready var history_button: Button = %HistoryButton
@onready var call_bluff_button: Button = %CallBluffButton
@onready var concede_button: Button = %ConcedeButton

var player_is_active: bool = false
var game_id: int
var game_state: Dictionary
var _history_panel_visible = false

# --- Public Methods ---

func start_game(p_game_id: int) -> void:
	game_id = p_game_id

# --- Virtual Method Override ---

func _initialize_game() -> void:
	print("Competitive Game Initializing")
	set_title("Versus X")
	
	# Connect UI signals
	history_button.pressed.connect(_on_history_button_pressed)
	call_bluff_button.pressed.connect(_on_call_bluff_button_pressed)
	concede_button.pressed.connect(_on_concede_button_pressed)
	submit_button.pressed.connect(_on_submission)
	submission_input.text_submitted.connect(_on_submission)

	# Connect API signals
	ApiClient.competitive_submission_succeeded.connect(_on_api_submission_succeeded)
	ApiClient.competitive_game_state.connect(_on_api_game_state_received)
	ApiClient.request_failed.connect(_on_api_request_failed)
	
	set_state(State.INIT)

# --- State Enter/Exit Logic ---

func _enter_init():
	print("Entering INIT state")
	# Position the history panel off-screen initially and hide it
	history_panel.position.x = get_viewport_rect().size.x
	history_panel.hide()
	
	# Reset game variables to their defaults
	game_state = {}
	
	# Initial fetch of the game state from the server
	_fetch_game_state()


func _enter_waiting_for_opponent():
	print("Entering WAITING_FOR_OPPONENT state")
	waiting_overlay.show()
	# The concede button should be available even when waiting
	concede_button.disabled = false
	# All other controls should be disabled
	call_bluff_button.disabled = true
	submit_button.disabled = true
	submission_input.editable = false


func _exit_waiting_for_opponent():
	print("Exiting WAITING_FOR_OPPONENT state")
	waiting_overlay.hide()

func _enter_playing():
	print("Entering PLAYING state")
	# Enable all controls for the active player
	concede_button.disabled = false
	call_bluff_button.disabled = false
	submit_button.disabled = false
	submission_input.editable = true

func _exit_playing():
	print("Exiting PLAYING state")
	# Disable all controls when leaving the playing state
	concede_button.disabled = true
	call_bluff_button.disabled = true
	submit_button.disabled = true
	submission_input.editable = false

func _enter_submitting():
	print("Entering SUBMITTING state")
	# TODO: Show a loading indicator while we send the data to the server

func _exit_submitting():
	print("Exiting SUBMITTING state")
	# TODO: Hide the loading indicator

func _enter_completed():
	print("Entering COMPLETED state")
	
	var winner_id = game_state.get("winnerId", 0)
	var player_id = LoginManager.get_player_id() # Assuming LoginManager autoload
	
	var title_text = ""
	var message_text = ""
	
	if winner_id == player_id:
		title_text = "You Win!"
	else:
		title_text = "You Lose!"
		
	message_text = game_state.get("winReason", "The game has concluded.")
	
	# Get popup nodes
	var popup = %GameCompletionPopup
	var title_label = popup.get_node("VBoxContainer/CompletionLabel")
	var results_container = popup.get_node("VBoxContainer/ResultsContainer")
	
	# Clear any old results
	for child in results_container.get_children():
		child.queue_free()
		
	# Set new results
	title_label.text = title_text
	var message_label = Label.new()
	message_label.text = message_text
	results_container.add_child(message_label)
	
	# Disable game controls
	call_bluff_button.disabled = true
	concede_button.disabled = true
	submit_button.disabled = true
	submission_input.editable = false
	
	popup.popup_centered()

func _exit_completed():
	print("Exiting COMPLETED state")

# --- Private Methods ---

func _fetch_game_state() -> void:
	if not game_id:
		print_debug("Game ID not set. Cannot fetch game state.")
		# TODO: Handle this error gracefully, maybe return to main menu
		return
	ApiClient.fetch_competitive_game_state(game_id)


func _update_history_lists(p_game_state: Dictionary) -> void:
	var movie_list = %HistoryPanel.get_node("TabContainer/UsedMovies/ScrollContainer/MovieList")
	var people_list = %HistoryPanel.get_node("TabContainer/UsedPeople/ScrollContainer/PeopleList")

	# Clear existing history
	for child in movie_list.get_children():
		child.queue_free()
	for child in people_list.get_children():
		child.queue_free()

	# Populate movie history
	if p_game_state.has("usedMovies"):
		for movie in p_game_state.usedMovies:
			var label = Label.new()
			label.text = movie.title
			movie_list.add_child(label)

	# Populate people history
	if p_game_state.has("usedPeople"):
		for person in p_game_state.usedPeople:
			var label = Label.new()
			label.text = person.name
			people_list.add_child(label)


# --- API Signal Handlers ---

func _on_api_game_state_received(p_game_state: Dictionary) -> void:
	game_state = p_game_state
	
	# The API returns a 'pairing' object nested in the game state
	if game_state.has("pairing"):
		var new_pairing = Pairing.parse_pairing_from_json(game_state.pairing)
		current_pair.set_pairing(new_pairing)
	
	_update_history_lists(game_state)
	
	if game_state.get("gameStatus", "") == "finished":
		set_state(State.COMPLETED)
	elif game_state.get("isYourTurn", false):
		set_state(State.PLAYING)
	else:
		set_state(State.WAITING_FOR_OPPONENT)


func _on_api_submission_succeeded(response: Dictionary):
	# The server has confirmed our move, now we just need to fetch the new state
	_fetch_game_state()


func _on_api_request_failed(message: String):
	# TODO: Implement a user-facing error popup
	print("API Error: ", message)
	# We might want to return to the PLAYING state to allow the user to retry
	if current_state == State.SUBMITTING:
		set_state(State.PLAYING)


# --- UI Event Handlers ---

func _on_submission() -> void:
	if current_state != State.PLAYING:
		return
	
	var submission_text = submission_input.get_text()
	if submission_text.is_empty():
		# TODO: Show an error to the user
		print("Submission is empty.")
		return

	# The selected pairing is stored in the submission_input by the base class
	var selected_pairing = submission_input.selected_pairing
	if not selected_pairing:
		# This can happen if the user types something that isn't from the autocomplete
		# For a bluff, this is allowed. We need to decide how to handle it.
		# For now, let's just log it. A more robust solution would check the API.
		print("No valid pairing selected for submission.")
		# We'll allow the submission to proceed as a potential bluff.
	
	var turn_data = {
		"type": "movie" if submission_input.get_meta("submission_type") == "movie" else "person",
		"id": selected_pairing.movie_id if selected_pairing and submission_input.get_meta("submission_type") == "movie" else selected_pairing.person_id if selected_pairing else 0,
		"name": submission_text # Send the raw text for the bluff case
	}

	print("Submitting move: ", turn_data)
	set_state(State.SUBMITTING)
	ApiClient.submit_pvp_turn(game_id, turn_data)

func _on_history_button_pressed() -> void:
	_history_panel_visible = not _history_panel_visible
	var tween = get_tree().create_tween()
	var target_position_x

	if _history_panel_visible:
		history_panel.show()
		target_position_x = get_viewport_rect().size.x - history_panel.size.x
	else:
		target_position_x = get_viewport_rect().size.x

	tween.tween_property(history_panel, "position:x", target_position_x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	if not _history_panel_visible:
		await tween.finished
		history_panel.hide()


func _on_call_bluff_button_pressed() -> void:
	if current_state != State.PLAYING:
		return
	
	print("Calling bluff...")
	set_state(State.SUBMITTING)
	ApiClient.competitive_call_bluff(game_id)


func _on_concede_button_pressed() -> void:
	# Allow conceding even when waiting
	if current_state != State.PLAYING and current_state != State.WAITING_FOR_OPPONENT:
		return
	
	print("Conceding game...")
	set_state(State.SUBMITTING)
	ApiClient.competitive_concede_game(game_id)
