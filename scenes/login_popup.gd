extends PanelContainer

@export_file("*.tscn") var main_menu_scene_path : String
# --- UI Node References ---
# In the Godot editor, connect these to their respective nodes.
@onready var login_email_input = %LoginEmail
@onready var login_password_input = %LoginPassword
@onready var register_email_input = %RegisterEmail
@onready var register_display_name_input = %RegisterDisplayName
@onready var register_password_input = %RegisterPassword
@onready var error_label = %ErrorLabel

func _ready():
	# Hide the popup by default. The WelcomeScreen will show it.
	hide()
	
	# Connect to the global LoginManager's signals. This popup will now react
	# to authentication events from anywhere in the app.
	LoginManager.login_succeeded.connect(_on_auth_succeeded)
	LoginManager.login_failed.connect(_on_auth_failed)
	LoginManager.registration_succeeded.connect(_on_auth_succeeded)
	LoginManager.registration_failed.connect(_on_auth_failed)
	LoginManager.google_login_succeeded.connect(_on_auth_succeeded)
	LoginManager.google_login_failed.connect(_on_auth_failed)

# --- Public Methods ---

func show_popup():
	show()
	error_label.text = "" # Clear any previous errors on show

# --- Signal Handlers for UI Elements ---
# Connect the `pressed()` signal of each button to these functions in the editor.

func _on_login_button_pressed():
	var email = login_email_input.text
	var password = login_password_input.text
	if email.is_empty() or password.is_empty():
		_on_auth_failed("Email and password cannot be empty.")
		return
	error_label.text = "Logging in..."
	LoginManager.login(email, password)

func _on_register_button_pressed():
	var email = register_email_input.text
	var display_name = register_display_name_input.text
	var password = register_password_input.text
	
	# You can add more robust client-side validation here
	if not email.is_valid_email_address() or display_name.is_empty() or password.length() < 8:
		_on_auth_failed("Please fill all fields correctly (password > 8 chars).")
		return
		
	error_label.text = "Creating account..."
	LoginManager.register(email, password, display_name)

func _on_google_login_button_pressed():
	error_label.text = "Opening browser for Google login..."
	LoginManager.start_google_login()

# --- Signal Handlers for LoginManager ---

func _on_auth_succeeded(token: String):
	print("Authentication successful! You can now proceed.")
	TransitionManager.change_scene(main_menu_scene_path, 1)
	hide() # Hide the login popup on success

func _on_auth_failed(error_message: String):
	error_label.text = "Error: " + error_message
	print("Authentication failed: ", error_message)
