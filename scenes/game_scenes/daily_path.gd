extends Control

class_name DailyPath

@export var mini_pair_prefab:PackedScene

signal game_completed

var _path_from_start: Array[Pairing]
var _path_from_finish: Array[Pairing]

var _current_selected_pair: Pairing
var _current_selected_pair_index: int

func init_daily_path(start_pair:Pairing, finish_pair:Pairing):
	_path_from_start = Array([], TYPE_OBJECT, "Object", Pairing)
	_path_from_finish = Array([], TYPE_OBJECT, "Object", Pairing)
	push_to_start(start_pair)
	push_to_finish(finish_pair)

func push_to_start(pair:Pairing):
	if len(_path_from_start) > 0:
		print("sanity check on start node: ", _path_from_start[0])
	print("Pushing pair to end of start pairing array", JSON.stringify(pair))
	_path_from_start.push_back(pair)
	print("pairing pushed, sanity checking: ", _path_from_start.back())
	var mini_pair = mini_pair_prefab.instantiate()
	%StartPathHBoxContainer.add_child(mini_pair)
	mini_pair.set_pair(pair)

func push_to_finish(pair:Pairing):
	_path_from_finish.push_front(pair)
	var mini_pair = mini_pair_prefab.instantiate()
	%FinishPathHBoxContainer.add_child(mini_pair)
	%FinishPathHBoxContainer.move_child(mini_pair, 0)
	mini_pair.set_pair(pair)
	
func get_full_path_json() -> Array:
	var full_path_json = []
	print(len(_path_from_start))
	print(len(_path_from_finish))
	if len(_path_from_start) >= 2:
		print(_path_from_start[0])
		print(_path_from_start[1])

	print("Handle Path From Start")
	for path_node in _path_from_start:
		var packed_node = path_node.pack()
		print(packed_node)
		full_path_json.append(packed_node)

	print("Handle Path From Finish")
	for path_node in _path_from_finish:
		var packed_node = path_node.pack()
		print(packed_node)
		full_path_json.append(packed_node)
	
	print("FullPathComplete")
	print(full_path_json)
	return full_path_json

# Check after each submission to see if win condition met
func _check_path_completeness() -> bool:
	var i = 0
	var curr_pair:Pairing = _path_from_start[i]
	var path_exists = true
	while(path_exists && i < _path_from_start.size()-1):
		if _path_from_start[i].movie_name == _path_from_start[i+1].movie_name || _path_from_start[i].person_name == _path_from_start[i+1].person_name:
			i += 1
			continue
		else:
			path_exists = false
	# TODO confirm overlap as well
	
	# Specifically check the mid point
	# TODO Lookahead needed for last check to complete path (On submission, check last submissions cast/crew for early finish)
	if (path_exists &&
		(_path_from_start.back().movie_name != _path_from_finish.front().movie_name &&
		 _path_from_start.back().person_name != _path_from_finish.front().person_name)):
		print("Failed the Gap")
		return false
	
	# Confirm path makes it to the end through both Arrays
	while(path_exists && i < _path_from_finish.size()-1):
		if _path_from_finish[i].movie_name == _path_from_finish[i+1].movie_name || _path_from_finish[i].person_name == _path_from_finish[i+1].person_name:
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
		game_completed.emit()
	else:
		print("Nay")
