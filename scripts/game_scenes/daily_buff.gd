extends Control

const DAILY_GAME_ENDPOINT = "/api/games/daily" # GET for setup, POST for submission
const DAILY_STATUS_ENDPOINT = "/api/games/daily/status" # GET for checking submission status
const MOVIE_CREDITS_API_ENDPOINT = "/api/movie/%d/cast"
const PERSON_CREDITS_API_ENDPOINT = "/api/person/%d/credits"

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

# Call API daily endpoint to populate start and finish pairs
# TODO incorporate account information later
func _ready() -> void:
	print("Ready")
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

	# Make the initial API call to check status
	BluffClient.instance.http_request.request_completed.connect(_handle_daily_status_response, CONNECT_ONE_SHOT)
	BluffClient.instance.make_request(DAILY_STATUS_ENDPOINT)

func _enter_playing():
	print("Entering PLAYING state")
	# TODO: Enable UI elements for gameplay

func _exit_playing():
	print("Exiting PLAYING state")
	# TODO: Disable UI to prevent input during state transitions or in other states

func _enter_completed():
	print("Entering COMPLETED state")
	%GameCompletionPopupPanel.popup()

func _exit_completed():
	print("Exiting COMPLETED state")

func daily_submission():
	print("Submitting daily...")
	#TODO: Actual player ID/account hookup
	var data_to_send = { "player_id": 1, "steps": %DailyPath.get_full_path_json() }
	BluffClient.instance.http_request.request_completed.connect(_handle_daily_submission_response, CONNECT_ONE_SHOT)
	BluffClient.instance.make_request(DAILY_GAME_ENDPOINT, HTTPClient.METHOD_POST, JSON.stringify(data_to_send))

func _update_changing(type: CHANGE_TYPES) -> void:
	last_change = type
	_update_toggle_button_text()
	var highlight_type: MoviePersonPair.Highlight
	match type:
		CHANGE_TYPES.MOVIE:
			# When changing the movie, the person is the source. Highlight the person.
			highlight_type = MoviePersonPair.Highlight.PERSON
		CHANGE_TYPES.PERSON:
			# When changing the person, the movie is the source. Highlight the movie.
			highlight_type = MoviePersonPair.Highlight.MOVIE
		_: # This covers CHANGE_TYPES.NONE
			highlight_type = MoviePersonPair.Highlight.NONE
	
	# Always clear both highlights first to ensure a clean state.
	%StartingPair.set_highlight(MoviePersonPair.Highlight.NONE)
	%FinishingPair.set_highlight(MoviePersonPair.Highlight.NONE)

	# Then, apply the highlight only to the active pair.
	if current_direction == START_TO_FINISH:
		%StartingPair.set_highlight(highlight_type)
	else:
		%FinishingPair.set_highlight(highlight_type)
	
func _handle_daily_response(result, _response_code, _headers, body):
	print("Got Daily Response")
	if result != OK:
		print("Non-Zero Status in Request Response: %d", result)
		# TODO: Show an error popup to the user
		return
	
	var json_result = JSON.parse_string(body.get_string_from_utf8())
	if json_result == null:
		print("Failed to parse daily status JSON.")
		# TODO: Show an error message to the user
		return

	# User has not submitted, set up the game board.
	var startingPair:Pairing = Pairing.parse_pairing_from_json(json_result["starting_pair"])
	var finishingPair:Pairing = Pairing.parse_pairing_from_json(json_result["finishing_pair"])
	%StartingPair.set_pairing(startingPair)
	%FinishingPair.set_pairing(finishingPair)
	%DailyPath.init_daily_path(startingPair, finishingPair)
	print("Initialized, transitioning to PLAYING state")
	set_state(State.PLAYING)

func _handle_daily_status_response(result, _response_code, _headers, body):
	print("Got Daily Status Response")
	if result != OK:
		print("Non-Zero Status in Request Response: %d", result)
		# TODO: Show an error popup to the user
		return
	
	var json_result = JSON.parse_string(body.get_string_from_utf8())
	if json_result == null:
		print("Failed to parse daily status JSON.")
		# TODO: Show an error message to the user
		return
		
	if json_result.get("submitted", false): # Default to false if not found
		print("Already submitted for today. Fetching results.")
		# User has already submitted, make the call to get the results.
		BluffClient.instance.http_request.request_completed.connect(_handle_daily_results_response, CONNECT_ONE_SHOT)
		BluffClient.instance.make_request(DAILY_GAME_ENDPOINT)
	else:
		print("Not submitted yet. Fetching game setup.")
		# User has not submitted, make the call to get the game setup data.
		BluffClient.instance.http_request.request_completed.connect(_handle_daily_response, CONNECT_ONE_SHOT)
		BluffClient.instance.make_request(DAILY_GAME_ENDPOINT)

func _handle_daily_results_response(result, _response_code, _headers, body):
	print("Got Daily Results Response")
	if result != OK:
		print("Non-Zero Status in Request Response: %d", result)
		# TODO: Show an error popup to the user
		return
	
	var json_result = JSON.parse_string(body.get_string_from_utf8())
	if json_result == null:
		print("Failed to parse daily results JSON.")
		# TODO: Show an error message to the user
		return

	var results = json_result.get("results", [])
	_show_daily_results(results)

