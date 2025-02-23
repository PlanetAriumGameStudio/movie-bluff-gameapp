extends AudioOptionsMenu

#@onready var master_volume_slider : HSlider = $MarginContainer/VBoxContainer/MasterVolumeSlider
#@onready var music_volume_slider : HSlider = $MarginContainer/VBoxContainer/MusicVolumeSlider
#@onready var sfx_volume_slider : HSlider = $MarginContainer/VBoxContainer/SfxVolumeSlider
#
#func _ready() -> void:
	#master_volume_slider.value = AppSettings.get_bus_volume(0) * 100.0
	#sfx_volume_slider.value = AppSettings.get_bus_volume(1) * 100.0
	#music_volume_slider.value = AppSettings.get_bus_volume(2) * 100.0
#
#func _on_master_volume_slider_value_changed(value: float) -> void:
	#AppSettings.set_bus_volume(0, value / 100.0)
#
#func _on_sfx_volume_slider_value_changed(value: float) -> void:
	#AppSettings.set_bus_volume(1, value / 100.0)
#
#func _on_music_volume_slider_value_changed(value: float) -> void:
	#AppSettings.set_bus_volume(2, value / 100.0)
#
#func _on_confirm_button_pressed() -> void:
	#queue_free()
