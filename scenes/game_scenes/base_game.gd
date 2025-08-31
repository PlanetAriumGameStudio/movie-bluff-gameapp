extends Control
class_name BaseGame
# Base class for all game modes (Daily, Competitive, etc.)
# This script will manage the common UI elements and provide a common interface
# for the specific game mode scripts.

### [STATE TRACKING]
enum State {INIT, WAITING_FOR_OPPONENT, PLAYING, SUBMITTING, COMPLETED}
var current_state: State

enum ChangeTypes {NONE, MOVIE, PERSON}
var last_change:ChangeTypes

# --- Signals ---
signal back_button_pressed
# TODO: Make settings pop up menu at some point to hook up here
signal settings_button_pressed

# --- UI Nodes ---
@onready var header: PanelContainer = %Header
@onready var body: MarginContainer = %Body
@onready var footer: PanelContainer = %Footer

# --- Heading / Navigation
@onready var header_back_button: Button = %HeaderBackButton
@onready var title_label: Label = %TitleLabel

# --- Footer / Controls
@onready var submission_input: LineEdit = %SubmissionInput
@onready var submit_button: Button = %SubmitButton
@onready var change_type_toggle_button: Button = %ChangeTypeToggleButton
@onready var change_direction_button: Button = %ChangeDirectionButton

# --- Popup 
@onready var game_completion_popup: PopupPanel = %GameCompletionPopup
@onready var completion_back_button: Button = %CompletionBackButton

func _ready() -> void:
	header_back_button.pressed.connect(_on_back_button_pressed)
	completion_back_button.pressed.connect(_on_back_button_pressed)
	# The specific game modes will be responsible for connecting to the other buttons
	# and implementing their own logic.
	
	# Virtual method to be overridden by child scenes
	_initialize_game()

# --- Virtual Methods ---

func _initialize_game() -> void:
	# This method should be overridden by the specific game mode scripts
	# to set up the game state, connect to API signals, etc.
	pass

# --- Public Methods ---

func set_title(title: String) -> void:
	title_label.text = title

func show_loading_spinner() -> void:
	# TODO: Implement a loading spinner
	pass

func hide_loading_spinner() -> void:
	# TODO: Implement a loading spinner
	pass

# --- State Machine ---

func set_state(new_state: State) -> void:
	if current_state == new_state and current_state != State.INIT:
		return

	# Exit logic for the current state
	match current_state:
		State.WAITING_FOR_OPPONENT:
			_exit_waiting_for_opponent()
		State.PLAYING:
			_exit_playing()
		State.SUBMITTING:
			_exit_submitting()
		State.COMPLETED:
			_exit_completed()
	current_state = new_state

	# Enter logic for the new state
	match current_state:
		State.INIT:
			_enter_init()
		State.WAITING_FOR_OPPONENT:
			_enter_waiting_for_opponent()
		State.PLAYING:
			_enter_playing()
		State.SUBMITTING:
			_enter_submitting()
		State.COMPLETED:
			_enter_completed()

# --- State Enter/Exit Logic ---
# These methods should be overridden by the specific game mode scripts
# to handle state.

func _enter_init():
	print("Entering INIT state")
	# This method should be overridden by the specific game mode scripts
	# to handle state.
	pass

func _enter_waiting_for_opponent():
	print("Entering WAITING_FOR_OPPONENT state")
	pass

func _exit_waiting_for_opponent():
	print("Exiting WAITING_FOR_OPPONENT state")

func _enter_playing():
	print("Entering PLAYING state")
	# This method should be overridden by the specific game mode scripts
	# to handle state.
	pass

func _exit_playing():
	print("Exiting PLAYING state")
	# This method should be overridden by the specific game mode scripts
	# to handle state.
	pass

func _enter_submitting():
	print("Entering SUBMITTING state")
	show_loading_spinner()
	pass

func _exit_submitting():
	print("Exiting SUBMITTING state")
	hide_loading_spinner()
	pass


func _enter_completed():
	print("Entering COMPLETED state")
	game_completion_popup.popup()

func _exit_completed():
	print("Exiting COMPLETED state")
	# This method should be overridden by the specific game mode scripts
	# to handle state.
	pass

# --- UI Event Handlers ---

func _on_back_button_pressed() -> void:
	emit_signal("back_button_pressed")
	TransitionManager.change_scene("res://scenes/menus/main_menu/main_menu.tscn", 1)
