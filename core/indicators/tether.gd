class_name Tether extends Indicator


var _line: Line2D


var _anchor_a: Token
var _anchor_b: Token


@export var _color: Color:
	get: return _color
	set(value):
		_color = value
		if _line: _line.default_color = _color


func _init(anchor_a: Token, anchor_b: Token, color: Color) -> void:
	_anchor_a = anchor_a
	_anchor_b = anchor_b

	_line = Line2D.new()
	_line.closed = false
	_line.width = 4
	_line.set_points([
		_anchor_a.position if _anchor_a != null else Vector2(0,0),
		_anchor_b.position if _anchor_b != null else Vector2(0,0)
	])
	add_child(_line)
	
	_color = color
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)

	_line.set_point_position(0, _anchor_a.position if _anchor_a != null else Vector2(0,0))
	_line.set_point_position(1, _anchor_b.position if _anchor_b != null else Vector2(0,0))


func _update_alpha() -> void:
	_line.default_color.a = _color.a * _alpha
