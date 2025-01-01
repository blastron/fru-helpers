class_name DescriptionPanel extends Control


@export var _title: Label
@export var _mechanic_description: RichTextLabel
@export var _strat_description: RichTextLabel
@export var _next_button: Button
@export var _prev_button: Button
@export var _start_button: Button
@export var _reset_button: Button


var next_enabled: bool:
	get: return not _next_button.disabled if _next_button else false
	set(value): if _next_button: _next_button.disabled = not value


var prev_enabled: bool:
	get: return not _prev_button.disabled if _prev_button else false
	set(value): if _prev_button: _prev_button.disabled = not value


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


var mechanic_description: String:
	get: return _mechanic_description.text if _mechanic_description else ""
	set(value):
		_mechanic_description.text = value
		_mechanic_description.visible = not value.is_empty()


var strat_description: String:
	get: return _strat_description.text if _strat_description else ""
	set(value):
		_strat_description.text = value
		_strat_description.visible = not value.is_empty()


func _ready() -> void:
	if _next_button: _next_button.pressed.connect(func(): next_pressed.emit())
	if _prev_button: _prev_button.pressed.connect(func(): prev_pressed.emit())
	if _start_button: _start_button.pressed.connect(func(): start_pressed.emit())
	if _reset_button: _reset_button.pressed.connect(func(): reset_pressed.emit())
