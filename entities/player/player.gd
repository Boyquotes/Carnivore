extends Entity


signal entered_eat_state
signal exited_eat_state
signal healing


const HUNGER_DECREASE_DELAY_WHEN_FULL: float = 1.5
const DEFAULT_HUNGER_DECREASE_DELAY: float = 3.0
var HUNGER_DECREASE_DELAY: float = DEFAULT_HUNGER_DECREASE_DELAY ## had to turn this bitch into a var because of the skill system
var ENERGY_DECREASE_DELAY: float = 0.6 ## same as above
const HUNGER_DECREASE_DELAY_TUTORIAL: float = 4.0

const HUNGER_DAMAGE = 1
const DAMAGE_CAMERA_SHAKE_DURATION = 0.3
const DAMAGE_CAMERA_SHAKE_INTENSITY = 0.8

export(int) var MAX_HUNGER = 6
export(int) var MAX_ENERGY = 6

onready var StatDecreaseTimer: Timer = $stat_decrease_delay
onready var SpriteMaterial: ShaderMaterial = $texture.material
onready var InvincibilityTimer: Timer = $invincibility_timer
onready var RootedSkillHealingTimer: Timer = $rooted_skill_healing_timer
onready var AnimPlayer = $part_state_anim_handler/animation_player
onready var ProjectileHandler: Node2D = $part_player_projectile_handler

var last_time_TEMP:= 0

func _ready():
	add_tag("PLAYER")
	
	# creating new stats
	stats["hunger"] = MAX_HUNGER / 2
	stats["can_get_hungry"] = true
	stats["energy"] = 0
	stats["shields"] = 0 if not has_skill("hard_skin") else 3 * int(clamp((2 * int(has_skill("body_armor")) + 1), 1, 2))
	call_deferred("update_stat", "hunger", get_stat("hunger"), false)
	call_deferred("update_stat", "shields", get_stat("shields"), false)
	
	
	## adds 20% of speed if you have the speed boost skill
	MAX_SPEED = MAX_SPEED + 25.0 / float(MAX_SPEED) * 100.0 if game_data.player_data.skills.speed_boost else MAX_SPEED
	DEFAULT_MAX_SPEED = MAX_SPEED
	
	# increases the time it takes for the energy to go down if you have the energy efficiency skill
	ENERGY_DECREASE_DELAY *= 1.75 if game_data.player_data.skills.energy_efficiency else 1.0
	
	# warning-ignore:return_value_discarded
	input_events.connect("player_movement_direction_updated", self, "_on_player_used_joystick")
	# warning-ignore:return_value_discarded
	player_events.connect("meat_consumed", self, "consume_meat")
	# warning-ignore:return_value_discarded
	player_events.connect("enter_eat_state_request", self, "enter_eat_state")
	# warning-ignore:return_value_discarded
	player_events.connect("set_stat_value", self, "update_stat")
	# warning-ignore:return_value_discarded
	player_events.connect("force_exit_from_eat_state", self, "_on_exit_from_eat_state_forced")
	# warning-ignore:return_value_discarded
	player_events.connect("unfreeze_player", self, "unfreeze")
	# warning-ignore:return_value_discarded
	player_events.connect("freeze_player", self, "freeze")
	# warning-ignore:return_value_discarded
	connect("frozen", self, "_on_player_frozen")
	# warning-ignore:return_value_discarded
	connect("unfrozen", self, "_on_player_unfrozen")
	
		
func _input(event):
	if OS.is_debug_build():
		if event.is_action_pressed("debug_f3"): player_events.emit_signal("unfreeze_player")
		if event.is_action_pressed("debug_f4"): consume_meat()
		if event.is_action_pressed("debug_f6"): update_stat("health", int(max(get_stat("health") - 1, 0)))
		if event.is_action_pressed("debug_f7"): player_events.emit_signal("freeze_player")
		
	if get_stat("energy") <= 0: return
	
	match event.get_class():
		"InputEventMouseButton":
			if !event.button_index == game_data.game_settings.desktop_keybinds.controls_special: continue
			if get_state() == "EAT": continue
			if get_stat("energy") < MAX_ENERGY: continue
			enter_eat_state()


