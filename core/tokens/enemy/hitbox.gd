@tool

class_name Hitbox extends Node2D

const color: Color = Color(1, 0.1, 0.1)

@export var radius: float = 100:
	get: return radius
	set(value):
		radius = value
		_redraw_lines()

var _outer_line: Line2D
var _inner_line: Line2D
var _rear_line: Line2D

var _forward_arrow: Polygon2D
var _left_arrow: Polygon2D
var _right_arrow: Polygon2D

# Called when the node enters the scene tree for the first time.
func _init() -> void:
	_outer_line = Line2D.new()
	_outer_line.width = 3
	_outer_line.default_color = color
	add_child(_outer_line)
	
	_inner_line = Line2D.new()
	_inner_line.width = 1
	_inner_line.default_color = color
	add_child(_inner_line)

	_rear_line = Line2D.new()
	_rear_line.width = 1
	_rear_line.default_color = color
	add_child(_rear_line)

	_forward_arrow = Polygon2D.new()
	_forward_arrow.color = color
	add_child(_forward_arrow)

	_left_arrow = Polygon2D.new()
	_left_arrow.color = color
	add_child(_left_arrow)

	_right_arrow = Polygon2D.new()
	_right_arrow.color = color
	add_child(_right_arrow)
	
	_redraw_lines()


func _redraw_lines() -> void:
	# Draw arcs.
	var inner_radius_offset: float = radius * .2
	
	_outer_line.set_points(_generate_arc_points(radius, -.75 * PI, 1.5 * PI))
	_inner_line.set_points(_generate_arc_points(radius - inner_radius_offset, PI * -.75, 1.5 * PI))
	_rear_line.set_points(_generate_arc_points(radius + 1, -.75 * PI, -.5 * PI))
	
	# Draw front arrow.
	var front_arrow_base_arc: float = .05 * PI
	var front_arrow_length: float = radius * .2
	var front_arrow_wall_length: float = front_arrow_length * 0.3
	var front_arrow_wall_width: float = 0.9
	
	var forward_arrow_points: Array[Vector2]
	forward_arrow_points.append(Vector2(cos(front_arrow_base_arc) * radius, sin(front_arrow_base_arc) * radius))
	forward_arrow_points.append(Vector2(forward_arrow_points[0].x + front_arrow_wall_length,
										forward_arrow_points[0].y * front_arrow_wall_width))
	forward_arrow_points.append(Vector2(radius + front_arrow_length, 0))
	forward_arrow_points.append(Vector2(forward_arrow_points[1].x, -forward_arrow_points[1].y))
	forward_arrow_points.append(Vector2(forward_arrow_points[0].x, -forward_arrow_points[0].y))
	
	_forward_arrow.set_polygon(forward_arrow_points)

	
	# Draw side arrows.
	var side_arrow_width: float = inner_radius_offset * 0.6
	var side_arrow_center_y: float = radius - inner_radius_offset / 2
	var side_arrow_length: float = side_arrow_width * 0.8
	
	var right_arrow_points: Array[Vector2]
	right_arrow_points.append(Vector2(side_arrow_length * -.25, side_arrow_center_y + side_arrow_width / 2))
	right_arrow_points.append(Vector2(side_arrow_length * -.25, side_arrow_center_y - side_arrow_width / 2))
	right_arrow_points.append(Vector2(side_arrow_length * .75, side_arrow_center_y))

	_right_arrow.set_polygon(right_arrow_points)
	_left_arrow.set_polygon(_mirror_points(right_arrow_points))
	
	
	
	
	
func _generate_arc_points(arc_radius: float, starting_angle: float, arc_width: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	
	# Determine the number of segments needed to smoothly draw the arc and the width of each segment.
	var num_segments: int = ceil(abs(arc_width) * radius / 5.0)
	var segment_arc_width: float = arc_width / num_segments
	
	var current_angle: float = starting_angle
	for count in num_segments + 1:
		var x: float = cos(current_angle) * arc_radius
		var y: float = sin(current_angle) * arc_radius
		points.append(Vector2(x, y))
		
		current_angle += segment_arc_width
	
	return points

func _mirror_points(points: Array[Vector2]) -> Array[Vector2]:
	var mirrored_points: Array[Vector2] = []
	for point in points:
		mirrored_points.append(Vector2(point.x, -point.y))
	return mirrored_points
