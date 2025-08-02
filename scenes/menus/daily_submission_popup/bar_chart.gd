@tool
extends Control

# This scene is responsible for generating a bar chart from a given dataset.
var placeholder_data = [{"steps":3, "count": 100}, {"steps": 4, "count": 20}, {"steps": 5, "count": 50}, {"steps": 6, "count": 75}, {"steps": 7, "count": 10}, {"steps": 8, "count": 60}]

@export var bar_scene: PackedScene
@export var use_placeholder_data: bool = false
@export var bar_count: int = 5:
	set(v):
		bar_count = max(0, v)
		rebuild_bars()

@onready var bars_container: HBoxContainer = %BarsContainer

func rebuild_bars():
	if not Engine.is_editor_hint():
		return
	populate_chart(placeholder_data)

# Use _ready() to set up the initial state when the scene is opened
func _ready() -> void:
	if Engine.is_editor_hint():
		rebuild_bars()

# Populates the chart with data.
# The data should be an array of dictionaries, each with "steps" and "count".
# e.g., [{"steps": 5, "count": 12}, {"steps": 6, "count": 25}]
func populate_chart(results_data: Array) -> void:
	if not Engine.is_editor_hint():
		return
	
	clear_bars()
	
	if results_data.is_empty():
		# TODO: Optionally show a "No data available" message.
		return
	
	# Find the highest player count to scale the other bars against.
	var max_count = 0
	for item in results_data:
		if item.count > max_count:
			max_count = item.count
	
	var owner_node = get_tree().edited_scene_root
	if owner_node == null:
		# This can happen if the script is not attached to a scene root
		# Or if the scene isn't saved yet
		return
	
	# Create and add a bar for each data point.
	for item in results_data:
		var bar = bar_scene.instantiate()
		var label_text = "%d Steps" % item.steps
		bar.name = "Bar_" + str(item.steps)
		bars_container.add_child(bar)
		bar.owner = owner_node
		if bar is Control:
			bar.set_data(item.count, max_count, label_text)

func clear_bars():
	# Clear any previous bars
	for child in bars_container.get_children():
		if child.name.begins_with("Bar"):
			child.queue_free()
