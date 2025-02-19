extends Node

# AudioServer takes bus volume values as float representing Db. It is recommended to keep Audible Db values between -60Db and 0Db.
# To make bus inaudible, values of -80Db to -60Db should be sufficient
# Volume will typically be passed in here from a HSlider that has a range from [0,100]
const MIN_DB : float = -80.0
const MAX_DB : float = 0.0
const MIN_SLIDER : float = 0.0
const MAX_SLIDER : float = 100.0
 
var master_bus : 
	get: AudioServer.get_bus_index("Master")
var master_volume_level : float:
	get : return _linear_translate_db_to_slider(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	set(volume) : AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), _linear_translate_slider_to_db(volume))
var sfx_volume_level : float:
	get : return _linear_translate_db_to_slider(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SoundEffects")))
	set(volume) : AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SoundEffects"), _linear_translate_slider_to_db(volume))
var music_volume_level : float:
	get : return _linear_translate_db_to_slider(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	set(volume) : AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _linear_translate_slider_to_db(volume))

func _linear_translate_slider_to_db(volume : float) -> float : 
	return clampf(((volume - MIN_SLIDER) * (MAX_DB - MIN_DB)) / (MAX_SLIDER - MIN_SLIDER) + MIN_DB, MIN_DB, MAX_DB) 

func _linear_translate_db_to_slider(volume : float) -> float :
	return clampf(((volume - MIN_DB) * (MAX_SLIDER - MIN_SLIDER)) / (MAX_DB - MIN_DB) + MIN_SLIDER, MIN_SLIDER, MAX_SLIDER) 
