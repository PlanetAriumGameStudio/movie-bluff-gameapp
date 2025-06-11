extends Control

# TODO Replace this with custom client later
@onready var movie_bluff_api = $HTTPRequest

# Uses provided API Url:Port from config
const daily_api_format_string = "%s:%s/daily"
const movie_credits_api_format_string = "%s:%s/movie/%d/cast"
const person_credits_api_format_string = "%s:%s/person/%d/credits"

### [STATE TRACKING]
enum {INIT_STATE, PLAYING_STATE, COMPLETION_STATE}
var current_state = INIT_STATE

enum {START_TO_FINISH, FINISH_TO_START}
var current_direction = START_TO_FINISH

enum CHANGE_TYPES {NONE, MOVIE, PERSON}
var last_change:CHANGE_TYPES
var change_labels_dict = {
	CHANGE_TYPES.NONE: "Select Next Change",
	CHANGE_TYPES.MOVIE: "Changing: Person",
	CHANGE_TYPES.PERSON: "Changing: Movie",
}

var current_pairing:Pairing

# Tracks game completion state. will be updated once per submission.
var path_complete:bool

# Call API daily endpoint to populate start and finish pairs
# TODO incorporate account information later
func _ready() -> void:
	init_daily()
	
# Will initialize state and all components to prepare for a fresh daily attempt
func init_daily():
	print("Initializing")
	current_pairing = Pairing.new()
	current_state = INIT_STATE
	current_direction = START_TO_FINISH
	%DailyPath.path_from_start = Array([], TYPE_OBJECT, "Pairing", Pairing)
	%DailyPath.path_from_finish = Array([], TYPE_OBJECT, "Pairing", Pairing)
	path_complete = false
	_update_changing(CHANGE_TYPES.NONE)
	_update_direction_text()
	if !%DirectionArrow.flip_h:
		_update_direction_arrow()
	
	movie_bluff_api.request_completed.connect(_handle_daily_response, ConnectFlags.CONNECT_ONE_SHOT)
	var err = movie_bluff_api.request(daily_api_format_string % [Globals.BLUFF_API_BASE_ADDRESS, Globals.BLUFF_API_PORT])
	if err != OK:
		push_error(err)
		
func _update_changing(type:CHANGE_TYPES) -> void:
	last_change = type
	%ChangeTypeLabel.text = change_labels_dict.get(type)
	
func _handle_daily_response(result, response_code, headers, body):
	print("Got Daily Response")
	var json = JSON.parse_string(body.get_string_from_utf8())
	var startingPair:Pairing = Pairing.parse_pairing_from_json(json["starting_pair"])
	var finishingPair:Pairing = Pairing.parse_pairing_from_json(json["finishing_pair"])
	%StartingPair.set_pairing(startingPair)
	%FinishingPair.set_pairing(finishingPair)
	%DailyPath.init_daily_path(startingPair, finishingPair)
	print("Initialized")

func _get_credits_for_movie(movie_id:int):
	movie_bluff_api.request_completed.connect(_handle_credits_for_movie_response, ConnectFlags.CONNECT_ONE_SHOT)
	var err = movie_bluff_api.request(movie_credits_api_format_string % [Globals.BLUFF_API_BASE_ADDRESS, Globals.BLUFF_API_PORT, movie_id])
	if err != OK:
		push_error(err)

func _handle_credits_for_movie_response(result, response_code, headers, body):
	print("Got Credits for Movie Response")
	var json = JSON.parse_string(body.get_string_from_utf8())
	if current_direction == FINISH_TO_START:
		current_pairing.movie_credits = json["cast"]
		%FinishingPair.set_pairing(current_pairing)
	else:
		current_pairing.movie_credits = json["cast"]
		%StartingPair.update_movie_pairing(current_pairing)

func _get_credits_for_person(person_id:int):
	movie_bluff_api.request_completed.connect(_handle_credits_for_person_response, ConnectFlags.CONNECT_ONE_SHOT)
	var err = movie_bluff_api.request(person_credits_api_format_string % [Globals.BLUFF_API_BASE_ADDRESS, Globals.BLUFF_API_PORT, person_id])
	if err != OK:
		push_error(err)

func _handle_credits_for_person_response(result, response_code, headers, body):
	print("Got Credits for Person Response")
	var json = JSON.parse_string(body.get_string_from_utf8())
	if current_direction == FINISH_TO_START:
		current_pairing.person_credits = json["cast"]
		%FinishingPair.set_pairing(current_pairing)
	else:
		current_pairing.person_credits = json["cast"]
		%StartingPair.update_person_pairing(current_pairing)

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
	if current_direction == START_TO_FINISH:
		current_pairing = %StartingPair.get_pair()
	else:
		current_pairing = %FinishingPair.get_pair()
		
	# Changing Movie
	if last_change == CHANGE_TYPES.PERSON:
		print(current_pairing.movie_id)
		var credit_index = current_pairing.person_credits.find_custom(_movie_has_submission)
		if credit_index > -1:
			# Success: Update pairing and get new credits list
			current_pairing.movie_id = current_pairing.person_credits[credit_index].id
			current_pairing.movie_name = current_pairing.person_credits[credit_index].title
			current_pairing.movie_poster_url = current_pairing.person_credits[credit_index].poster_path
			_get_credits_for_movie(current_pairing.person_credits[credit_index].id)
			_update_changing(CHANGE_TYPES.MOVIE)
			_push_pair_to_path(current_pairing)
			%SubmissionInput.clear()
		else:
			print("not found")
	# Changing Person
	elif last_change == CHANGE_TYPES.MOVIE:
		var credit_index = current_pairing.movie_credits.find_custom(_person_has_submission)
		if credit_index > -1:
			current_pairing.person_id = current_pairing.movie_credits[credit_index].id
			current_pairing.person_name = current_pairing.movie_credits[credit_index].name
			current_pairing.person_profile_url = current_pairing.movie_credits[credit_index].profile_path
			_get_credits_for_person(current_pairing.movie_credits[credit_index].id)
			_update_changing(CHANGE_TYPES.PERSON)
			_push_pair_to_path(current_pairing)
			%SubmissionInput.clear()
		else:
			print("not found")
	else:
		print("error in last_change")
		
func _on_change_movie_button_button_down() -> void:
	_update_changing(CHANGE_TYPES.PERSON)

func _on_change_person_button_button_down() -> void:
	_update_changing(CHANGE_TYPES.MOVIE)
	
func _update_direction_text() -> void:
	if current_direction == START_TO_FINISH:
		%DirectionLabel.text = "Direction: Forewards"
	else: 
		%DirectionLabel.text = "Direction: Backwards"

func _update_direction_arrow() -> void:
	%DirectionArrow.flip_h = !%DirectionArrow.flip_h

func _on_change_direction_button_button_down() -> void:
	if current_direction == START_TO_FINISH:
		current_direction = FINISH_TO_START
	else: 
		current_direction = START_TO_FINISH
	_update_direction_text()
	_update_direction_arrow()
