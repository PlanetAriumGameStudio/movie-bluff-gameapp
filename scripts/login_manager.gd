extends Node

# Emitted when the login flow completes, successfully or not.
signal login_succeeded(session_token)
signal login_failed(error_message)

# --- Configuration ---
const SERVER_BASE_URL = "http://localhost:8080"
const POLLING_INTERVAL_SECONDS = 2.0 # Poll every 2 seconds
const POLLING_TIMEOUT_SECONDS = 300  # 5 minutes, should match server's state expiration

# --- Internal State ---
var _state: String = ""
var _is_polling: bool = false

# --- Node References ---
var _initial_request: HTTPRequest
var _polling_request: HTTPRequest
var _polling_timer: Timer
var _timeout_timer: Timer

func _ready():
	# Create nodes programmatically for better encapsulation.
	_initial_request = HTTPRequest.new()
	_polling_request = HTTPRequest.new()
	_polling_timer = Timer.new()
	_timeout_timer = Timer.new()

	# It's good practice to name nodes for easier debugging if needed.
	_initial_request.name = "InitialAuthRequest"
	_polling_request.name = "PollingAuthRequest"
	_polling_timer.name = "PollingTimer"
	_timeout_timer.name = "TimeoutTimer"

	add_child(_initial_request)
	add_child(_polling_request)
	add_child(_polling_timer)
	add_child(_timeout_timer)

	# Connect signals to their handlers.
	_initial_request.request_completed.connect(_on_initial_request_completed)
	_polling_request.request_completed.connect(_on_polling_request_completed)
	_polling_timer.timeout.connect(_poll_for_status)
	_timeout_timer.timeout.connect(_on_polling_timeout)

# --- Public API ---

# Call this method from a UI button or on startup to begin the login process.
func start_login_flow():
	if _is_polling:
		print("Login flow is already in progress.")
		return

	print("Starting login flow...")
	var url = SERVER_BASE_URL + "/auth/google/url"
	
	# The previous script had a bug where it didn't disable redirects.
	# While not strictly necessary for this endpoint, it's good practice.
	_initial_request.max_redirects = 0
	
	var error = _initial_request.request(url)
	if error != OK:
		print("Error initiating login request: %s" % error)
		emit_signal("login_failed", "Could not connect to the server.")

# --- Signal Handlers ---

# Step 1: Handle the response from /auth/google/url
func _on_initial_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("Failed to get auth URL. Code: %s" % response_code)
		emit_signal("login_failed", "The server did not provide a valid login URL.")
		return

	var json_result = JSON.parse_string(body.get_string_from_utf8())
	if not json_result or not json_result.has("url") or not json_result.has("state"):
		print("Invalid response from server when getting auth URL.")
		emit_signal("login_failed", "Received an invalid response from the server.")
		return

	var auth_url = json_result["url"]
	_state = json_result["state"]

	print("Received auth URL. Opening in user's browser...")
	OS.shell_open(auth_url)

	# Step 2: Start the polling process
	_is_polling = true
	_polling_timer.wait_time = POLLING_INTERVAL_SECONDS
	_polling_timer.start()
	
	_timeout_timer.wait_time = POLLING_TIMEOUT_SECONDS
	_timeout_timer.start()

	# Trigger the first poll immediately without waiting for the timer.
	_poll_for_status()


# Step 3: Poll the /auth/status/{state} endpoint
func _poll_for_status():
	if not _is_polling:
		return

	print("Polling for status with state: %s" % _state)
	var url = "%s/auth/status/%s" % [SERVER_BASE_URL, _state]
	_polling_request.request(url)


# Step 4: Handle the response from the polling request
func _on_polling_request_completed(result, response_code, headers, body):
	if not _is_polling:
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		_stop_polling()
		emit_signal("login_failed", "A network error occurred while checking login status.")
		return

	match response_code:
		200: # Success! Login is complete.
			print("Login successful!")
			_stop_polling()
			var json_result = JSON.parse_string(body.get_string_from_utf8())
			if json_result and json_result.has("token"):
				var session_token = json_result["token"]
				print("Received session token.")
				emit_signal("login_succeeded", session_token)
			else:
				emit_signal("login_failed", "Server reported success but did not provide a token.")
		
		202: # Accepted. The user has not finished logging in yet.
			print("Login is still pending... will poll again shortly.")
			# The timer will automatically fire again, so we do nothing here.
		
		_: # Any other code is a failure (404, 500, etc.).
			print("Login failed with status code: %s" % response_code)
			_stop_polling()
			emit_signal("login_failed", "Login failed or was cancelled by the user.")


func _on_polling_timeout():
	if _is_polling:
		print("Login flow timed out after %d seconds." % POLLING_TIMEOUT_SECONDS)
		_stop_polling()
		emit_signal("login_failed", "The login request timed out.")

# --- Helper Functions ---

func _stop_polling():
	if _is_polling:
		print("Stopping the polling process.")
		_is_polling = false
		_polling_timer.stop()
		_timeout_timer.stop()
		_state = ""


func _on_login_button_pressed() -> void:
	pass # Replace with function body.
