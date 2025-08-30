extends Control
class_name BaseGame
# Base class for all game modes (Daily, Competitive, etc.)
# This script will manage the common UI elements and provide a common interface
# for the specific game mode scripts.

# --- Signals ---
signal back_button_pressed
signal settings_button_pressed

# --- UI Nodes ---
@onready var header: PanelContainer = %Header
@onready var body: MarginContainer = %Body
@onready var footer: PanelContainer = %Footer

@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel

@onready var starting_pair: Control = %StartingPair
@onready var finishing_pair: Control = %FinishingPair

@onready var path_container: HBoxContainer = %PathContainer
@onready var submission_input: LineEdit = %SubmissionInput
@onready var submit_button: Button = %SubmitButton
@onready var change_type_toggle_button: Button = %ChangeTypeToggleButton
@onready var change_direction_button: Button = %ChangeDirectionButton
@onready var game_completion_popup: PopupPanel = %GameCompletionPopup
@onready var daily_path: Control = %DailyPath




func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
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

# --- UI Event Handlers ---

func _on_back_button_pressed() -> void:
	emit_signal("back_button_pressed")
	# Default behavior is to go to the main menu.
	# This can be overridden in the child scenes if needed.
	TransitionManager.change_scene("res://scenes/menus/main_menu/main_menu.tscn", 1)
