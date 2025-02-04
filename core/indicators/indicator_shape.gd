class_name IndicatorShape extends Indicator


var _border: Line2D
var _background: Polygon2D


var border_opacity: float = 1:
	get: return border_opacity
	set(value):
		border_opacity = value
		if _border: _border.default_color.a = _color.a * _alpha * border_opacity


var background_opacity: float = 0.5:
	get: return background_opacity
	set(value):
		background_opacity = value
		if _background: _background.color.a = _color.a * _alpha * background_opacity


# The color of the indicator. If this color has an alpha value, it will be multiplied by _alpha.
@export var _color: Color:
	get: return _color
	set(value):
		_color = value
		if _border:
			_border.default_color = _color
			_border.default_color.a *= border_opacity
			
		if _background:
			_background.color = _color
			_background.color.a *= background_opacity


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
	if _border: _border.default_color.a = _color.a * _alpha * border_opacity
	if _background: _background.color.a = _color.a * _alpha * background_opacity
