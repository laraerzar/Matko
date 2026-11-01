extends Node

var easy_completed: bool = false
var medium_completed: bool = false
var hard_completed: bool = false

var intro_shown := false # uvod se pokaže samo enkrat
var outro_shown := false # sporočilo o uspehu se pokaže samo enkrat

func all_completed() -> bool:
	return easy_completed and medium_completed and hard_completed

func reset() -> void:
	easy_completed = false
	medium_completed = false
	hard_completed = false
	intro_shown = false
	outro_shown = false
