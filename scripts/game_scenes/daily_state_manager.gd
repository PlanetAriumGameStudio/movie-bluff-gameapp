extends Node

class_name DailyStateManager

### [STATE TRACKING]
enum {INIT_STATE, PLAYING_STATE, COMPLETION_STATE}
var current_state = INIT_STATE

enum {START_TO_FINISH, FINISH_TO_START}
var current_direction = START_TO_FINISH

enum CHANGE_TYPES {NONE, MOVIE, PERSON}
var last_change:CHANGE_TYPES
var change_labels_dict = {
	CHANGE_TYPES.NONE: "Select Next Change",
	CHANGE_TYPES.MOVIE: "Changing: Person",
	CHANGE_TYPES.PERSON: "Changing: Movie",
}

var current_pairing:Pairing

# Tracks game completion state. will be updated once per submission.
var path_complete:bool

var path_from_start: Array[Pairing]
var path_from_finish: Array[Pairing]

func _ready() -> void:
	return
