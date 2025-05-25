extends Control

class_name PairEntry

const image_format_string = "%s%s%s"

@onready var bluffAPIReq = $HTTPRequest

@export_enum("Movie", "Person") var type:String = "Movie"

func update_pair(label_text:String, image_url:String):
	print("Updating Pair")
	# Make request to fetch image
	bluffAPIReq.request_completed.connect(_update_pairing, ConnectFlags.CONNECT_ONE_SHOT)
	var size
	if type == "Movie":
		size = Globals.MOVIE_POSTER_SIZES[2]
	else:
		size = Globals.PERSON_PROFILE_SIZES[2]
	var err = bluffAPIReq.request(image_format_string % [Globals.IMAGE_BASE_URL, size, image_url])
	if err != OK:
		push_error(err)
	
	#Update label text
	%PairLabel.text = label_text

func _update_pairing(result, response_code, headers, body):
	%PairImage.texture = _load_image_from_buffer(body)
	
func _load_image_from_buffer(body) -> ImageTexture:
	var image = Image.new()
	var error = image.load_jpg_from_buffer(body)
	if error != OK:
		print(error)
		# Put generic filler in here
		return ImageTexture.new()
	else:
		return ImageTexture.new().create_from_image(image)
