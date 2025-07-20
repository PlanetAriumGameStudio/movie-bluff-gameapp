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

func set_highlight_active(is_active: bool):
	var panel: PanelContainer = %PairImageMargin
	var stylebox_override: StyleBoxFlat

	# Check if an override already exists. If so, we can safely get it.
	if panel.has_theme_stylebox_override("panel"):
		stylebox_override = panel.get_theme_stylebox("panel")
	else:
		# If no override exists, create one by duplicating the base theme stylebox.
		# This ensures each instance has a unique style to modify.
		var base_stylebox = panel.get_theme_stylebox("panel")
		if not base_stylebox is StyleBoxFlat:
			push_warning("PairImageMargin's panel stylebox is not a StyleBoxFlat.")
			return
		stylebox_override = base_stylebox.duplicate()
		panel.add_theme_stylebox_override("panel", stylebox_override)

	if is_active:
		var border_width = 4
		stylebox_override.border_width_left = border_width
		stylebox_override.border_width_top = border_width
		stylebox_override.border_width_right = border_width
		stylebox_override.border_width_bottom = border_width
		stylebox_override.border_color = Color("ffd400") # Golden yellow
		# This is the crucial part: add padding so the border is visible around the content.
		stylebox_override.content_margin_left = border_width
		stylebox_override.content_margin_top = border_width
		stylebox_override.content_margin_right = border_width
		stylebox_override.content_margin_bottom = border_width
	else:
		# Set border width to 0 to hide it.
		stylebox_override.border_width_left = 0
		stylebox_override.border_width_top = 0
		stylebox_override.border_width_right = 0
		stylebox_override.border_width_bottom = 0
		# Also reset the content margin so the layout returns to normal.
		stylebox_override.content_margin_left = 0
		stylebox_override.content_margin_top = 0
		stylebox_override.content_margin_right = 0
		stylebox_override.content_margin_bottom = 0
