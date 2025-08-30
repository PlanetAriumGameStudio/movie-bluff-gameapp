extends Control

class_name DailyPath

@export var mini_pair_prefab:PackedScene

signal game_completed

var _path_from_start: Array[Pairing]
var _path_from_finish: Array[Pairing]

func init_daily_path(start_pair:Pairing, finish_pair:Pairing):
	_path_from_start = Array([], TYPE_OBJECT, "Object", Pairing)
	_path_from_finish = Array([], TYPE_OBJECT, "Object", Pairing)
	push_to_start(start_pair)
	push_to_finish(finish_pair)

func push_to_start(pair:Pairing):
	_path_from_start.push_back(pair)
	var mini_pair = mini_pair_prefab.instantiate()
	%StartPathHBoxContainer.add_child(mini_pair)
	mini_pair.set_pair(pair)

	if _check_path_completeness():
		game_completed.emit()

func push_to_finish(pair:Pairing):
	_path_from_finish.push_front(pair)
	var mini_pair = mini_pair_prefab.instantiate()
	%FinishPathHBoxContainer.add_child(mini_pair)
	%FinishPathHBoxContainer.move_child(mini_pair, 0)
	mini_pair.set_pair(pair)

	if _check_path_completeness():
		game_completed.emit()
	
func get_full_path_json() -> Array:
	var full_path_json = []

	for path_node in _path_from_start:
		var packed_node = path_node.pack()
		full_path_json.append(packed_node)

	for path_node in _path_from_finish:
		var packed_node = path_node.pack()
		full_path_json.append(packed_node)
	
	return full_path_json

# Check after each submission to see if win condition met
func _check_path_completeness() -> bool:
	if _path_from_start.size() < 1 or _path_from_finish.size() < 1:
		return false
	print("checking path completeness")
	var i = 0
	var path_exists = true

	# Check start path completion
	while(path_exists && i < _path_from_start.size()-1):
		if _path_from_start[i].movie_name == _path_from_start[i+1].movie_name || _path_from_start[i].person_name == _path_from_start[i+1].person_name:
			i += 1
			continue
		else:
			path_exists = false
	
	# Check the mid point
	if (path_exists &&
		(_path_from_start.back().movie_name != _path_from_finish.front().movie_name &&
		 _path_from_start.back().person_name != _path_from_finish.front().person_name)):
		return false
	
	# Check finish path completion
	while(path_exists && i < _path_from_finish.size()-1):
		if _path_from_finish[i].movie_name == _path_from_finish[i+1].movie_name || _path_from_finish[i].person_name == _path_from_finish[i+1].person_name:
			i += 1
			continue
		else:
			path_exists = false
	
	return path_exists
