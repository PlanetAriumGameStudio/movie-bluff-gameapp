@tool
extends Control

@onready var bar_rect: Panel = %BarRect

# Sets the bar's visual properties based on the data provided.
#
# - value: The number of players for this bar.
# - max_value: The highest number of players across all bars in the chart.
# - label: The text to display below the bar (e.g., "5 Steps").
func set_data(value: int, max_value: int) -> void:
	if max_value > 0:
		# We control the bar's height by adjusting its top anchor.
		# A value of 1.0 means the bar has 0 height.
		# A value of 0.0 means the bar has 100% height.
		var height_ratio = float(value) / max_value
		bar_rect.anchor_top = 1.0 - height_ratio
	else:
		# Handle the case where there's no data or max_value is zero.
		bar_rect.anchor_top = 1.0
