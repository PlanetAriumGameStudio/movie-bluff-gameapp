extends Control

# This scene is responsible for generating a bar chart from a given dataset.

@export var bar_scene: PackedScene

@onready var bars_container: HBoxContainer = %BarsContainer

# Populates the chart with data.
# The data should be an array of dictionaries, each with "steps" and "count".
# e.g., [{"steps": 5, "count": 12}, {"steps": 6, "count": 25}]
func populate_chart(results_data: Array) -> void:
	# First, clear any bars that might already exist.
	for child in bars_container.get_children():
		child.queue_free()

	if results_data.is_empty():
		# TODO: Optionally show a "No data available" message.
		return

	# Find the highest player count to scale the other bars against.
	var max_count = 0
	for item in results_data:
		if item.count > max_count:
			max_count = item.count

	# Sort the data by the number of steps in ascending order.
	results_data.sort_custom(func(a, b): return a.steps < b.steps)

	# Create and add a bar for each data point.
	for item in results_data:
		var bar = bar_scene.instantiate()
		var label_text = "%d Steps" % item.steps
		bars_container.add_child(bar)
		bar.set_data(item.count, max_count, label_text)
