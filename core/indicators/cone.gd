@tool
class_name Cone extends IndicatorShape
	

@export var _radius: float = 100 :
	get: return _radius
	set(value):
		_radius = value
		_update_points()

@export var _arc_width: float = PI / 2 :
	get: return _arc_width
	set(value):
		_arc_width = value
		_update_points()


func _init(radius: float, arc_width: float, color: Color) -> void:
	super(color)
	
	_radius = radius
	_arc_width = arc_width


func _update_points() -> void:
	_border.clear_points()
	_background.set_polygon([])
	
	if _arc_width <= 0:
		return

	# Add center point.
	_border.add_point(Vector2(0,0))
	_background.polygon.append(Vector2(0,0))

	# Determine the number of segments to draw along the outer radius of the cone.
	var draw_radius: float = _radius
	var num_segments: int
	if _radius <= 0:
		# The cone is unbounded. Just draw a cone with a huge radius but few points.
		draw_radius = 10000
		num_segments = 5
	else:
		# The cone has a fixed radius. Figure out the length of the arc, then determine the number of segments we need
		#   to draw it smoothly.
		var arc_length: float = _arc_width * _radius
		num_segments = ceil(arc_length / 5.0)

	# Determine the width of each segment.
	var segment_arc_width: float = _arc_width / num_segments

	# Add vertices. Note that we're adding one more point than the number of segments, since each segment is drawn
	#   between two points.
	var points: Array[Vector2]
	points.append(Vector2(0,0))
	
	var current_angle: float = -_arc_width / 2
	for count in num_segments + 1:
		var x: float = cos(current_angle) * draw_radius
		var y: float = sin(current_angle) * draw_radius
		points.append(Vector2(x, y))
		
		current_angle += segment_arc_width
	
	_border.set_points(points)
	_background.set_polygon(points)
