extends Node

# A utility function to safely load a JPG from a buffer and return a texture.
# Returns an empty ImageTexture on failure.
static func texture_from_jpg_buffer(buffer: PackedByteArray) -> ImageTexture:
	var image = Image.new()
	var error = image.load_jpg_from_buffer(buffer)
	if error != OK:
		printerr("ImageUtils: Failed to load JPG from buffer. Error code: ", error)
		# Return a placeholder or empty texture
		return ImageTexture.new()
	else:
		return ImageTexture.create_from_image(image)

# Constructs a full image URL for a movie poster.
static func get_movie_poster_url(path: String, size_index: int = 2) -> String:
	if not "MOVIE_POSTER_SIZES" in Globals or size_index < 0 or size_index >= len(Globals.MOVIE_POSTER_SIZES):
		printerr("ImageUtils: Invalid or missing movie poster size settings. Index: ", size_index)
		return "" # Return empty string on failure
	var size = Globals.MOVIE_POSTER_SIZES[size_index]
	return "%s%s%s" % [Globals.IMAGE_BASE_URL, size, path]

# Constructs a full image URL for a person's profile picture.
static func get_person_profile_url(path: String, size_index: int = 2) -> String:
	if not "PERSON_PROFILE_SIZES" in Globals or size_index < 0 or size_index >= len(Globals.PERSON_PROFILE_SIZES):
		printerr("ImageUtils: Invalid or missing person profile size settings. Index: ", size_index)
		return "" # Return empty string on failure
	var size = Globals.PERSON_PROFILE_SIZES[size_index]
	return "%s%s%s" % [Globals.IMAGE_BASE_URL, size, path]
