@tool
class_name Beam extends IndicatorShape


@export var _length: float = 100 :
	get: return _length
	set(value):
		_length = value
		_update_points()

@export var _width: float = 20 :
	get: return _width
	set(value):
		_width = value
		_update_points()


func _init(length: float, width: float, color: Color) -> void:
	super(color)

	_length = length
	_width = width


func _update_points() -> void:
	_border.clear_points()
	_background.set_polygon([])
	
	if _length <= 0 or _width <= 0:
		return
	
	var half_width: float = _width / 2
	var points: Array[Vector2] = [
		Vector2(0, half_width),
		Vector2(0, -half_width),
		Vector2(_length, -half_width),
		Vector2(_length, half_width)
	]

	_border.set_points(points)
	_background.set_polygon(points)
	
