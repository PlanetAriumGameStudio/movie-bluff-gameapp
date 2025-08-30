extends BaseGame

### [STATE TRACKING]
enum State {INIT, PLAYING, COMPLETED}
var current_state: State

enum {START_TO_FINISH, FINISH_TO_START}
var current_direction = START_TO_FINISH

enum CHANGE_TYPES {NONE, MOVIE, PERSON}
var last_change:CHANGE_TYPES

var current_pairing:Pairing

# Tracks game completion state. will be updated once per submission.
var path_complete:bool

@onready var bar_chart = %BarChart

# --- Virtual Method Override ---

func _initialize_game() -> void:
	print("Daily Game Initializing")
	set_title("Daily Bluff")
	
	submit_button.pressed.connect(_on_submission_button_button_down)
	submission_input.text_submitted.connect(_on_submission_input_text_submitted)
	change_type_toggle_button.pressed.connect(_on_change_type_toggle_button_button_down)
	change_direction_button.pressed.connect(_on_change_direction_button_button_down)
	daily_path.game_completed.connect(_on_daily_path_game_completed)
	
	set_state(State.INIT)

# --- State Machine ---

func set_state(new_state: State) -> void:
	if current_state == new_state and current_state != State.INIT:
		return

	# Exit logic for the current state
	match current_state:
		State.PLAYING:
			_exit_playing()
		State.COMPLETED:
			_exit_completed()
	current_state = new_state

	# Enter logic for the new state
	match current_state:
		State.INIT:
			_enter_init()
		State.PLAYING:
			_enter_playing()
		State.COMPLETED:
			_enter_completed()

# --- State Enter/Exit Logic ---

func _enter_init():
	print("Entering INIT state")
	# Reset all game variables to their defaults
	current_pairing = Pairing.new()
	current_direction = START_TO_FINISH
	path_complete = false
	# Set initial UI state to match game state
	%GameboardHBoxContainer.split_offset = 200
	_update_changing(CHANGE_TYPES.PERSON) # Default to changing the Movie
	_update_toggle_button_text()
	%SubmissionInput.grab_focus()

	# Connect to all signals from our global ApiClient
	ApiClient.daily_status_received.connect(_on_api_status_received)
	ApiClient.daily_game_setup_received.connect(_on_api_game_setup_received)
	ApiClient.daily_submission_succeeded.connect(_on_api_submission_succeeded)
	ApiClient.movie_credits_received.connect(_on_api_credits_for_movie_received)
	ApiClient.person_credits_received.connect(_on_api_credits_for_person_received)
	ApiClient.request_failed.connect(_on_api_request_failed)

	print("Fetch Status")
	ApiClient.fetch_daily_status()

func _enter_playing():
	print("Entering PLAYING state")
	# TODO: Enable UI elements for gameplay

func _exit_playing():
	print("Exiting PLAYING state")
	# TODO: Disable UI to prevent input during state transitions or in other states

func _enter_completed():
	print("Entering COMPLETED state")
	game_completion_popup.popup()

func _exit_completed():
	print("Exiting COMPLETED state")

func daily_submission():
	print("Submitting daily...")
	#TODO: Actual player ID/account hookup
	var path_data = daily_path.get_full_path_json()
	ApiClient.submit_daily_path(path_data)

func _update_changing(type: CHANGE_TYPES) -> void:
	last_change = type
	_update_toggle_button_text()
	var highlight_type: int # MoviePersonPair.Highlight
	match type:
		CHANGE_TYPES.MOVIE:
			highlight_type = 2 # MoviePersonPair.Highlight.PERSON
		CHANGE_TYPES.PERSON:
			highlight_type = 1 # MoviePersonPair.Highlight.MOVIE
		_:
			highlight_type = 0 # MoviePersonPair.Highlight.NONE
	
	starting_pair.set_highlight(0)
	finishing_pair.set_highlight(0)

	if current_direction == START_TO_FINISH:
		starting_pair.set_highlight(highlight_type)
	else:
		finishing_pair.set_highlight(highlight_type)
	
func _show_daily_results(results: Array) -> void:
	# Hide the main game UI elements
	body.hide()
	footer.hide()
	
	# Repurpose the completion popup to show results
	game_completion_popup.title = "Daily Results"
	var completion_label = game_completion_popup.find_child("CompletionLabel")
	if completion_label:
		completion_label.hide()
	
	print("Populate chart with results:")
	print(results)
	bar_chart.show()
	bar_chart.populate_chart(results)
	
	game_completion_popup.popup_centered()

# --- Data Transformation ---

func _transform_results_map_to_array(results_map: Dictionary) -> Array:
	var results_array: Array = []
	for steps_str in results_map.keys():
		var steps_int = int(steps_str)
		var count = results_map[steps_str]
		results_array.append({"steps": steps_int, "count": count})
	return results_array


# --- API Signal Handlers ---

func _on_api_status_received(status_data: Dictionary):
	if status_data.get("submitted", false):
		print("Already submitted for today. Showing results.")
		var results_map = status_data.get("results_map", {})
		var results = _transform_results_map_to_array(results_map)
		_show_daily_results(results)
	else:
		print("Not submitted yet. Fetching game setup data.")
		ApiClient.fetch_daily_game_data()

