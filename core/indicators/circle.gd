@tool

class_name Circle extends Indicator


@export var _radius: float = 100:
	get: return _radius
	set(value):
		_radius = value
		_update_points()

# Whether this is an "in" or an "out".
@export var _invert: bool = false:
	get: return _background.invert_enabled
	set(value):
		_background.invert_enabled = value


func _init(radius: float, invert: bool, color: Color, lifespan: float) -> void:
	super(color, lifespan)

	_radius = radius
	_invert = invert
	

func _update_points() -> void:
	_border.clear_points()
	_background.set_polygon([])
	
	if _radius <= 0:
		return
	
	# Determine the number of segments needed to smoothly draw the circle and the width of each segment.
	var circumference: float = 2 * PI * _radius
	var num_segments: int = min(16, ceil(circumference / 5.0))
	var segment_arc_width: float = 2 * PI / num_segments

	# Build the list of points.
	var points: Array[Vector2]
	var current_angle: float = 0
	for count in num_segments:
		var x: float = sin(current_angle) * _radius
		var y: float = -cos(current_angle) * _radius
		points.append(Vector2(x, y))
		
		current_angle += segment_arc_width
	
	_border.set_points(points)
	_background.set_polygon(points)