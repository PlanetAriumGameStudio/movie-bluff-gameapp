extends Node

# This is the unified, global API client for the entire application.
# It handles all HTTP communication with the backend server.

# --- Singleton Pattern ---
static var instance: ApiClient

# --- Signals ---
signal config_received()
signal daily_status_received(status_data: Dictionary)
signal daily_game_setup_received(start_pair: Pairing, end_pair: Pairing)
signal daily_submission_succeeded(results_data: Dictionary)
signal movie_credits_received(credits: Array, original_pair: Pairing)
signal person_credits_received(credits: Array, original_pair: Pairing)
signal competitive_game_list_received(games: Array)
signal competitive_game_state_received(game_state: Dictionary)
signal competitive_new_game_created(game_state: Dictionary)
signal request_failed(message: String)

# --- Constants ---
const SERVER_BASE_URL = "http://127.0.0.1:8080" # Change to your production URL

# --- Private Variables ---
var _http_request: HTTPRequest

# --- Godot Engine Methods ---
func _ready() -> void:
	if instance != null:
		queue_free()
		return
	instance = self
	
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	
	LoginManager.login_succeeded.connect(fetch_config)
	LoginManager.google_login_succeeded.connect(fetch_config)

# --- Public Methods ---

func fetch_config(_token = "") -> void:
	_make_request("/api/config", _on_config_received)

func fetch_daily_status() -> void:
	_make_request("/api/games/daily/status", _on_daily_status_response)

func fetch_daily_game_data() -> void:
	_make_request("/api/games/daily", _on_daily_game_data_response)

func submit_daily_path(path_json: Array) -> void:
	var body = { "player_id": 1, "steps": path_json } # TODO: Get player_id from LoginManager
	_make_request("/api/games/daily", _on_daily_submission_response, HTTPClient.METHOD_POST, JSON.stringify(body))

func fetch_credits_for_movie(movie_id: int, pair: Pairing) -> void:
	var bound_callback = _on_movie_credits_response.bind(pair)
	_make_request("/api/movie/%d/cast" % movie_id, bound_callback)

func fetch_credits_for_person(person_id: int, pair: Pairing) -> void:
	var bound_callback = _on_person_credits_response.bind(pair)
	_make_request("/api/person/%d/credits" % person_id, bound_callback)

func fetch_competitive_game_list() -> void:
	_make_request("/api/competitive/games", _on_competitive_game_list_response)

func create_new_competitive_game() -> void:
	_make_request("/api/competitive/games/new", _on_competitive_new_game_response, HTTPClient.METHOD_POST)

func fetch_competitive_game_state(game_id: String) -> void:
	_make_request("/api/competitive/games/%s" % game_id, _on_competitive_game_state_response)

# --- Private Core Logic ---

func _make_request(endpoint: String, callback: Callable, method: int = HTTPClient.METHOD_GET, body: String = "") -> void:
	if not LoginManager.is_logged_in():
		printerr("ApiClient: Cannot make request, user is not logged in.")
		emit_signal("request_failed", "Not logged in")
		return

	var headers = LoginManager.get_auth_header()
	headers.append("X-API-Key: %s" % Globals.API_SECRET_KEY)
	if method in [HTTPClient.METHOD_POST, HTTPClient.METHOD_PUT]:
		headers.append("Content-Type: application/json")

	var url = SERVER_BASE_URL + endpoint
	_http_request.request_completed.connect(callback, CONNECT_ONE_SHOT)
	var error = _http_request.request(url, headers, method, body)

	if error != OK:
		printerr("HTTPRequest failed immediately with error: ", error)
		emit_signal("request_failed", "Initial request error.")

func _parse_response(result: int, response_code: int, body: PackedByteArray, request_name: String) -> Variant:
	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("request_failed", "Request failed for %s: %s" % [request_name, result])
		return null
	
	if response_code >= 400:
		emit_signal("request_failed", "Request failed for %s with code: %s" % [request_name, response_code])
		return null

	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())
	if parse_error != OK:
		emit_signal("request_failed", "JSON parse error for %s" % request_name)
		return null
	
	return json.get_data()

# --- Private Response Handlers ---

func _on_config_received(result, response_code, _headers, body):
	var data = _parse_response(result, response_code, body, "Config")
	if data == null: return
	Globals.set_movie_poster_sizes(data["images"]["poster_sizes"])
	Globals.set_person_profile_sizes(data["images"]["profile_sizes"])
	Globals.set_image_base_url(data["images"]["base_url"])
	emit_signal("config_received")

func _on_daily_status_response(result, response_code, _headers, body):
	var data = _parse_response(result, response_code, body, "Daily Status")
	if data == null: return
	emit_signal("daily_status_received", data)

func _on_daily_game_data_response(result, response_code, _headers, body):
	var data = _parse_response(result, response_code, body, "Daily Game Data")
	if data == null: return
	var start = Pairing.parse_pairing_from_json(data["starting_pair"])
	var end = Pairing.parse_pairing_from_json(data["finishing_pair"])
	emit_signal("daily_game_setup_received", start, end)

func _on_daily_submission_response(result, response_code, _headers, body):
	var data = _parse_response(result, response_code, body, "Daily Submission")
	if data == null: return
	emit_signal("daily_submission_succeeded", data)

func _on_movie_credits_response(result, response_code, _headers, body, pair):
	var data = _parse_response(result, response_code, body, "Movie Credits")
	if data == null: return
	emit_signal("movie_credits_received", data["cast"], pair)

func _on_person_credits_response(result, response_code, _headers, body, pair):
	var data = _parse_response(result, response_code, body, "Person Credits")
	if data == null: return
	emit_signal("person_credits_received", data["cast"], pair)

func _on_competitive_game_list_response(result, response_code, _headers, body):
	var data = _parse_response(result, response_code, body, "Competitive Game List")
	if data == null: return
	emit_signal("competitive_game_list_received", data.get("games", []))

func _on_competitive_new_game_response(result, response_code, _headers, body):
	var data = _parse_response(result, response_code, body, "New Competitive Game")
	if data == null: return
	emit_signal("competitive_new_game_created", data)

func _on_competitive_game_state_response(result, response_code, _headers, body):
	var data = _parse_response(result, response_code, body, "Competitive Game State")
	if data == null: return
	emit_signal("competitive_game_state_received", data)
