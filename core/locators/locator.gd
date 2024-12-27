class_name Locator extends Control

signal on_clicked(locator: Locator)

enum State { HIDDEN, DISABLED, ENABLED }

@export var initial_state: State = State.DISABLED
var state: State = State.DISABLED:
	get:
		if not $"button".visible:
			return State.HIDDEN
		elif $"button".disabled:
			return State.DISABLED
		else:
			return State.ENABLED
	set(value):
		$"button".visible = value != State.HIDDEN
		$"button".disabled = value != State.ENABLED
		
func _ready() -> void:
	state = initial_state
	
	$"button".pressed.connect(self.button_pressed)

func button_pressed() -> void:
	on_clicked.emit(self)
