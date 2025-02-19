extends PanelContainer

@onready var master_volume_slider : HSlider = $MarginContainer/VBoxContainer/MasterVolumeSlider
@onready var music_volume_slider : HSlider = $MarginContainer/VBoxContainer/MusicVolumeSlider
@onready var sfx_volume_slider : HSlider = $MarginContainer/VBoxContainer/SfxVolumeSlider

func _ready() -> void:
	master_volume_slider.value = AudioManager.master_volume_level
	sfx_volume_slider.value = AudioManager.sfx_volume_level
	music_volume_slider.value = AudioManager.music_volume_level

func _on_master_volume_slider_value_changed(value: float) -> void:
	AudioManager.master_volume_level = value

func _on_sfx_volume_slider_value_changed(value: float) -> void:
	AudioManager.sfx_volume_level = value

func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioManager.music_volume_level = value

func _on_confirm_button_pressed() -> void:
	queue_free()
