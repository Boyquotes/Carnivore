extends TextureRect


const ARCHIEVEMENT_TITLE_TEXT: String = "ui.archievements.%s.title"
onready var ColorTween: Tween = $Tween
onready var TitleLabel: Label = $HBoxContainer/Label



func _ready():
	self.visible = false
	# warning-ignore:return_value_discarded
	player_events.connect("archievement_made", self, "_on_archievement_made")
	


func animate():
	self.modulate = Color.yellow
	# warning-ignore:return_value_discarded
	ColorTween.interpolate_property(
		self,
		"modulate",
		Color.yellow, Color.white,
		0.4, 
		Tween.TRANS_LINEAR, Tween.EASE_OUT,
		1.5
	)
	# warning-ignore:return_value_discarded
	ColorTween.start()


	
func _on_archievement_made(archievement: String, notify):
	if !notify: return
	self.visible = true
	TitleLabel.text = archievement
	animate()

func _on_Tween_tween_all_completed():
	self.visible = false
