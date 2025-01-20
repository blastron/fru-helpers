class_name IndicatorShape extends Indicator


var _border: Line2D
var _background: Polygon2D


const _background_opacity: float = 0.5


# The color of the indicator. If this color has an alpha value, it will be multiplied by _alpha.
@export var _color: Color:
	get: return _color
	set(value):
		_color = value
		if _border: _border.default_color = _color
		if _background:
			_background.color = _color
			_background.color.a *= _background_opacity


func _init(color: Color) -> void:
	# Create shapes.
	_background = Polygon2D.new()
	_background.invert_border = 10000
	add_child(_background)

	_border = Line2D.new()
	_border.width = 3
	_border.closed = true
	add_child(_border)

	_color = color


func _update_alpha() -> void:
	if _border: _border.default_color.a = _color.a * _alpha
	if _background: _background.color.a = _color.a * _alpha * _background_opacity
