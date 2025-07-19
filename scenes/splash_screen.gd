extends Control

@onready var login_popup = %LoginPopup
@onready var show_login_button = %ShowLoginButton

func _ready():
	LoginManager.login_succeeded.connect(_on_auto_login_succeeded)
	LoginManager.login_failed.connect(_on_auto_login_failed)

	# Check the initial authentication status from the LoginManager.
	match LoginManager.auth_status:
		LoginManager.AuthStatus.LOGGED_IN:
			# This case is unlikely but safe to handle: verification was so fast
			# it finished before this scene's _ready() function was called.
			_on_auto_login_succeeded("") # Pass a dummy token string.
		
		LoginManager.AuthStatus.VERIFYING:
			# A token was found and is being verified with the server.
			# Hide the login button to prevent user interaction during this process.
			print("Verifying existing session...")
			if show_login_button:
				show_login_button.hide()
		
		LoginManager.AuthStatus.NOT_LOGGED_IN:
			# No token was found, so auto-login will not occur.
			# We can disconnect the signals immediately.
			_disconnect_auto_login_signals()

func _on_auto_login_succeeded(_token: String):
	_disconnect_auto_login_signals()
	print("Auto-login successful. Transitioning to main menu.")
	_transition_to_main_menu()

func _on_auto_login_failed(_error_message: String):
	_disconnect_auto_login_signals()
	print("Auto-login failed. Token may be expired or invalid.")
	# Show the login button again so the user can log in manually.
	if show_login_button:
		show_login_button.show()

func _disconnect_auto_login_signals():
	if LoginManager.login_succeeded.is_connected(_on_auto_login_succeeded):
		LoginManager.login_succeeded.disconnect(_on_auto_login_succeeded)
	if LoginManager.login_failed.is_connected(_on_auto_login_failed):
		LoginManager.login_failed.disconnect(_on_auto_login_failed)

func _transition_to_main_menu():
	var main_menu_path = login_popup.main_menu_scene_path
	if main_menu_path.is_empty():
		printerr("SplashScreen: main_menu_scene_path is not set on the LoginPopup node! Cannot transition automatically.")
		return
	TransitionManager.change_scene.call_deferred(main_menu_path, 1)

func _on_show_login_button_pressed():
	login_popup.show_popup()
