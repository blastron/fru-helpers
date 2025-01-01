class_name Locator extends Control


@export var _button: BaseButton
@export var _correct_icon: TextureRect
@export var _incorrect_icon: TextureRect


enum State { HIDDEN, DISABLED, ENABLED, CORRECT, INCORRECT }
var state: State = State.DISABLED:
	get: return state
	set(value):
		state = value
		
		if _button:
			_button.visible = state in [State.DISABLED, State.ENABLED]
			_button.disabled = state != State.ENABLED
			
		if _correct_icon: _correct_icon.visible = state == State.CORRECT
		if _incorrect_icon: _incorrect_icon.visible = state == State.INCORRECT


@export var initial_state: State = State.DISABLED


signal on_clicked(locator: Locator)


var occupants: Array[Token]


# The distance from the center that any tokens beyond the first who are at this locator should be moved, so as to avoid
#   tokens being placed directly on top of each other, for readability's sake.
@export var crowd_spacing: float = 5

# A random angle, set on _ready(), used as the starting point for crowd spacing.
var crowd_angle: float


func _ready() -> void:
	state = initial_state
	if _button: _button.pressed.connect(self.button_pressed)
	
	crowd_angle = randf_range(0, 2 * PI)

	
func button_pressed() -> void:
	on_clicked.emit(self)