func _process(_delta):
	if get_state() in CONSTANT_STATES: process_constant_state()
	else: process_inconstant_state()
	TextureRes.flip_v = rotation_degrees > 90 and rotation_degrees < -90
	
func process_constant_state(): pass

func process_inconstant_state():
	if get_state() == "EAT": return
	set_state("IDLE" if movement_direction == Vector2.ZERO else "MOVE")
	
	process_rooted_skill()
	
func in_tutorial(): return game_data.player_data.bounty == game_data.DEFAULT_BOUNTY
func energy_full(): return get_stat("energy") == MAX_ENERGY
func has_skill(skill: String): return game_data.player_data.skills[skill]



func process_rooted_skill():
	if not has_skill("rooted"): return
	if get_stat("health") == MAX_HEALTH: return
	if not get_state() in ["MOVE", "IDLE"]: return
	match get_state():
		"MOVE": RootedSkillHealingTimer.stop()
		"IDLE": 
			if not RootedSkillHealingTimer.is_stopped(): continue
			RootedSkillHealingTimer.start()
			
	
	if RootedSkillHealingTimer.is_stopped(): return
	print("player.gd: RootedSkillHealingTimer.time_left: %s" % RootedSkillHealingTimer.time_left)
	
	
func process_healing_meal_skill():
	if not has_skill("healing_meal"): return
	if get_stat("shields") > 0: return
	if not toolbox.EntityRNG.randi_range(1, 100) <= 25: return
	
	update_stat("health", int(min(get_stat("health") + 1, MAX_HEALTH)))


func start_stat_decrease_timer(hunger_value: int):
	if not get_stat("can_get_hungry"): return
	var time := HUNGER_DECREASE_DELAY
	
	if has_skill("survivor_metabolism"):
		time = HUNGER_DECREASE_DELAY * 2 if hunger_value <= 3 else time
	if in_tutorial():
		time += 0.2
	if energy_full():
		time -= 0.2
	
	StatDecreaseTimer.start(time)
	
func reset_stat_decrease_timer(mode: String):
	match mode:
		"hunger": start_stat_decrease_timer(get_stat("hunger"))
		"energy": StatDecreaseTimer.start(ENERGY_DECREASE_DELAY)


func update_stat(id: String, value: int, animate: bool = true):
	set_stat(id, value)
	player_events.emit_signal("status_value_update", id, get_stat(id), animate)

func start_invincibility():
	set_stat("invincible", true)
	InvincibilityTimer.start()

func stop_invincibility():
	set_stat("invincible", false)
	
func enter_eat_state():
	if get_state() == "EAT": return
	if get_stat("energy") < MAX_ENERGY: return
	add_tag("EAT")
	set_state("EAT")
	InvincibilityTimer.stop()
	set_stat("invincible", true)
	player_events.emit_signal("entered_eat_state")
	player_events.emit_signal("special_attack_unavailable")
	emit_signal("entered_eat_state")
	# yeah i use the same timer for both hunger and energy, deal with it
	reset_stat_decrease_timer("energy")
	set_movement_direction(Vector2.LEFT)
	input_events.emit_signal("player_movement_direction_updated", Vector2.LEFT)
	
	if not has_skill("bloodthirsty"): return
	MAX_SPEED += (25.0 / float(DEFAULT_MAX_SPEED)) * 100.0
	
func exit_eat_state():
	if get_state() != "EAT": return
	start_invincibility()
	remove_tag("EAT")
	set_state("IDLE")
	set_stat("invincible", false)
	emit_signal("exited_eat_state")
	reset_stat_decrease_timer("hunger")
	player_events.emit_signal("exited_eat_state")
	set_rotation_degrees(0.0)
	set_movement_direction(Vector2.ZERO)
	AnimPlayer.play("RESET")
	
	# resets the speed because of the bloodthirsty skill
	MAX_SPEED = DEFAULT_MAX_SPEED

