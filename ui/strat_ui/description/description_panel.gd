class_name DescriptionPanel extends Control


@export var _title: Label
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
	strat_description = ""


var strat_description: String:
	get: return _strat_description.text if _strat_description else ""
	set(value):
		if _strat_description:
			_strat_description.text = value
			_strat_description.visible = not value.is_empty()


func _ready() -> void:
	if _next_button: _next_button.pressed.connect(func(): next_pressed.emit())
	if _prev_button: _prev_button.pressed.connect(func(): prev_pressed.emit())
	if _start_button: _start_button.pressed.connect(func(): start_pressed.emit())
	if _reset_button: _reset_button.pressed.connect(func(): reset_pressed.emit())
	if _explain_button: _explain_button.pressed.connect(func(): explain_pressed.emit())
	if _menu_button: _menu_button.pressed.connect(self._menu_button_pressed)
	
	strat_description = ""


func _menu_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
