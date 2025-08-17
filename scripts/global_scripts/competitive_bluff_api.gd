extends Node

# Signal for when the list of games is successfully fetched.
signal game_list_received(games: Array)

# Signal for when the state of a single game is successfully fetched.
signal game_state_received(game_state: Dictionary)

# Signal for when a request fails.
signal request_failed(error_message: String)

# The base URL for your server's API.
@export var api_base_url: String = "http://localhost:8080/api/competitive" # Replace with your actual URL

@onready var http_request: HTTPRequest = $HTTPRequest

func _ready() -> void:
	# Connect the request completed signal from the HTTPRequest node.
	http_request.request_completed.connect(_on_request_completed)

# --- Public API Methods ---

func fetch_game_list() -> void:
	var url = "%s/games" % api_base_url
	print("Fetching game list from: %s" % url)
	_make_request(url, "GET_GAME_LIST")

func create_new_game() -> void:
	var url = "%s/games/new" % api_base_url
	print("Creating new game at: %s" % url)
	_make_request(url, "CREATE_GAME", HTTPClient.METHOD_POST)

func fetch_game_state(game_id: String) -> void:
	var url = "%s/games/%s" % [api_base_url, game_id]
	print("Fetching game state from: %s" % url)
	_make_request(url, "GET_GAME_STATE")

# --- Internal Logic ---

func _make_request(url: String, request_type: String, method: int = HTTPClient.METHOD_GET, body: String = "") -> void:
	var headers = ["Content-Type: application/json"]
	# TODO: Add authentication headers if needed
	# headers.append("Authorization: Bearer " + LoginManager.get_auth_token())
	
	var error = http_request.request(url, headers, method, body)
	if error != OK:
		print("HTTPRequest failed immediately with error: ", error)
		emit_signal("request_failed", "Initial request error.")

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var response_data = {}
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())

	if error != OK:
		print("JSON Parse Error: ", json.get_error_message())
		emit_signal("request_failed", "Invalid JSON response.")
		return

	response_data = json.get_data()

	match response_code:
		200, 201: # OK, Created
			_handle_successful_response(response_data)
		_: # Handle other codes (404, 500, etc.)
			var error_message = response_data.get("error", "An unknown error occurred.")
			print("API Error (HTTP %d): %s" % [response_code, error_message])
			emit_signal("request_failed", error_message)

func _handle_successful_response(data: Dictionary) -> void:
	# This is a simple way to route responses. A more robust implementation
	# might pass the original 'request_type' to the completion handler.
	# For now, we'll infer based on the data structure.
	if data.has("games"):
		emit_signal("game_list_received", data.games)
	elif data.has("game_state"):
		emit_signal("game_state_received", data.game_state)
	else:
		# Fallback for other successful responses, e.g., new game creation
		print("Received unhandled successful response: ", data)
