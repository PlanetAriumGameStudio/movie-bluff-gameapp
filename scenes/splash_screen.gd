extends Control

@onready var login_popup = $LoginPopup # Assign the LoginPopup node in the editor

func _on_show_login_button_pressed():
	login_popup.show_popup()
