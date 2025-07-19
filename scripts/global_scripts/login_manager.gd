extends Node

# Emitted when auth state changes
signal login_succeeded(token)
signal login_failed(error_message)
signal registration_succeeded(token)
signal registration_failed(error_message)
signal google_login_succeeded(token)
signal google_login_failed(error_message)

# --- Configuration ---
const SERVER_BASE_URL = "http://127.0.0.1:8080"
const POLLING_INTERVAL_SECONDS = 2.0 # Poll every 2 seconds
const POLLING_TIMEOUT_SECONDS = 300  # 5 minutes, should match server's state expiration

# --- State Management ---
enum AuthStatus { NOT_LOGGED_IN, VERIFYING, LOGGED_IN }
var auth_status = AuthStatus.NOT_LOGGED_IN

# --- Internal State ---
var _jwt_token: String = ""
var _google_login_state: String = ""
var _is_polling: bool = false

# HTTPRequest nodes for different API calls
var _login_request: HTTPRequest
var _register_request: HTTPRequest
var _google_url_request: HTTPRequest
var _google_poll_request: HTTPRequest
var _verify_token_request: HTTPRequest

var _polling_timer: Timer
var _timeout_timer: Timer

# Path to save the token for persistence
const TOKEN_SAVE_PATH = "user://session.dat"
# A secret key for encrypting the token on disk.
# TODO: Change this to a long, random string for production build.
const ENCRYPTION_KEY = "a_very_secret_and_long_key_for_my_game"

func _ready():
	# Setup HTTPRequest nodes
	_login_request = HTTPRequest.new()
	_register_request = HTTPRequest.new()
	_google_url_request = HTTPRequest.new()
	_google_poll_request = HTTPRequest.new()
	_verify_token_request = HTTPRequest.new()
	add_child(_login_request)
	add_child(_register_request)
	add_child(_google_url_request)
	add_child(_google_poll_request)
	add_child(_verify_token_request)

	_login_request.name = "LoginRequest"
	_register_request.name = "RegisterRequest"
	_google_url_request.name = "GoogleURLRequest"
	_google_poll_request.name = "GooglePollRequest"
	_verify_token_request.name = "VerifyTokenRequest"
	_login_request.use_threads = true
	_register_request.use_threads = true
	_google_url_request.use_threads = true
	_google_poll_request.use_threads = true
	_verify_token_request.use_threads = true
	
	# Connect signals to their handlers.
	_login_request.request_completed.connect(_on_login_request_completed)
	_register_request.request_completed.connect(_on_register_request_completed)
	_google_url_request.request_completed.connect(_on_google_url_request_completed)
	_google_poll_request.request_completed.connect(_on_google_poll_request_completed)
	_verify_token_request.request_completed.connect(_on_verify_token_request_completed)
	
	# Init timers
	_polling_timer = Timer.new()
	_timeout_timer = Timer.new()
	_polling_timer.name = "PollingTimer"
	_polling_timer.wait_time = POLLING_INTERVAL_SECONDS
	_polling_timer.one_shot = false
	_polling_timer.timeout.connect(_poll_for_status)
	_timeout_timer.name = "TimeoutTimer"
	_timeout_timer.wait_time = POLLING_TIMEOUT_SECONDS
	_timeout_timer.one_shot = true
	_timeout_timer.timeout.connect(_on_polling_timeout)
	add_child(_polling_timer)
	add_child(_timeout_timer)
	
	# Try to load a saved token on startup
	load_token()
	
func is_logged_in() -> bool:
	return auth_status == AuthStatus.LOGGED_IN

func get_jwt() -> String:
	return _jwt_token

# --- Public API ---

