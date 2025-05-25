extends MainMenu

@onready var httpReq:HTTPRequest = $HTTPRequest

const config_api_format_string = "%s:%s/config"

func _ready():
	httpReq.request_completed.connect(_get_config, ConnectFlags.CONNECT_ONE_SHOT)
	print(config_api_format_string % [Globals.BLUFF_API_BASE_ADDRESS, Globals.BLUFF_API_PORT])
	var err = httpReq.request(config_api_format_string % [Globals.BLUFF_API_BASE_ADDRESS, Globals.BLUFF_API_PORT])
	if err != OK:
		push_error(err)

func _get_config(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	print(type_string(typeof(json["images"]["poster_sizes"])))
	Globals.set_movie_poster_sizes(json["images"]["poster_sizes"])
	Globals.set_person_profile_sizes(json["images"]["profile_sizes"])
	Globals.set_image_base_url(json["images"]["base_url"])
	print("Config from API set")
