class_name Config
extends Object

const CONFIG_LOCATION : String = "user://config.cfg"

static var config_file : ConfigFile

static func _init():
	load_config()
	
static func _save_config() -> void: 
	var err := config_file.save(CONFIG_LOCATION)
	if err:
		push_error("save config failed with error %d" % err)
		
static func load_config() -> void:
	if config_file != null:
		return
	config_file = ConfigFile.new()
	var err := config_file.load(CONFIG_LOCATION)
	if err == Error.ERR_FILE_NOT_FOUND:
		_save_config()
	elif err:
		push_error("load config failed with error %d" % err)

# Convienience methods for fetching and manipulating config values

static func set_config(section: String, key: String, value) -> void:
	load_config()
	config_file.set_value(section, key, value)
	_save_config()

static func get_config(section: String, key: String, default = null) -> Variant:
	load_config()
	return config_file.get_value(section, key, default)
	