func _show_daily_results(results: Array) -> void:
	# Hide the main game UI elements
	%GameboardHBoxContainer.hide()
	%UserInputMargin.hide()
	
	# Repurpose the completion popup to show results
	%GameCompletionPopupPanel.title = "Daily Results"
	%DailySubmissionButton.hide() # Hide the submission button
	
	# TODO: Replace this with the bar chart visualization
	var results_text = "You've already completed the daily for today!\n\n"
	results_text += "Here's how everyone did:\n"
	for item in results:
		results_text += "  %s steps: %s players\n" % [item.steps, item.count]
	
	%GameCompletionLabel.text = results_text
	%GameCompletionPopupPanel.popup_centered()

func _handle_daily_submission_response(result, response_code, headers, body):
	if result == 0:
		var json = JSON.parse_string(body.get_string_from_utf8())
		print("Submissing results")
	else:
		print("Non-Zero Status in Request Response: %d", result)

func _get_credits_for_movie(movie_id: int, pair: Pairing):
	BluffClient.instance.http_request.request_completed.connect(_handle_credits_for_movie_response.bind(pair), CONNECT_ONE_SHOT)
	BluffClient.instance.make_request(MOVIE_CREDITS_API_ENDPOINT % movie_id)

func _handle_credits_for_movie_response(result, _response_code, _headers, body, next_pair):
	print("Got Credits for Movie Response")
	if result == 0:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if current_direction == FINISH_TO_START:
			next_pair.movie_credits = json["cast"]
			%FinishingPair.update_movie_pairing(next_pair)
		else:
			next_pair.movie_credits = json["cast"]
			%StartingPair.update_movie_pairing(next_pair)
	else:
		print("Non-Zero Status in Request Response: %d", result)

func _get_credits_for_person(person_id:int, pair: Pairing):
	BluffClient.instance.http_request.request_completed.connect(_handle_credits_for_person_response.bind(pair), CONNECT_ONE_SHOT)
	BluffClient.instance.make_request(PERSON_CREDITS_API_ENDPOINT % person_id)

func _handle_credits_for_person_response(result, _response_code, _headers, body, next_pair):
	print("Got Credits for Person Response")
	if result == 0:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if current_direction == FINISH_TO_START:
			next_pair.person_credits = json["cast"]
			%FinishingPair.update_person_pairing(next_pair)
		else:
			next_pair.person_credits = json["cast"]
			%StartingPair.update_person_pairing(next_pair)
	else:
		print("Non-Zero Status in Request Response: %d", result)

func _movie_has_submission(input):
	# TODO Better search comparisons and fuzzy logic
	return input["title"] == %SubmissionInput.text
	
func _person_has_submission(input):
	# TODO Better search comparisons and fuzzy logic
	return input["name"] == %SubmissionInput.text

func _push_pair_to_path(pair:Pairing):
	if current_direction == START_TO_FINISH:
		%DailyPath.push_to_start(pair)
	else:
		%DailyPath.push_to_finish(pair)

func _process_movie_change_submission():
	var credit_index = current_pairing.person_credits.find_custom(_movie_has_submission)
	if credit_index > -1:
		# Success: Update pairing and get new credits list
		var next_pairing = current_pairing.duplicate()
		var credit = current_pairing.person_credits[credit_index]
		next_pairing.movie_id = credit.id
		next_pairing.movie_name = credit.title
		next_pairing.movie_poster_url = credit.poster_path
		_get_credits_for_movie(credit.id, next_pairing)
		_update_changing(CHANGE_TYPES.MOVIE)
		_push_pair_to_path(next_pairing)
		%SubmissionInput.clear()
		%SubmissionInput.grab_focus()
	else:
		print("Submission Error: Movie not found in person's credits.")

func _process_person_change_submission():
	var credit_index = current_pairing.movie_credits.find_custom(_person_has_submission)
	if credit_index > -1:
		var next_pairing = current_pairing.duplicate()
		var credit = current_pairing.movie_credits[credit_index]
		next_pairing.person_id = credit.id
		next_pairing.person_name = credit.name
		next_pairing.person_profile_url = credit.profile_path
		_get_credits_for_person(credit.id, next_pairing)
		_update_changing(CHANGE_TYPES.PERSON)
		_push_pair_to_path(next_pairing)
		%SubmissionInput.clear()
		%SubmissionInput.grab_focus()
	else:
		print("Submission Error: Person not found in movie's credits.")

func _on_submission_button_button_down() -> void:
	if current_state != State.PLAYING:
		return
	current_pairing = %StartingPair.get_pair() if current_direction == START_TO_FINISH else %FinishingPair.get_pair()
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
	%SubmissionInput.grab_focus()

func _update_toggle_button_text():
	%ChangeTypeToggleButton.text = "Change to Person" if last_change == CHANGE_TYPES.PERSON else "Change to Movie"

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
	%SubmissionInput.grab_focus()

func _on_submit_button_button_down() -> void:
	daily_submission()

func _on_daily_path_game_completed() -> void:
	print("Game complete!")
	if current_state == State.PLAYING:
		set_state(State.COMPLETED)


func _on_back_button_pressed() -> void:
	# Based on your REPO-TODO, you have a scene transition global.
	# You may need to adjust the path to your main menu scene file.
	TransitionManager.change_scene("res://scenes/menus/main_menu/main_menu.tscn", 1)
