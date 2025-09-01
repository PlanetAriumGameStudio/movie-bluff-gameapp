extends Control
class_name ChangeTypeToggle

enum ChangeType { PERSON, MOVIE }

signal change_type_changed(type: ChangeType)

@onready var movie_button: TextureButton = %MovieButton
@onready var person_button: TextureButton = %PersonButton

var current_type: ChangeType = ChangeType.MOVIE:
	set(value):
		if current_type == value:
			return
		current_type = value
		emit_signal("change_type_changed", current_type)
		_update_visuals()

func _ready() -> void:
	movie_button.pressed.connect(_on_movie_button_pressed)
	person_button.pressed.connect(_on_person_button_pressed)
	_update_visuals()

func _on_movie_button_pressed() -> void:
	self.current_type = ChangeType.MOVIE

func _on_person_button_pressed() -> void:
	self.current_type = ChangeType.PERSON

func _update_visuals() -> void:
	match current_type:
		ChangeType.MOVIE:
			movie_button.modulate = Color(1, 1, 1, 1)
			person_button.modulate = Color(1, 1, 1, 0.5)
		ChangeType.PERSON:
			person_button.modulate = Color(1, 1, 1, 1)
			movie_button.modulate = Color(1, 1, 1, 0.5)

func get_current_change_type() -> ChangeType:
	return current_type
