extends Node

# AudioServer takes bus volume values as float representing Db. It is recommended to keep Audible Db values between -60Db and 0Db.
# To make bus inaudible, values of -80Db to -60Db should be sufficient 
var master_volume_level : float:
	get : return master_volume_level
	set(volume) : 
		master_volume_level = volume
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume)
var sfx_volume_level : float:
	get : return sfx_volume_level
	set(volume) : 
		sfx_volume_level = volume
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SoundEffects"), volume)
var music_volume_level : float:
	get : return music_volume_level
	set(volume) : 
		music_volume_level = volume
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), volume)
