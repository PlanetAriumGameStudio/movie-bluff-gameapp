class_name AppSettings
extends Node

const AUDIO_SECTION = &'AudioSettings'
const VIDEO_SECTION = &'VideoSettings'

const FULLSCREEN_ENABLED = &'FullscreenEnabled'
const SCREEN_RESOLUTION = &'ScreenResolution'
const MASTER_BUS_INDEX = 0
const MUTE_SETTING_KEY = &'Mute' 

# Volume Options

static func get_bus_volume(bus_index : int) -> float:
	var initial_linear = 1.0
	var linear = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	return linear
	
static func set_bus_volume(bus_index : int, linear : float) -> void:
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear)) 

static func set_mute(mute_flag : bool) -> void:
	return AudioServer.set_bus_mute(MASTER_BUS_INDEX, mute_flag)

static func is_muted() -> bool:
	return AudioServer.is_bus_mute(MASTER_BUS_INDEX)
	
static func get_audio_bus_name(bus_index : int) -> String:
	return AudioServer.get_bus_name(bus_index)

static func set_audio_from_config():
	print("Setting audio")
	for bus_index in AudioServer.bus_count:
		var bus_name : String = AudioServer.get_bus_name(bus_index)
		var bus_volume : float = get_bus_volume(bus_index)
		bus_volume = Config.get_config(AUDIO_SECTION, bus_name, bus_volume)
		if is_nan(bus_volume):
			bus_volume = 1.0
			Config.set_config(AUDIO_SECTION, bus_name, bus_volume)
		set_bus_volume(bus_index, bus_volume)
	var mute_audio_flag : bool = is_muted()
	mute_audio_flag = Config.get_config(AUDIO_SECTION, MUTE_SETTING_KEY, mute_audio_flag)
	set_mute(mute_audio_flag)

# Video

static func set_fullscreen_enabled(value : bool, window : Window) -> void:
	window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (value) else Window.MODE_WINDOWED

static func set_resolution(value : Vector2i, window: Window) -> void:
	if value.x == 0 or value.y == 0:
		return
	window.size = value

static func is_fullscreen(window : Window) -> bool:
	return (window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (window.mode == Window.MODE_FULLSCREEN) 

static func get_resolution(window : Window) -> Vector2i:
	var current_resolution : Vector2i = window.size
	return Config.get_config(VIDEO_SECTION, SCREEN_RESOLUTION, current_resolution)

static func set_video_from_config(window : Window) -> void:
	var fullscreen_enabled : bool = is_fullscreen(window)
	fullscreen_enabled = Config.get_config(VIDEO_SECTION, FULLSCREEN_ENABLED, fullscreen_enabled)
	set_fullscreen_enabled(fullscreen_enabled, window)
	if not (fullscreen_enabled or OS.has_feature("web")):
		var current_resolution : Vector2i = get_resolution(window)
		set_resolution(current_resolution, window)

# Setup

static func set_from_config() -> void:
	set_audio_from_config()
	
static func set_from_config_and_window(window : Window) -> void:
	set_from_config()
	set_video_from_config(window)
