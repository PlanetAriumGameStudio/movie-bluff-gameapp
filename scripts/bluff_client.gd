extends Node

class_name BluffClient

@onready var bluffClient:HTTPRequest = $HTTPRequest

func _ready():
	# Initialize connection to Bluff API server and get 
	print(bluffClient)
	bluffClient.request_completed.connect(_get_config, CONNECT_ONE_SHOT)

func _get_config(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	Globals.set_image_base_url(json["images"]["base_url"])

func _find_image(result, response_code, headers, body) -> ImageTexture:
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		print(error)
		return ImageTexture.new()
	else:
		return ImageTexture.new().create_from_image(image)
