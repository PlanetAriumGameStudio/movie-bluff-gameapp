extends MarginContainer

class_name MiniPair

const image_format_string = "%s%s%s"

# Creating and deleting requestors here because you can't make more than one req at a time with a single req instance
func set_pair(pair:Pairing):
	print(Globals.PERSON_PROFILE_SIZES)
	print(Globals.MOVIE_POSTER_SIZES)
	var personReq = HTTPRequest.new()
	print("Setting Mini Pair Images: [Movie/Person]", pair.movie_poster_url, pair.person_profile_url)
	add_child(personReq)
	personReq.request_completed.connect(_update_person.bind(personReq), ConnectFlags.CONNECT_ONE_SHOT)
	var size = Globals.PERSON_PROFILE_SIZES[0]
	var err = personReq.request(image_format_string % [Globals.IMAGE_BASE_URL, size, pair.person_profile_url])
	if err != OK:
		push_error(err)
		
	var movieReq = HTTPRequest.new()
	add_child(movieReq)
	movieReq.request_completed.connect(_update_movie.bind(movieReq), ConnectFlags.CONNECT_ONE_SHOT)
	size = Globals.MOVIE_POSTER_SIZES[0]
	err = movieReq.request(image_format_string % [Globals.IMAGE_BASE_URL, size, pair.movie_poster_url])
	if err != OK:
		push_error(err)
		
func _update_person(result, response_code, headers, body, httpReq):
	%MiniPersonProfile.texture = _load_image_from_buffer(body)
	httpReq.queue_free()
	
func _update_movie(result, response_code, headers, body, httpReq):
	%MiniMoviePoster.texture = _load_image_from_buffer(body)
	httpReq.queue_free()
	
func _load_image_from_buffer(body) -> ImageTexture:
	var image = Image.new()
	var error = image.load_jpg_from_buffer(body)
	if error != OK:
		print(error)
		# Put generic filler in here
		return ImageTexture.new()
	else:
		return ImageTexture.new().create_from_image(image)
