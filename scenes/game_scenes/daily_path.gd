extends Control

class_name DailyPath

var path_from_start: Array[Pairing]
var path_from_finish: Array[Pairing]

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
