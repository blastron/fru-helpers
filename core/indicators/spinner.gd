@tool
class_name Spinner extends Indicator

const num_arrows: int = 3

const color_cw: Color = Color(1.0, 0.9, 0.2)
const color_ccw: Color = Color(0.2, 0.9, 1.0)


@export var radius: float = 100:
	get: return radius
	set(value):
		radius = value
		_update_points()


@export var clockwise: bool = true:
	get: return clockwise
	set(value):
		clockwise = value
		scale.x = 1 if clockwise else -1
		_set_colors()


var _arrows: Array[Arrow]


func _init() -> void:
	# Make a number of arrows and heads that matches num_arrows, each of them rotated so as to evenly space them out.
	var spacing: float = 2 * PI / num_arrows
	for arrow_index in num_arrows:
		var current_rotation: float = spacing * arrow_index
		var new_arrow: Arrow = Arrow.new()
		new_arrow.rotation = current_rotation
		add_child(new_arrow)
		_arrows.append(new_arrow)
	
	_update_points()
	_set_colors()


func _set_colors() -> void:
	for arrow in _arrows:
		arrow.color = color_cw if clockwise else color_ccw


func _update_points() -> void:
	# Determine the arc width for the arrow.
	var arc_width: float = (2 * PI / num_arrows) * .75
	
	# Determine the number of segments to draw for the circle.
	var arc_length: float = arc_width * radius
	var num_segments: int = ceil(arc_length / 5)
	
	# Determine the width of each segment.
	var segment_arc_width: float = arc_width / num_segments

	# Add vertices. Note that we're adding one more point than the number of segments, since each segment is drawn
	#   between two points.
	var points: Array[Vector2]

	var current_angle: float = 0
	for count in num_segments + 1:
		var x: float = cos(current_angle) * radius
		var y: float = sin(current_angle) * radius
		points.append(Vector2(x, y))

		current_angle += segment_arc_width
		
	# Set each arrow's points to the list we just generated. Each arrow has already been rotated, and these points are
	#   set in local space, so we don't need to do anything special to handle rotation. Also, the whole element is
	#   flipped horizontally depending on if we're clockwise or counterclockwise, so we don't need to worry about that
	#   either.
	for arrow in _arrows:
		arrow.points = points


func _update_alpha() -> void:
	for arrow in _arrows:
		arrow.alpha = _alpha