func login(email, password):
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"email": email, "password": password})
	var error = _login_request.request(SERVER_BASE_URL + "/auth/login", headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		emit_signal("login_failed", "An error occurred while trying to connect.")

func register(email, password, display_name):
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"email": email, "password": password, "displayName": display_name})
	var error = _register_request.request(SERVER_BASE_URL + "/auth/register", headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		emit_signal("registration_failed", "An error occurred while trying to connect.")

# Call this method from a UI button or on startup to begin the google login process.
func start_google_login():
	if _is_polling:
		print("Login flow is already in progress.")
		return

	print("Starting login flow...")
	# The previous script had a bug where it didn't disable redirects.
	# While not strictly necessary for this endpoint, it's good practice.
	# TODO: Double check the need for this
	_google_url_request.max_redirects = 0
	var error = _google_url_request.request(SERVER_BASE_URL + "/auth/google/url")
	if error != OK:
		print("Error initiating login request: %s" % error)
		emit_signal("google_login_failed", "Could not connect to the server.")

func _poll_for_status():
	if not _is_polling:
		return

	print("Polling for status with state: %s" % _google_login_state)
	var url = "%s/auth/status/%s" % [SERVER_BASE_URL, _google_login_state]
	_google_poll_request.request(url)

# --- Signal Handlers for HTTPRequest ---
func _on_login_request_completed(result, response_code, headers, body):
	var response_body_text = body.get_string_from_utf8()
	var response = JSON.parse_string(response_body_text)
	if response_code == 200 and response and response.has("token"):
		_jwt_token = response["token"]
		auth_status = AuthStatus.LOGGED_IN
		emit_signal("login_succeeded", _jwt_token)
	else:
		var error_message = "Invalid email or password."
		if not response_body_text.is_empty():
			error_message = response_body_text # The raw error from server
		emit_signal("login_failed", error_message)

func _on_register_request_completed(result, response_code, headers, body):
	var response_body_text = body.get_string_from_utf8()
	var response = JSON.parse_string(response_body_text)
	if response_code == 201 and response and response.has("token"):
		_jwt_token = response["token"]
		auth_status = AuthStatus.LOGGED_IN
		emit_signal("registration_succeeded", _jwt_token)
	else:
		var error_message = "Registration failed."
		if not response_body_text.is_empty():
			error_message = response_body_text
		emit_signal("registration_failed", error_message)

func _on_google_url_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("Failed to get auth URL. Code: %s" % response_code)
		emit_signal("google_login_failed", "The server did not provide a valid login URL.")
		return

	var json_result = JSON.parse_string(body.get_string_from_utf8())
	if not json_result or not json_result.has("url") or not json_result.has("state"):
		print("Invalid response from server when getting auth URL.")
		emit_signal("google_login_failed", "Received an invalid response from the server.")
		return
		
	# Got successful response
	_google_login_state = json_result["state"]
	print("Received auth URL. Opening in user's browser...")
	OS.shell_open(json_result["url"])

	# Start the polling process
	_is_polling = true
	_polling_timer.start()
	_timeout_timer.start()

	# Trigger the first poll immediately without waiting for the timer.
	_poll_for_status()

# Handle the response from the polling request
func _on_google_poll_request_completed(result, response_code, headers, body):
	if not _is_polling:
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		_stop_polling()
		emit_signal("google_login_failed", "A network error occurred while checking login status.")
		return

	match response_code:
		200: # Success! Login is complete.
			print("Login successful!")
			_stop_polling()
			var json_result = JSON.parse_string(body.get_string_from_utf8())
			if json_result and json_result.has("token"):
				print("Received session token.")
				_jwt_token = json_result["token"]
				auth_status = AuthStatus.LOGGED_IN
				save_token()
				emit_signal("google_login_succeeded", _jwt_token)
			else:
				emit_signal("google_login_failed", "Server reported success but did not provide a token.")
		
		202: # Accepted. The user has not finished logging in yet.
			print("Login is still pending... will poll again shortly.")
			# The timer will automatically fire again, so we do nothing here.
		
		_: # Any other code is a failure (404, 500, etc.).
			print("Login failed with status code: %s" % response_code)
			_stop_polling()
			emit_signal("google_login_failed", "Login failed or was cancelled by the user.")

# --- Token Storage and Encryption ---

func save_token():
	var file = FileAccess.open_encrypted_with_pass(TOKEN_SAVE_PATH, FileAccess.WRITE, ENCRYPTION_KEY)
	if file:
		file.store_var(_jwt_token)
		prints("Token saved securely.")

func _clear_saved_token():
	if FileAccess.file_exists(TOKEN_SAVE_PATH):
		DirAccess.remove_absolute(TOKEN_SAVE_PATH)
		prints("Cleared invalid token from disk.")

func load_token():
	if not FileAccess.file_exists(TOKEN_SAVE_PATH):
		auth_status = AuthStatus.NOT_LOGGED_IN
		return

	var file = FileAccess.open_encrypted_with_pass(TOKEN_SAVE_PATH, FileAccess.READ, ENCRYPTION_KEY)
	if file:
		_jwt_token = file.get_var()
		if not _jwt_token.is_empty():
			prints("Session token loaded from disk. Verifying with server...")
			auth_status = AuthStatus.VERIFYING
			# Verify the token is still valid with the server by making a call
			# to a protected endpoint like /api/me.
			var headers = get_auth_header()
			_verify_token_request.request(SERVER_BASE_URL + "/api/me", headers, HTTPClient.METHOD_GET)
		else:
			auth_status = AuthStatus.NOT_LOGGED_IN

func _on_verify_token_request_completed(result, response_code, headers, body):
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		prints("Token verification successful.")
		auth_status = AuthStatus.LOGGED_IN
		emit_signal("login_succeeded", _jwt_token)
	else:
		prints("Token verification failed. Response code: %s" % response_code)
		logout() # Clear token, status, and file
		emit_signal("login_failed", "Your session has expired. Please log in again.")

func logout():
	_jwt_token = ""
	auth_status = AuthStatus.NOT_LOGGED_IN
	_clear_saved_token()
	prints("Logged out and session cleared.")
	
# --- Making Authenticated Requests ---

# TODO: move this somewhere?
# A helper to make authenticated API calls.
# Returns the HTTPRequest node so the caller can connect to its 'request_completed' signal.
#func make_authenticated_request(endpoint: String, method: int = HTTPClient.METHOD_GET, body: String = "") -> HTTPRequest:
	#var request = HTTPRequest.new()
	#add_child(request) # The node must be in the scene tree to work
#
	#if not is_logged_in():
		#printerr("Cannot make authenticated request: not logged in.")
		## The caller should check the return value and handle this case.
		#return null
#
	#var url = SERVER_BASE_URL + endpoint
	#var headers = [
		#"Authorization: Bearer " + _jwt_token,
		#"Content-Type: application/json"
	#]
	#
	## The request node will be freed once the request is completed.
	#request.request_completed.connect(func(result, response_code, headers, body):
		#request.queue_free()
	#)
#
	#request.request(url, headers, method, body)
	#return request

func _on_polling_timeout():
	if _is_polling:
		print("Login flow timed out after %d seconds." % POLLING_TIMEOUT_SECONDS)
		_stop_polling()
		emit_signal("google_login_failed", "The login request timed out.")

# --- Helper Functions ---

func _stop_polling():
	if _is_polling:
		print("Stopping the polling process.")
		_is_polling = false
		_polling_timer.stop()
		_timeout_timer.stop()
		_google_login_state = ""

func get_auth_header() -> PackedStringArray:
	if _jwt_token.is_empty():
		return []
	return ["Authorization: Bearer " + _jwt_token]
