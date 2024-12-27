class_name Indicator extends Node2D


var _border: Line2D
var _background: Polygon2D

func _init(color: Color, lifespan: float = 0) -> void:
	# Create shapes.
	_background = Polygon2D.new()
	_background.invert_border = 10000
	add_child(_background)

	_border = Line2D.new()
	_border.width = 3
	_border.closed = true
	add_child(_border)

	if lifespan > 0:
		_lifespan = lifespan
		_remaining_lifespan = lifespan
		
	_color = color
	_update_points()


# The color of the cone. Alpha value is multiplied based on self._alpha.
@export var _color: Color:
	get: return _color
	set(value):
		_color = value
		_update_colors()

@export var _alpha: float = 1 :
	get: return _alpha
	set(value):
		_alpha = value
		_update_colors()

func _update_colors() -> void:
	_border.default_color = _color
	_border.default_color.a *= _alpha

	_background.color = _color
	_background.color.a *= _alpha * 0.5

func _update_points() -> void:
	pass

var _lifespan: float = 0
var _remaining_lifespan: float = 0
signal task_completed(shape: Indicator)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if _lifespan > 0 and _remaining_lifespan > 0:
		_remaining_lifespan -= delta
		_alpha = ease(clamp(_remaining_lifespan / _lifespan, 0, 1), 0.3)

		if _remaining_lifespan <= 0:
			task_completed.emit(self)
			queue_free()

func destroy(fade_time: float) -> void:
	if fade_time <= 0:
		queue_free()
	else:
		_lifespan = fade_time
		_remaining_lifespan = fade_time
