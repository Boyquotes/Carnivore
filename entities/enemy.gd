extends Entity
class_name Enemy

export(Array) var state_execution_pattern
var state_id: int = 0

onready var Player = toolbox.get_node_in_group("player")
onready var AI_TARGET = Player

func _ready():
	connect("deleted", self, "_on_deleted")


func go_to_next_state():
	state_id = state_id + 1 if state_id < len(state_execution_pattern) - 1 else 0
	set_state(state_execution_pattern[state_id])
	
func start_state_pattern():
	set_state(state_execution_pattern[0])
	
func _on_deleted():
	camera_events.emit_signal("camera_shake_request", 0.2, 2)
