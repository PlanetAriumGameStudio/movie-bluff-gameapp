extends Node

# This is the unified, global API client for the entire application.
# It handles all HTTP communication with the backend server.

# --- Singleton Pattern ---
static var instance: ApiClient

# --- Signals ---
# Configuration Signals
signal config_received()

# Daily Challenge Signals
signal daily_status_received(status_data: Dictionary)
signal daily_game_setup_received(start_pair: Pairing, end_pair: Pairing)
signal daily_submission_succeeded(results_data: Dictionary)
signal movie_credits_received(credits: Array, original_pair: Pairing)
signal person_credits_received(credits: Array, original_pair: Pairing)

# Competitive Mode Signals
signal competitive_game_list_received(games: Array)
signal competitive_game_state_received(game_state: Dictionary)
signal competitive_new_game_created(game_state: Dictionary)

# Generic Failure Signal
signal request_failed(message: String)

# --- Constants ---
const SERVER_BASE_URL = "http://127.0.0.1:8080" # Change to your production URL

# --- Private Variables ---
var _http_request: HTTPRequest
var _pending_requests = {}

# --- Godot Engine Methods ---
func _ready() -> void:
	if instance != null:
		queue_free()
		return
	instance = self
	
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	
	LoginManager.login_succeeded.connect(fetch_config)
	LoginManager.google_login_succeeded.connect(fetch_config)

# --- Public Methods: Configuration ---
func fetch_config(_token = "") -> void:
	_make_request("/api/config", "GET_CONFIG")

# --- Public Methods: Daily Challenge ---
func fetch_daily_status() -> void:
	_make_request("/api/games/daily/status", "GET_DAILY_STATUS")

func fetch_daily_game_data() -> void:
	_make_request("/api/games/daily", "GET_DAILY_GAME_DATA")

func submit_daily_path(path_json: Array) -> void:
	var body = { "player_id": 1, "steps": path_json } # TODO: Get player_id from LoginManager
	_make_request("/api/games/daily", "SUBMIT_DAILY_PATH", HTTPClient.METHOD_POST, JSON.stringify(body))

func fetch_credits_for_movie(movie_id: int, pair: Pairing) -> void:
	_make_request("/api/movie/%d/cast" % movie_id, "GET_MOVIE_CREDITS", HTTPClient.METHOD_GET, "", {"pair": pair})

func fetch_credits_for_person(person_id: int, pair: Pairing) -> void:
	_make_request("/api/person/%d/credits" % person_id, "GET_PERSON_CREDITS", HTTPClient.METHOD_GET, "", {"pair": pair})

# --- Public Methods: Competitive Mode ---
func fetch_competitive_game_list() -> void:
	_make_request("/api/competitive/games", "GET_COMPETITIVE_GAMES")

func create_new_competitive_game() -> void:
	_make_request("/api/competitive/games/new", "CREATE_COMPETITIVE_GAME", HTTPClient.METHOD_POST)

func fetch_competitive_game_state(game_id: String) -> void:
	_make_request("/api/competitive/games/%s" % game_id, "GET_COMPETITIVE_GAME_STATE")

# --- Private Core Logic ---
func _make_request(endpoint: String, request_type: String, method: int = HTTPClient.METHOD_GET, body: String = "", meta: Dictionary = {}) -> void:
	if not LoginManager.is_logged_in():
		printerr("ApiClient: Cannot make request, user is not logged in.")
		emit_signal("request_failed", "Not logged in")
		return

	var headers = LoginManager.get_auth_header()
	headers.append("X-API-Key: %s" % Globals.API_SECRET_KEY)
	if method in [HTTPClient.METHOD_POST, HTTPClient.METHOD_PUT]:
		headers.append("Content-Type: application/json")

	var url = SERVER_BASE_URL + endpoint
	var error = _http_request.request(url, headers, method, body)

	if error != OK:
		printerr("HTTPRequest failed immediately with error: ", error)
		emit_signal("request_failed", "Initial request error.")
	else:
		# Store request type to handle response correctly
		var request_id = _http_request.get_http_client_status() # This is a way to identify the request
		_pending_requests[request_id] = {"type": request_type, "meta": meta}

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var request_id = result # The result is the ID of the completed request
	var request_info = _pending_requests.pop(request_id, {"type": "UNKNOWN", "meta": {}})
	var request_type = request_info.type
	var meta = request_info.meta

	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())
	
	if parse_error != OK:
		emit_signal("request_failed", "Invalid JSON response")
		return

	var response_data = json.get_data()

	if response_code >= 400:
		var error_message = response_data.get("error", "An unknown error occurred.")
		emit_signal("request_failed", error_message)
		return

	# --- Response Routing ---
	match request_type:
		"GET_CONFIG":
			Globals.set_movie_poster_sizes(response_data["images"]["poster_sizes"])
			Globals.set_person_profile_sizes(response_data["images"]["profile_sizes"])
			Globals.set_image_base_url(response_data["images"]["base_url"])
			emit_signal("config_received")
		"GET_DAILY_STATUS":
			emit_signal("daily_status_received", response_data)
		"GET_DAILY_GAME_DATA":
			var start = Pairing.parse_pairing_from_json(response_data["starting_pair"])
			var end = Pairing.parse_pairing_from_json(response_data["finishing_pair"])
			emit_signal("daily_game_setup_received", start, end)
		"SUBMIT_DAILY_PATH":
			emit_signal("daily_submission_succeeded", response_data)
		"GET_MOVIE_CREDITS":
			emit_signal("movie_credits_received", response_data["cast"], meta.pair)
		"GET_PERSON_CREDITS":
			emit_signal("person_credits_received", response_data["cast"], meta.pair)
		"GET_COMPETITIVE_GAMES":
			emit_signal("competitive_game_list_received", response_data.get("games", []))
		"GET_COMPETITIVE_GAME_STATE":
			emit_signal("competitive_game_state_received", response_data)
		"CREATE_COMPETITIVE_GAME":
			emit_signal("competitive_new_game_created", response_data)
		_:
			print("Unhandled API response type: ", request_type)
