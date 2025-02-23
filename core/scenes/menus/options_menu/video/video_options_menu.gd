class_name VideoOptionsMenu
extends Control

func _update_ui(window : Window):
	%FullscreenControl.value = AppSettings.is_fullscreen(window)

func _ready():
	var window : Window = get_window()
	_update_ui(window)
	
func _on_fullscreen_control_setting_changed(value):
	var window : Window = get_window()
	AppSettings.set_fullscreen_enabled(value, window)
	