func consume_meat():
	if get_state() == "EAT": return
	
	var stat_to_update = "hunger" if get_stat("hunger") < MAX_HUNGER else "energy"
	var stat_cap = MAX_HUNGER if stat_to_update == "hunger" else MAX_ENERGY
	update_stat(
		stat_to_update,
		int(min(get_stat(stat_to_update) + 1, stat_cap))
	)
	
	start_stat_decrease_timer(get_stat("hunger"))
	
	process_healing_meal_skill()
	
	if get_stat("energy") == MAX_ENERGY:
		player_events.emit_signal("special_attack_available")
		add_tag("FULL")
		return
	remove_tag("FULL")
	
	
func consume_enemy(EnemyNode):
	## Trick to make the camera constantly shake
	# basically the hurtbox is always detecting the player object
	# so i use that to make the camera shake
	var shake_intensity: float = 0.3 if "PLAYER" in EnemyNode.TAGS else 1.5
	camera_events.emit_signal("camera_shake_request", 0.15, shake_intensity)
	
	if "PLAYER" in EnemyNode.TAGS: return
	
	# regenerates both hunger and health
	update_stat("hunger", int(min(get_stat("hunger") + 1, MAX_HUNGER)))
	
	if get_stat("shields") > 0: return
	if get_stat("health") < MAX_HEALTH:
		emit_signal("healing")
		update_stat("health", get_stat("health") + 1)
	
	
func apply_damage(damage: int):
	if damage <= 0: return
	if damage >= get_stat("health"): 
		die()
		return
		
	emit_signal("hurt")
	start_invincibility()
	start_blinking()
	
	var value_to_update = "health" if get_stat("shields") <= 0 else "shields"
	var health_after_damage = get_stat(value_to_update) - damage
	if value_to_update == "shields": 
		if health_after_damage < 0:
			update_stat("health", int(abs(health_after_damage)))
			update_stat("shields", 0)
			return
	
	update_stat(
		value_to_update,
		health_after_damage
	)
	
	camera_events.emit_signal("camera_shake_request", DAMAGE_CAMERA_SHAKE_DURATION, DAMAGE_CAMERA_SHAKE_INTENSITY)
	
func set_movement_direction(value: Vector2):
	if get_state() in ["EAT", "DASH"]:
		if value == Vector2.ZERO:
			return
	movement_direction = value

		
		

func _on_stat_decrease_delay_timeout():
	remove_tag("FULL")
	match get_state():
		"EAT":
			if get_stat("energy") <= 0: 
				exit_eat_state()
				return
			update_stat("energy", int(max(get_stat("energy") - 1, 0)))
			StatDecreaseTimer.start(ENERGY_DECREASE_DELAY)
		_:
			if get_stat("hunger") <= 0: 
				apply_damage(1)
				return
			update_stat("hunger", int(max(get_stat("hunger") - 1, 0)))
			start_stat_decrease_timer(get_stat("hunger"))
			
func _on_exit_from_eat_state_forced(): exit_eat_state()


func _on_player_used_joystick(value):
	set_movement_direction(value)
	_on_player_movement_direction_updated(value)
	
func _on_player_movement_direction_updated(value): 
	if get_state() == "EAT" or value == Vector2.ZERO: return
	player_events.emit_signal("player_moving" if value != Vector2.ZERO else "player_not_moving")
	
func _on_player_frozen(): FRICTION = DEFAULT_FRICTION * 0.145
func _on_player_unfrozen(): FRICTION = DEFAULT_FRICTION


func _on_player_state_changed(new_state, _old_state):
	game_data.current_player_state = new_state


func _on_rooted_skill_healing_timer_timeout():
	if get_stat("shields") > 0: return
	update_stat("health", int(min(get_stat("health") + 1, MAX_HEALTH)))
	emit_signal("healing")
