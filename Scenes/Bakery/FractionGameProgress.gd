extends Node

#ali je uvodno sporočilo že prikazano
var intro_shown: bool = false

#ali je zaključno sporočilo že prikazano
var outro_shown: bool = false

# katere težavnosti so opravljene: 0 = lahko, 1 = srednje, 2 = težko
var completed_modes: Array[int] = []

func complete_mode(mode: int) -> void:
	if not completed_modes.has(mode):
		completed_modes.append(mode)

func all_completed() -> bool:
	return completed_modes.size() >= 3
