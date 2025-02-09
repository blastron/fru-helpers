class_name DescriptionPanel extends Control


@export var _title: Label
@export var _subtitle: Label
@export var _subtitle_container: Container
@export var _description_box: VBoxContainer
@export var _strat_description: RichTextLabel

@export var _next_button: Button
@export var _prev_button: Button

@export var _start_button: Button
@export var _reset_button: Button

@export var _explain_button: Button

@export var _menu_button: Button


var next_enabled: bool:
	get: return not _next_button.disabled if _next_button else false
	set(value): if _next_button: _next_button.disabled = not value


var prev_enabled: bool:
	get: return not _prev_button.disabled if _prev_button else false
	set(value): if _prev_button: _prev_button.disabled = not value


# Whether the explain button is shown. If it is, the next and previous buttons are hidden, even if they are enabled.
var explain_enabled: bool:
	get: return _explain_button.visible if _explain_button else false
	set(value):
		if _explain_button: _explain_button.visible = value
		if _next_button: _next_button.visible = not value
		if _prev_button: _prev_button.visible = not value


# Whether the start button is enabled. If it is not, then the reset button is enabled.
var start_enabled: bool:
	get: return _start_button.visible if _start_button else false
	set(value):
		if _start_button: _start_button.visible = value
		if _reset_button: _reset_button.visible = not value


signal next_pressed()
signal prev_pressed()

signal start_pressed()
signal reset_pressed()
signal explain_pressed()


func _init() -> void:
	next_enabled = false
	prev_enabled = false
	start_enabled = false
	explain_enabled = false
	strat_description = []


var title: String:
	get: return _title.text if _title else ""
	set(value): if _title: _title.text = value


var subtitle: String:
	get: return _subtitle.text if _subtitle else ""
	set(value):
		if _subtitle: _subtitle.text = value
		if _subtitle_container: _subtitle_container.visible = not value.is_empty()


var strat_description: Array[String]:
	get:
		if not _description_box: return []
		
		var output: Array[String]
		for child in _description_box.get_children():
			if child is RichTextLabel:
				output.append(child.text)
			
		return output
	set(value):
		if not _description_box or not _strat_description: return
		
		# Remove all children from the box except for the strat description.
		for child in _description_box.get_children():
			if child != _strat_description:
				_description_box.remove_child(child)
				child.queue_free()
			
		# Set the first paragraph.
		if len(value) == 0:
			_strat_description.text = ""
			return
		else:
			_strat_description.text = value[0]
		
		if len(value) > 1:
			for index in range(1, len(value)):
				var new_paragraph: RichTextLabel = _strat_description.duplicate()
				new_paragraph.text = value[index]
				_description_box.add_child(new_paragraph)


func _ready() -> void:
	if _next_button: _next_button.pressed.connect(func(): next_pressed.emit())
	if _prev_button: _prev_button.pressed.connect(func(): prev_pressed.emit())
	if _start_button: _start_button.pressed.connect(func(): start_pressed.emit())
	if _reset_button: _reset_button.pressed.connect(func(): reset_pressed.emit())
	if _explain_button: _explain_button.pressed.connect(func(): explain_pressed.emit())
	if _menu_button: _menu_button.pressed.connect(self._menu_button_pressed)
	
	strat_description = []


func _menu_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
	
