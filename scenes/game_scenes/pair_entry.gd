extends Control

class_name PairEntry

@export_enum("Movie", "Person") var type:String = "Movie"

func update_pair(label_text:String, image_path:String):
	print("Updating Pair: ", label_text)
	
	# Update label text immediately
	%PairLabel.text = label_text
	
	# Construct the full URL using our new utility
	var full_image_url: String
	if type == "Movie":
		full_image_url = ImageUtils.get_movie_poster_url(image_path)
	else:
		full_image_url = ImageUtils.get_person_profile_url(image_path)

	if full_image_url.is_empty():
		printerr("PairEntry: Could not get a valid image URL for path: ", image_path)
		%PairImage.texture = null # Clear texture on failure
		return

	# Create a temporary HTTPRequest node to fetch the image
	var image_requester = HTTPRequest.new()
	add_child(image_requester) # Must be in the tree to make requests
	
	# Make request to fetch image. Bind the requester so we can free it later.
	image_requester.request_completed.connect(_on_image_request_completed.bind(image_requester), CONNECT_ONE_SHOT)
	var err = image_requester.request(full_image_url)
	if err != OK:
		printerr("PairEntry: Image request failed to start. Error: ", err)
		image_requester.queue_free() # Clean up on failure

func _on_image_request_completed(result, response_code, _headers, body, requester):
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		%PairImage.texture = ImageUtils.texture_from_jpg_buffer(body)
	else:
		printerr("PairEntry: Failed to download image. Result: %s, Code: %s" % [result, response_code])
		%PairImage.texture = null # Clear texture on failure
	
	# Clean up the temporary request node
	requester.queue_free()
