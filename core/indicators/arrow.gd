@tool
class_name Arrow extends Node2D


var _line_foreground: Line2D
var _head_foreground: Line2D

# Lines drawn beneath the foreground lines to serve as an outline.
var _line_background: Line2D
var _head_background: Line2D


@export var color: Color:
	get: return _line_foreground.default_color
	set(value):
		_line_foreground.default_color = value
		_head_foreground.default_color = value
		_update_alpha()


@export var border_color: Color:
	get: return _line_background.default_color
	set(value):
		_line_background.default_color = value
		_head_background.default_color = value
		_update_alpha()


@export var alpha: float = 1:
	get: return alpha
	set(value):
		alpha = value
		_update_alpha()


@export var width: float:
	get: return _line_foreground.width
	set(value):
		var cached_border_width: float = border_width
		_line_foreground.width = value
		_head_foreground.width = value
		_line_background.width = value + cached_border_width
		_head_background.width = value + cached_border_width


@export var border_width: float:
	get: return (_line_background.width - _line_foreground.width) / 2
	set(value):
		_line_background.width = _line_foreground.width + value * 2
		_head_background.width = _head_foreground.width + value * 2


@export var points: PackedVector2Array:
	get: return _line_foreground.points
	set(value):
		_line_foreground.set_points(value)
		_line_background.set_points(value)
		_update_head()


@export var head_size: float = 10:
	get: return head_size
	set(value):
		head_size = value
		_update_head()


func _init(_points: Array[Vector2] = [Vector2(0, 0), Vector2(100, 0)]) -> void:
	# Add background lines.
	_line_background = Line2D.new()
	_line_background.closed = false
	add_child(_line_background)
	
	_head_background = Line2D.new()
	_head_background.closed = false
	add_child(_head_background)
	
	# Add foreground lines.
	_line_foreground = Line2D.new()
	_line_foreground.closed = false
	add_child(_line_foreground)
	
	_head_foreground = Line2D.new()
	_head_foreground.closed = false
	add_child(_head_foreground)
	
	points = _points
	color = Color.WHITE
	border_color = Color.BLACK
	width = 3
	border_width = 2


func _update_head() -> void:
	if len(points) < 2 or head_size <= 0 or (points[-2] - points[-1]).is_zero_approx():
		_head_foreground.clear_points()
		_head_background.clear_points()
		return
	
	# Get vectors pointing in the direction of the arrow and tangential to it, scaled to match the head size. We
	#   multiply the size by sqrt(2)/2 here so that the final lines, which are at 45 degrees, are sized correctly.
	var head_forward: Vector2 = (points[-1] - points[-2]).normalized() * (head_size * sqrt(2) / 2)
	var head_tangent: Vector2 = Vector2(-head_forward.y, head_forward.x)
	
	# Generate the list of points:
	var head_points: Array[Vector2] = [
		points[-1] - head_forward - head_tangent,	# Back and to the left
		points[-1],									# At the tip of the arrow
		points[-1] - head_forward + head_tangent	# Back and to the right
	]
	
	_head_foreground.set_points(head_points)
	_head_background.set_points(head_points)

	
func _update_alpha():
	_line_foreground.default_color.a = alpha
	_head_foreground.default_color.a = alpha

	_line_background.default_color.a = alpha
	_head_background.default_color.a = alpha
