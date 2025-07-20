extends Control

class_name MoviePersonPair

enum Highlight { NONE, MOVIE, PERSON }

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

func set_highlight(part_to_highlight: Highlight) -> void:
	# Reset both highlights
	%MoviePairEntry.set_highlight_active(false)
	%PersonPairEntry.set_highlight_active(false)

	# Then, apply the highlight to the specified part
	match part_to_highlight:
		Highlight.MOVIE:
			%MoviePairEntry.set_highlight_active(true)
		Highlight.PERSON:
			%PersonPairEntry.set_highlight_active(true)
