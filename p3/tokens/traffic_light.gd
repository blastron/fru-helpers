@tool
class_name TrafficLight extends EnemyToken


@export var _spinner: Spinner


var clockwise: bool:
	get: return _spinner.clockwise if _spinner else true
	set(value): if _spinner: _spinner.clockwise = value


var spinner_visible: bool = false:
	get: return spinner_visible
	set(value):
		spinner_visible = value
		if _spinner:
			if spinner_visible: _spinner.fade_in(0.5)
			else: _spinner.fade_out(0.5)


func _ready() -> void:
	super()
	
	if _spinner:
		_spinner._alpha = 0
