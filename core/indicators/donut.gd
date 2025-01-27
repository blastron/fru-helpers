@tool
class_name Donut extends IndicatorShape


@export var _inner_radius: float = 50:
	get: return _inner_radius
	set(value):
		_inner_radius = value
		_update_points()


@export var _outer_radius: float = 100:
	get: return _outer_radius
	set(value):
		_outer_radius = value
		_update_points()


func _init(inner_radius: float, outer_radius: float, color: Color) -> void:
	super(color)

	_inner_radius = inner_radius
	_outer_radius = outer_radius


func _update_points() -> void:
	_border.clear_points()
	_background.set_polygon([])

	if _inner_radius <= 0 or _outer_radius <= _inner_radius:
		return
	
	# Draw two circles; first, clockwise at the outer radius, and second, counterclockwise at the inner radius.
	var points: Array[Vector2]
	points += _get_ring_points(_outer_radius, true)
	points += _get_ring_points(_inner_radius, false)

	_border.set_points(points)
	_background.set_polygon(points)


func _get_ring_points(radius: float, clockwise: bool) -> Array[Vector2]:
	# Determine the number of segments needed to smoothly draw the circle and the width of each segment.
	var circumference: float = 2 * PI * radius
	var num_segments: int = max(16, ceil(circumference / 5.0))
	var segment_arc_width: float = 2 * PI / num_segments

	# Build the list of points.
	var points: Array[Vector2]
	var current_angle: float = 0
	for count in num_segments + 1:
		var x: float = sin(current_angle) * radius
		var y: float = -cos(current_angle) * radius
		points.append(Vector2(x, y))

		current_angle += segment_arc_width if clockwise else -segment_arc_width
	
	return points
