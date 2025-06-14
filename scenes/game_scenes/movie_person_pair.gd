extends Control

class_name MoviePersonPair

var current_pairing:Pairing

func update_movie_pairing(pair:Pairing):
	%MoviePairEntry.update_pair(pair.movie_name, pair.movie_poster_url)
	current_pairing = pair
	
func update_person_pairing(pair:Pairing):
	%PersonPairEntry.update_pair(pair.person_name, pair.person_profile_url)
	current_pairing = pair

func set_pairing(pair:Pairing):
	%MoviePairEntry.update_pair(pair.movie_name, pair.movie_poster_url)
	%PersonPairEntry.update_pair(pair.person_name, pair.person_profile_url)
	current_pairing = pair

func get_pair() -> Pairing:
	return current_pairing
