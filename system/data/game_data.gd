extends Node

const TARGET_BOUNTY: int = 15000
const DEFAULT_BOUNTY = 20
const MAX_CHEER_INTENSITY = 25.0

const default_player_data = {
	"special_attack_tutorial_finished": false,
	"bounty": DEFAULT_BOUNTY,
	"skill_points": 0,
	"skills": {
		"hard_skin": false,
		"rooted": false,
		"body_armor": false,
		"speed_boost": false,
		"energy_saver": false,
		"bloodthirsty": false,
		"large_tongue": false,
		"healing_meal": false,
		"survivor": false
	}
}
var player_data: Dictionary = default_player_data.duplicate(true)

const DEFAULT_VOLUME: float = 1.6

var default_game_settings: Dictionary = {
	"audio": {
		"Master": DEFAULT_VOLUME / 2,
		"music": DEFAULT_VOLUME,
		"entity_sounds": DEFAULT_VOLUME,
		"player_sounds": DEFAULT_VOLUME,
		"environment_sounds": DEFAULT_VOLUME,
		"gui_sounds": DEFAULT_VOLUME,
	},
	"video": {
		"camera_shake": true
	},
	"locale": {
		"value": "DEFAULT"	
	},
	"desktop_keybinds": {
		"controls_up": OS.find_scancode_from_string("W"),
		"controls_right": OS.find_scancode_from_string("D"),
		"controls_down": OS.find_scancode_from_string("S"),
		"controls_left": OS.find_scancode_from_string("A"),
		"controls_pause": OS.find_scancode_from_string("ESCAPE"),
		"controls_interact": OS.find_scancode_from_string("E"),
		"controls_switch_projectile": OS.find_scancode_from_string("Q"),
		"controls_shoot": BUTTON_LEFT,
		"controls_special": BUTTON_RIGHT
	},
	"mobile_button_displacement": {
		"movement_joystick": Vector2(35, 20),
		"shooting_joystick": Vector2(45, 25),
		"special_attack": Vector2(14, 14),
		"switch_projectile": Vector2(14, 42),
		"pause_button": Vector2(12, 12)
	}
}
var game_settings: Dictionary = default_game_settings.duplicate(true)

var current_platform: String = "desktop" setget set_current_platform, get_current_platform # TEMP
var current_level: String = "" setget set_current_level, get_current_level
var current_arena_wave: int = 1 setget set_current_wave, get_current_wave
var current_player_state: String = ""
var initial_player_bounty: int = 0
var level_player_bounty: int = 0
var total_level_player_bounty: int = 0
var progress_safe: bool = false
var skills_disabled: bool = false
var can_pause: bool = false
var cheer_intensity: float = 1.0 setget set_cheer_intensity, get_cheer_intensity

var last_lowest_level_time: Array = [] setget set_last_lowest_level_time, get_last_lowest_level_time



func _ready(): # For debug values    REMEMBER THAT THE PLATFORM MUST BE SET IN device_manager.gd NOT HERE FELIPE YOU DUMB FUCK
	if !OS.is_debug_build() or OS.get_name() == "Android": return
	player_data.bounty = 300
	player_data.skill_points = 69
	
	#player_data.skills.hard_skin = true
	#player_data.skills.body_armor = true
	
func override_game_settings(value: Dictionary): game_settings = value.duplicate(true)
func override_player_data(value: Dictionary): player_data = value.duplicate(true)

func set_cheer_intensity(value: float):
	cheer_intensity = value
	cheer_intensity = clamp(cheer_intensity, 1.0, MAX_CHEER_INTENSITY)
	game_events.emit_signal("cheer_intensity_updated", cheer_intensity)
func get_cheer_intensity() -> float: return cheer_intensity

func set_current_platform(platform_name: String): current_platform = platform_name
func get_current_platform() -> String: return current_platform

func set_player_bounty_target(value: int): bounty_target = value
func get_player_bounty_target(): return bounty_target
	

func set_current_level(level_name: String): current_level = level_name
func get_current_level() -> String: return current_level

func set_current_wave(wave_number: int): current_arena_wave = wave_number
func get_current_wave() -> int: return current_arena_wave

func set_player_data(key, value): player_data[key] = value
func get_player_data(key): return player_data[key]

func set_game_setting(group, key, value): game_settings[group][key] = value
func get_game_setting(group, key): return game_settings[group][key]

func set_last_lowest_level_time(value: Array): last_lowest_level_time = value
func get_last_lowest_level_time() -> Array: return last_lowest_level_time

func reset_all_data():
	print("RESETTING DATA")
	player_data = default_player_data.duplicate(true)
	game_settings = default_game_settings.duplicate(true)
	global_data_manager.save_all()
