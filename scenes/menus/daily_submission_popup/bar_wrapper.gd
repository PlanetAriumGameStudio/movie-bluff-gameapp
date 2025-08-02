@tool
extends Control

# Sets the bar's visual properties based on the data provided.
#
# - value: The number of players for this bar.
# - max_value: The highest number of players across all bars in the chart.
# - label: The text to display below the bar (e.g., "5 Steps").
func set_data(value: int, max_value: int, chart_label: String) -> void:
	%Bar.set_data(value, max_value)
	%Count.set_text(str(value))
	%Label.set_text(chart_label)
