extends Node

# This component handles all communication with the backend API for the daily challenge.
# It emits signals with the parsed data, decoupling the main scene from the HTTP request details.

signal status_received(status_data)
signal game_setup_received(start_pair, end_pair)
signal submission_succeeded(results_data)
signal credits_for_movie_received(credits, original_pair)
signal credits_for_person_received(credits, original_pair)
signal request_failed(message)

const DAILY_GAME_ENDPOINT = "/api/games/daily"
const DAILY_STATUS_ENDPOINT = "/api/games/daily/status"
const MOVIE_CREDITS_API_ENDPOINT = "/api/movie/%d/cast"
const PERSON_CREDITS_API_ENDPOINT = "/api/person/%d/credits"

# --- Public API Methods ---

func fetch_status():
	print("Fetching daily status")
	BluffClient.instance.http_request.request_completed.connect(_handle_daily_status_response, CONNECT_ONE_SHOT)
	BluffClient.instance.make_request(DAILY_STATUS_ENDPOINT)

func fetch_game_data():
	BluffClient.instance.http_request.request_completed.connect(_handle_daily_response, CONNECT_ONE_SHOT)
	BluffClient.instance.make_request(DAILY_GAME_ENDPOINT)

func submit_daily(path_json: Dictionary):
	# TODO: The player_id should come from a central user session manager, not be hardcoded.
	var data_to_send = { "player_id": 1, "steps": path_json }
	BluffClient.instance.http_request.request_completed.connect(_handle_daily_submission_response, CONNECT_ONE_SHOT)
	BluffClient.instance.make_request(DAILY_GAME_ENDPOINT, HTTPClient.METHOD_POST, JSON.stringify(data_to_send))

func fetch_credits_for_movie(movie_id: int, pair: Pairing):
	BluffClient.instance.http_request.request_completed.connect(_handle_credits_for_movie_response.bind(pair), CONNECT_ONE_SHOT)
	BluffClient.instance.make_request(MOVIE_CREDITS_API_ENDPOINT % movie_id)

func fetch_credits_for_person(person_id: int, pair: Pairing):
	BluffClient.instance.http_request.request_completed.connect(_handle_credits_for_person_response.bind(pair), CONNECT_ONE_SHOT)
	BluffClient.instance.make_request(PERSON_CREDITS_API_ENDPOINT % person_id)

# --- Private Response Handlers ---

func _handle_daily_status_response(result, _response_code, _headers, body):
	var json_result = _parse_response(result, body, "Daily Status")
	if json_result == null: return
	
	status_received.emit(json_result)

func _handle_daily_response(result, _response_code, _headers, body):
	var json_result = _parse_response(result, body, "Daily Game Data")
	if json_result == null: return

	var startingPair:Pairing = Pairing.parse_pairing_from_json(json_result["starting_pair"])
	var finishingPair:Pairing = Pairing.parse_pairing_from_json(json_result["finishing_pair"])
	game_setup_received.emit(startingPair, finishingPair)

func _handle_daily_submission_response(result, _response_code, _headers, body):
	var json_result = _parse_response(result, body, "Daily Submission")
	if json_result == null: return
	
	submission_succeeded.emit(json_result)

func _handle_credits_for_movie_response(result, _response_code, _headers, body, next_pair):
	var json_result = _parse_response(result, body, "Movie Credits")
	if json_result == null: return
	
	credits_for_movie_received.emit(json_result["cast"], next_pair)

func _handle_credits_for_person_response(result, _response_code, _headers, body, next_pair):
	var json_result = _parse_response(result, body, "Person Credits")
	if json_result == null: return
	
	credits_for_person_received.emit(json_result["cast"], next_pair)

func _parse_response(result, body, request_name: String):
	if result != OK:
		var error_msg = "Request failed for %s with error code: %d" % [request_name, result]
		printerr(error_msg)
		request_failed.emit(error_msg)
		return null
	
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		var error_msg = "Failed to parse JSON for %s." % request_name
		printerr(error_msg)
		request_failed.emit(error_msg)
		return null
	
	return json
