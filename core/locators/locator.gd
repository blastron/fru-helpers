class_name Locator extends Control


@export var show_when_inactive: bool = false


@export var _button: BaseButton
@export var _correct_icon: TextureRect
@export var _incorrect_icon: TextureRect


enum State { DISABLED, ENABLED, CORRECT, INCORRECT }
var state: State = State.DISABLED:
	get: return state
	set(value):
		var did_change: bool = state != value
		state = value
		
		if _button:
			_button.visible = state == State.ENABLED or (state == State.DISABLED and show_when_inactive)
			_button.disabled = state != State.ENABLED
			_button.mouse_default_cursor_shape = CURSOR_POINTING_HAND if state == State.ENABLED else CURSOR_ARROW
			
		if _correct_icon: _correct_icon.visible = state == State.CORRECT
		if _incorrect_icon: _incorrect_icon.visible = state == State.INCORRECT
		
		if did_change: state_changed.emit(self)


signal state_changed(locator: Locator)


signal on_clicked(locator: Locator)


var occupants: Array[Token]


# The distance from the center that any tokens beyond the first who are at this locator should be moved, so as to avoid
#   tokens being placed directly on top of each other, for readability's sake.
@export var crowd_spacing: float = 5

# A random angle, set on _ready(), used as the starting point for crowd spacing.
var crowd_angle: float


func _ready() -> void:
	if _correct_icon: _correct_icon.z_index = Arena._Layers.EXPLAINER
	if _incorrect_icon: _incorrect_icon.z_index = Arena._Layers.EXPLAINER
	
	state = State.DISABLED
	if _button: _button.pressed.connect(self.button_pressed)
	
	crowd_angle = randf_range(0, 2 * PI)

	
func button_pressed() -> void:
	on_clicked.emit(self)