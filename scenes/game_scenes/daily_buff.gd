extends Control

const DAILY_API_ENDPOINT = "/api/games/daily"
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
	_update_changing(CHANGE_TYPES.NONE)
	_update_direction_text()

	# Make the initial API call
	BluffClient.instance.http_request.request_completed.connect(_handle_daily_response, CONNECT_ONE_SHOT)
	BluffClient.instance.make_request(DAILY_API_ENDPOINT)

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
	BluffClient.instance.make_request(DAILY_API_ENDPOINT, HTTPClient.METHOD_POST, JSON.stringify(data_to_send))

func _update_changing(type: CHANGE_TYPES) -> void:
	last_change = type
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
	%StartingPair.set_highlight(highlight_type)
	%FinishingPair.set_highlight(highlight_type)
	
func _handle_daily_response(result, _response_code, _headers, body):
	print("Got Daily Response")
	if result == 0:
		var json = JSON.parse_string(body.get_string_from_utf8())
		var startingPair:Pairing = Pairing.parse_pairing_from_json(json["starting_pair"])
		var finishingPair:Pairing = Pairing.parse_pairing_from_json(json["finishing_pair"])
		%StartingPair.set_pairing(startingPair)
		%FinishingPair.set_pairing(finishingPair)
		%DailyPath.init_daily_path(startingPair, finishingPair)
		print("Initialized, transitioning to PLAYING state")
		set_state(State.PLAYING)
	else:
		print("Non-Zero Status in Request Response: %d", result)

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

func _on_submission_button_button_down() -> void:
	if current_state != State.PLAYING:
		return

	if current_direction == START_TO_FINISH:
		current_pairing = %StartingPair.get_pair()
	else:
		current_pairing = %FinishingPair.get_pair()
		
	# Changing Movie
	if last_change == CHANGE_TYPES.PERSON:
		var credit_index = current_pairing.person_credits.find_custom(_movie_has_submission)
		if credit_index > -1:
			# Success: Update pairing and get new credits list
			var next_pairing = current_pairing.duplicate()
			next_pairing.movie_id = current_pairing.person_credits[credit_index].id
			next_pairing.movie_name = current_pairing.person_credits[credit_index].title
			next_pairing.movie_poster_url = current_pairing.person_credits[credit_index].poster_path
			_get_credits_for_movie(current_pairing.person_credits[credit_index].id, next_pairing)
			_update_changing(CHANGE_TYPES.MOVIE)
			_push_pair_to_path(next_pairing)
			%SubmissionInput.clear()
		else:
			print("not found")
	# Changing Person
	elif last_change == CHANGE_TYPES.MOVIE:
		var credit_index = current_pairing.movie_credits.find_custom(_person_has_submission)
		if credit_index > -1:
			var next_pairing = current_pairing.duplicate()
			next_pairing.person_id = current_pairing.movie_credits[credit_index].id
			next_pairing.person_name = current_pairing.movie_credits[credit_index].name
			next_pairing.person_profile_url = current_pairing.movie_credits[credit_index].profile_path
			_get_credits_for_person(current_pairing.movie_credits[credit_index].id, next_pairing)
			_update_changing(CHANGE_TYPES.PERSON)
			_push_pair_to_path(next_pairing)
			%SubmissionInput.clear()
		else:
			print("not found")
	else:
		print("error in last_change")
		
func _on_change_movie_button_button_down() -> void:
	if current_state != State.PLAYING:
		return
	_update_changing(CHANGE_TYPES.PERSON)

func _on_change_person_button_button_down() -> void:
	if current_state != State.PLAYING:
		return
	_update_changing(CHANGE_TYPES.MOVIE)
	
func _update_direction_text() -> void:
	if current_direction == START_TO_FINISH:
		%DirectionLabel.text = "Direction: Forewards"
	else: 
		%DirectionLabel.text = "Direction: Backwards"

func _on_change_direction_button_button_down() -> void:
	if current_state != State.PLAYING:
		return

	if current_direction == START_TO_FINISH:
		current_direction = FINISH_TO_START
		%GameboardHBoxContainer.split_offset = -200
	else: 
		current_direction = START_TO_FINISH
		%GameboardHBoxContainer.split_offset = 200
	_update_direction_text()

func _on_submit_button_button_down() -> void:
	daily_submission()

func _on_daily_path_game_completed() -> void:
	print("Game complete!")
	if current_state == State.PLAYING:
		set_state(State.COMPLETED)
