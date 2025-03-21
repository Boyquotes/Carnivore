extends MenuScreen

const ARCHIEVEMENT_TITLE_BASE: String = "ui.challenges.%s.title"
const ARCHIEVEMENT_DESCRIPTION_BASE: String = "ui.challenges.%s.description"

onready var CurrentArchievement = $challenges/archievement_viewer_manager/archievement_container/challenges_container/current_archievement
onready var ArrowRight = $challenges/VBoxContainer/arrow_container/arrow_right
onready var ArrowLeft = $challenges/VBoxContainer/arrow_container/arrow_left
onready var TabOutOfFocusLeft = $challenges/archievement_viewer_manager/archievement_container/challenges_container/out_of_focus_left
onready var TabOutOfFocusRight = $challenges/archievement_viewer_manager/archievement_container/challenges_container/out_of_focus_right

onready var PageNumber = $challenges/VBoxContainer/arrow_container/page


export(int) var number_of_archievements = 3
var current_panel: int = 0
var current_generation: String = "generation%s"
var archievements = game_data.get_player_data("archievements")


func _ready(): 
	current_generation = current_generation % game_data.get_player_data("generation")
	number_of_archievements -= 1 # improves readability
	update_current_panel()


func update_current_panel():
	if game_data.get_player_data("generation") < 0: return
	
	var archievement = game_data.ARCHIEVEMENT_REF[current_generation][current_panel]
	var archievement_title = ARCHIEVEMENT_TITLE_BASE % archievement
	var archievement_description = ARCHIEVEMENT_DESCRIPTION_BASE % archievement
	
	CurrentArchievement.set_archievement(archievement_title, archievement_description)
	
	if archievements[current_generation][archievement]: # if the archievement is complete
		CurrentArchievement.mark_archievement_as_complete()
	else: CurrentArchievement.mark_archievement_as_incomplete()
	
	ArrowLeft.disabled = current_panel == 0
	ArrowRight.disabled = current_panel == number_of_archievements
	
	TabOutOfFocusLeft.modulate.a = 1 if current_panel > 0 else 0
	TabOutOfFocusRight.modulate.a = 1 if current_panel < number_of_archievements else 0
	
	PageNumber.text = "%s/%s" % [current_panel + 1, number_of_archievements + 1]


func _on_arrow_button_pressed(id):
	match id:
		"arrow_up": current_panel = int(max(0, current_panel - 1))
		"arrow_down": current_panel = int(min(number_of_archievements, current_panel + 1))
	update_current_panel()
