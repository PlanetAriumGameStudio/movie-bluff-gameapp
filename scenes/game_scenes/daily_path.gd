extends Control

class_name DailyPath

@export var mini_pair_prefab:PackedScene

var path_from_start: Array[Pairing]
var path_from_finish: Array[Pairing]

func init_daily_path(start_pair:Pairing, finish_pair:Pairing):
	path_from_start = []
	path_from_finish = []
	push_to_start(start_pair)
	push_to_finish(finish_pair)

func push_to_start(pair:Pairing):
	path_from_start.push_back(pair)
	var mini_pair = mini_pair_prefab.instantiate()
	%StartPathHBoxContainer.add_child(mini_pair)
	mini_pair.set_pair(pair)

func push_to_finish(pair:Pairing):
	path_from_finish.push_front(pair)
	var mini_pair = mini_pair_prefab.instantiate()
	%FinishPathHBoxContainer.add_child(mini_pair)
	%FinishPathHBoxContainer.move_child(mini_pair, 0)
	mini_pair.set_pair(pair)

# Check after each submission to see if win condition met
func _check_path_completeness() -> bool:
	var i = 0
	var curr_pair:Pairing = path_from_start[i]
	var path_exists = true
	while(path_exists && i < path_from_start.size()-1):
		if path_from_start[i].movie_name == path_from_start[i+1].movie_name || path_from_start[i].person_name == path_from_start[i+1].person_name:
			i += 1
			continue
		else:
			path_exists = false
	# TODO confirm overlap as well
	
	# Specifically check the mid point
	# TODO Lookahead needed for last check to complete path (On submission, check last submissions cast/crew for early finish)
	if (path_exists &&
		(path_from_start.back().movie_name != path_from_finish.front().movie_name &&
		 path_from_start.back().person_name != path_from_finish.front().person_name)):
		print("Failed the Gap")
		return false
	
	# Confirm path makes it to the end through both Arrays
	while(path_exists && i < path_from_finish.size()-1):
		if path_from_finish[i].movie_name == path_from_finish[i+1].movie_name || path_from_finish[i].person_name == path_from_finish[i+1].person_name:
			i += 1
			continue
		else:
			path_exists = false
	
	if path_exists:
		print("yay")
	else:
		print("nay")
	return path_exists


func _on_submission_button_button_down() -> void:
	if _check_path_completeness():
		print("Yay")
	else:
		print("Nay")
