extends Control


signal request_movement_joystick_animation
signal request_stop_movement_joystick_animation

onready var MultiuseTimer := $timer
onready var TutorialTextCooldown := $tutorial_text_show_cooldown
onready var TutorialTextBox := $HBoxContainer/VBoxContainer/TutorialTextBox
onready var TutorialLabel := $HBoxContainer/VBoxContainer/TutorialTextBox/Label

const DELAY_BETWEEN_TUTORIALS := 2

const movement_tutorial_text = "tutorial.movement"
const pick_stone_tutorial_text = "tutorial.pick_stone"
const shooting_tutorial_text = "tutorial.throw_stone"
const hunger_tutorial_text = "tutorial.hunger"
const special_tutorial_text = "tutorial.special_attack"


enum {
	MOVEMENT,
	PICK_STONE,
	SHOOTING,
	EATING,
	SPECIAL
}
var tutorial_stage := MOVEMENT


func _ready():
	emit_signal("request_movement_joystick_animation")


func skip_tutorial_stage(text_to_show, new_stage):
	TutorialTextBox.visible = false
	TutorialLabel.text = tr(text_to_show)
	tutorial_stage = new_stage
	TutorialTextCooldown.start()



func _on_movement_joystick_used():
	emit_signal("request_stop_movement_joystick_animation")
	if !MultiuseTimer.is_stopped(): return
	MultiuseTimer.start(DELAY_BETWEEN_TUTORIALS)
	
func _on_player_picked_projectile(projectile):
	if projectile != "stone_projectile": return
	skip_tutorial_stage(shooting_tutorial_text, SHOOTING)
	player_events.disconnect("projectile_collected", self, "_on_player_picked_projectile")
	
func _on_tutorial_ant_dead():
	skip_tutorial_stage(hunger_tutorial_text, EATING)
	

func _on_timer_timeout():
	match tutorial_stage:
		MOVEMENT: 
			skip_tutorial_stage(pick_stone_tutorial_text, PICK_STONE)



func _on_tutorial_text_show_cooldown_timeout():
	TutorialTextBox.visible = true
	
	match tutorial_stage:
		PICK_STONE:
			player_events.connect("projectile_collected", self, "_on_player_picked_projectile")
			game_events.emit_signal("spawn_tutorial_stone")
		SHOOTING:
			game_events.emit_signal("spawn_tutorial_ant")
			game_events.connect("tutorial_ant_dead", self, "_on_tutorial_ant_dead")
