extends Node

static var instance: BluffClient

var http_request:HTTPRequest

const SERVER_BASE_URL = "http://127.0.0.1:8080"

func _ready():
	# This ensures we have a single, globally accessible instance.
	if instance != null:
		queue_free() # The singleton is already instanced, so destroy this new one.
		return
	instance = self
	
	# Create and add the HTTPRequest node as a child.
	# This ensures it's part of the scene tree and can process requests,
	# resolving the "Node not found" error for our AutoLoad singleton.
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	# Connect to the login signals from our LoginManager singleton to fetch config on login.
	LoginManager.login_succeeded.connect(fetch_config)
	LoginManager.google_login_succeeded.connect(fetch_config)

# This function will be our new way to make all authenticated API calls.
func make_request(endpoint: String, method: int = HTTPClient.METHOD_GET, body: String = ""):
	if not LoginManager.is_logged_in():
		printerr("BluffClient: Cannot make request, user is not logged in.")
		return

	# Get the standard "Authorization: Bearer <token>" header from our login manager.
	var headers = LoginManager.get_auth_header()
	# Add Content-Type for requests that have a body.
	if method == HTTPClient.METHOD_POST or method == HTTPClient.METHOD_PUT:
		headers.append("Content-Type: application/json")

	var url = SERVER_BASE_URL + endpoint
	# The HTTPRequest node must be connected to a callback to handle the response.
	# We will do this in the functions that call `make_request`.
	http_request.request(url, headers, method, body)

func fetch_config(_token = ""): # The token from the signal isn't needed here, but we accept it.
	http_request.request_completed.connect(_on_config_received, CONNECT_ONE_SHOT)
	make_request("/api/config") # IMPORTANT: Change this to your actual config endpoint!

func _on_config_received(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	print(json)
	Globals.set_image_base_url(json["images"]["base_url"])
