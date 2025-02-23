class_name MiniOptionsMenu
extends Control

@onready var mute_control = %MuteControl
@onready var fullscreen_control = %FullscreenControl

@export var audio_control_scene : PackedScene

func _on_bus_changed(bus_value : float, bus_index : int):
	AppSettings.set_bus_volume(bus_index, bus_value)
	
func _add_audio_control(bus_name : String, bus_value : float, bus_index : int):
	if audio_control_scene == null:
		return
	var audio_control = audio_control_scene.instantiate()
	%AudioControlContainer.call_deferred("add_child", audio_control)
	if audio_control is OptionControl:
		audio_control.option_section = OptionControl.OptionSections.AUDIO
		audio_control.option_name = bus_name
		audio_control.value = bus_value
		audio_control.connect("setting_changed", _on_bus_changed.bind(bus_index))
		
func _add_audio_bus_controls():
	for bus_index in AudioServer.bus_count:
		var bus_name : String = AppSettings.get_audio_bus_name(bus_index)
		var linear : float = AppSettings.get_bus_volume(bus_index)
		_add_audio_control(bus_name, linear, bus_index)

func _update_ui():
	_add_audio_bus_controls()
	mute_control.value = AppSettings.is_muted()
	fullscreen_control.value = AppSettings.is_fullscreen(get_window())

func _sync_with_config():
	_update_ui()
	
func _ready() -> void:
	_sync_with_config()

func _on_mute_control_setting_changed(value):
	AppSettings.set_mute(value)
	
func _on_fullscreen_control_setting_changed(value):
	AppSettings.set_fullscreen_enabled(value, get_window())
