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

	# Use the existing HTTPRequest node in the scene.
	var image_requester = %HTTPRequest
	image_requester.request_completed.connect(_on_image_request_completed, CONNECT_ONE_SHOT)
	var err = image_requester.request(full_image_url)
	if err != OK:
		printerr("PairEntry: Image request failed to start. Error: ", err)
		# Disconnect the one-shot signal if the request fails to start, to prevent memory leaks.
		image_requester.request_completed.disconnect(_on_image_request_completed)

func _on_image_request_completed(result, response_code, _headers, body):
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		%PairImage.texture = ImageUtils.texture_from_jpg_buffer(body)
	else:
		printerr("PairEntry: Failed to download image. Result: %s, Code: %s" % [result, response_code])
		%PairImage.texture = null # Clear texture on failure

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

	# Determine the border width based on the active state. This is more concise.
	var border_width = 4 if is_active else 0

	# Apply all properties in a single block.
	stylebox_override.border_width_left = border_width
	stylebox_override.border_width_top = border_width
	stylebox_override.border_width_right = border_width
	stylebox_override.border_width_bottom = border_width

	stylebox_override.content_margin_left = border_width
	stylebox_override.content_margin_top = border_width
	stylebox_override.content_margin_right = border_width
	stylebox_override.content_margin_bottom = border_width

	stylebox_override.border_color = Color("ffd400") # Golden yellow
