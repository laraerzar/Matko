extends Node

var has_played_number_blocks: bool = false

var intro_shown := false 
var outro_shown := false 

func reset() -> void:
	intro_shown = false
	outro_shown = false
	has_played_number_blocks = false
