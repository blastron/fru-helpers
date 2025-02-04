class_name SexApocTracer extends Node2D


var is_arc: bool = true
var clockwise: bool = true
var completion_cap: float = -1

const _arc_radius: float = 215
const _arc_width: float = PI / 4

const _travel_duration: float = 1.5
const _trail_length: float = 0.25 # How far behind the end of the trail is from the front, as a fraction of travel time.

const _fade_in_time: float = 0.5
const _fade_out_time: float = 0.5

const _num_circles: int = 20
var _circles: Array[Polygon2D]

const _circle_max_radius: float = 10
const _circle_min_radius: float = 5

const _circle_color: Color = Color(1.0, 1.0, 1.0)
const _circle_max_alpha: float = 0.4
const _circle_min_alpha: float = 0.05

var _completion_percent: float = 0


func _init():
	for circle_index in _num_circles:
		var ratio: float = float(circle_index) / (_num_circles - 1)
		var radius: float = lerp(_circle_max_radius, _circle_min_radius, ratio)
		var alpha: float = lerp(_circle_max_alpha, _circle_min_alpha, ratio)
		
		var circumference: float = 2 * PI * radius
		var num_segments: int = max(16, ceil(circumference / 5.0))
		var segment_arc_width: float = 2 * PI / num_segments
		
		var points: Array[Vector2]
		var current_angle: float = 0
		for count in num_segments:
			var x: float = sin(current_angle) * radius
			var y: float = -cos(current_angle) * radius
			points.append(Vector2(x, y))
	
			current_angle += segment_arc_width
		
		var circle = Polygon2D.new()
		_circles.append(circle)
		circle.set_polygon(points)
		circle.color = _circle_color
		circle.color.a *= alpha
		add_child(circle)


func _process(delta: float) -> void:
	if completion_cap > 0 && _completion_percent <= completion_cap:
		_completion_percent = min(_completion_percent + delta / _travel_duration, completion_cap)
	else: _completion_percent += delta / _travel_duration
	
	for circle_index in _num_circles:
		var circle: Polygon2D = _circles[circle_index]
		
		var relative_completion: float = _completion_percent - _trail_length * circle_index / (_num_circles - 1)
		if relative_completion < 0:
			circle.visible = false
		elif relative_completion > 1:
			circle.visible = false
			
			# The last circle has faded out. Delete the indicator.
			if circle_index == _num_circles - 1:
				queue_free()
		elif is_arc:
			circle.visible = true
		
			var current_angle: float = _arc_width * relative_completion
			if !clockwise: current_angle *= -1
		
			var x: float = sin(current_angle) * _arc_radius
			var y: float = -cos(current_angle) * _arc_radius
		
			circle.position = Vector2(x, y)
		else:
			circle.visible = true
			circle.position = Vector2(0, _arc_radius * relative_completion)
