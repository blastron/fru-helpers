extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready():
	$"p1/p1 - fall of fate".pressed.connect(self.p1_fall_of_fate)
	
	$"settings button".pressed.connect(self.show_settings)
	
	var settings_loaded: bool = UserSettings.try_load_settings()
	if not settings_loaded:
		show_settings()


func p1_fall_of_fate():
	get_tree().change_scene_to_file("res://p1/fof/fof.tscn")


func show_settings():
	$settings.visible = true