func _on_api_game_setup_received(start_pair: Pairing, end_pair: Pairing):
	starting_pair.set_pairing(start_pair)
	finishing_pair.set_pairing(end_pair)
	daily_path.init_daily_path(start_pair, end_pair)
	print("Initialized, transitioning to PLAYING state")
	set_state(State.PLAYING)

func _on_api_submission_succeeded(results_data: Dictionary):
	print("Submission successful. Results: ", results_data)
	var results_map = results_data.get("results_map", {})
	_show_daily_results(_transform_results_map_to_array(results_map))

func _on_api_credits_for_movie_received(credits: Array, next_pair: Pairing):
	next_pair.movie_credits = credits
	if current_direction == FINISH_TO_START:
		finishing_pair.update_movie_pairing(next_pair)
	else:
		starting_pair.update_movie_pairing(next_pair)

func _on_api_credits_for_person_received(credits: Array, next_pair: Pairing):
	next_pair.person_credits = credits
	if current_direction == FINISH_TO_START:
		finishing_pair.update_person_pairing(next_pair)
	else:
		starting_pair.update_person_pairing(next_pair)

func _on_api_request_failed(message: String):
	# TODO: Implement a user-facing error popup
	print("API Error: ", message)

# --- UI Event Handlers ---

func _movie_has_submission(input):
	# TODO Better search comparisons and fuzzy logic
	return input["title"] == submission_input.text
	
func _person_has_submission(input):
	# TODO Better search comparisons and fuzzy logic
	return input["name"] == submission_input.text

func _push_pair_to_path(pair:Pairing):
	if current_direction == START_TO_FINISH:
		daily_path.push_to_start(pair)
	else:
		daily_path.push_to_finish(pair)

func _process_movie_change_submission():
	var credit_index = current_pairing.person_credits.find_custom(_movie_has_submission)
	if credit_index > -1:
		# Success: Update pairing and get new credits list
		var next_pairing = current_pairing.duplicate()
		var credit = current_pairing.person_credits[credit_index]
		next_pairing.movie_id = credit.id
		next_pairing.movie_name = credit.title
		next_pairing.movie_poster_url = credit.poster_path if credit.poster_path else ""
		ApiClient.fetch_credits_for_movie(credit.id, next_pairing)
		_update_changing(CHANGE_TYPES.MOVIE)
		_push_pair_to_path(next_pairing)
		submission_input.clear()
		submission_input.grab_focus()
	else:
		print("Submission Error: Movie not found in person's credits.")

func _process_person_change_submission():
	var credit_index = current_pairing.movie_credits.find_custom(_person_has_submission)
	if credit_index > -1:
		var next_pairing = current_pairing.duplicate()
		var credit = current_pairing.movie_credits[credit_index]
		next_pairing.person_id = credit.id
		next_pairing.person_name = credit.name
		next_pairing.person_profile_url = credit.profile_path if credit.profile_path else ""
		ApiClient.fetch_credits_for_person(credit.id, next_pairing)
		_update_changing(CHANGE_TYPES.PERSON)
		_push_pair_to_path(next_pairing)
		submission_input.clear()
		submission_input.grab_focus()
	else:
		print("Submission Error: Person not found in movie's credits.")

func _on_submission_button_button_down() -> void:
	if current_state != State.PLAYING:
		return
	current_pairing = starting_pair.get_pair() if current_direction == START_TO_FINISH else finishing_pair.get_pair()
	match last_change:
		CHANGE_TYPES.PERSON: # User is submitting a movie to change from a person
			_process_movie_change_submission()
		CHANGE_TYPES.MOVIE: # User is submitting a person to change from a movie
			_process_person_change_submission()
		_:
			print("Submission Error: No change type selected.")

func _on_submission_input_text_submitted(_new_text: String):
	# Trigger the same logic as clicking the submission button.
	_on_submission_button_button_down()
	
func _on_change_type_toggle_button_button_down() -> void:
	if current_state != State.PLAYING:
		return
		
	if last_change == CHANGE_TYPES.PERSON:
		_update_changing(CHANGE_TYPES.MOVIE)
	else:
		_update_changing(CHANGE_TYPES.PERSON)
	submission_input.grab_focus()

func _update_toggle_button_text():
	change_type_toggle_button.text = "Change to Person" if last_change == CHANGE_TYPES.PERSON else "Change to Movie"

func _on_change_direction_button_button_down() -> void:
	if current_state != State.PLAYING:
		return
	
	var target_offset: int
	if current_direction == START_TO_FINISH:
		current_direction = FINISH_TO_START
		target_offset = -200
	else: 
		current_direction = START_TO_FINISH
		target_offset = 200
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(%GameboardHBoxContainer, "split_offset", target_offset, 0.4)
	
	# Re-evaluate and apply highlights for the new direction.
	_update_changing(last_change)
	submission_input.grab_focus()

func _on_submit_button_button_down() -> void:
	daily_submission()

func _on_daily_path_game_completed() -> void:
	print("Game complete!")
	if current_state == State.PLAYING:
		set_state(State.COMPLETED)
