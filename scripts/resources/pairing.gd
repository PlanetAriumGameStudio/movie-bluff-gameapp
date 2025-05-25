extends Resource

class_name Pairing

func new() -> Pairing:
	movie_id = 0
	movie_name = ""
	movie_poster_url = ""
	movie_credits = []
	
	person_id = 0
	person_name = ""
	person_profile_url = ""
	person_credits = []
	
	return self

static func parse_pairing_from_json(json:Variant) -> Pairing:
	var new_pairing:Pairing = Pairing.new()
	new_pairing.movie_id = int(json["movie_id"])
	new_pairing.movie_name = json["movie_name"]
	new_pairing.movie_poster_url = json["poster_path"]
	new_pairing.movie_credits = json["movie_credits"]
	
	new_pairing.person_id = int(json["person_id"])
	new_pairing.person_name = json["person_name"]
	new_pairing.person_profile_url = json["profile_path"]
	new_pairing.person_credits = json["person_credits"]
	return new_pairing

var movie_id:int
var movie_name:String
var movie_poster_url:String	
var movie_credits:Array

var person_id:int
var person_name:String
var person_profile_url:String
var person_credits: Array

class CastMember:
	var gender:int
	var id:int
	var name:String
	var original_name:String
	var profile_path:String
	var character:String

class MovieCredit:
	var id:int
	var original_title:String
	var poster_path:String
	var title:String
