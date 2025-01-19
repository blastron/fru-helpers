@tool

class_name PlayerToken extends Token


@export var _background_container: Node2D:
	get: return _background_container
	set(value):
		if _background_container != value:
			_background_container = value
			_create_polygons()

@export var _radius: float:
	get: return _radius
	set(value):
		_radius = value
		_update_points()


@export var _editor_role: PlayerData.Role:
	get: return _editor_role
	set(value):
		_editor_role = value
		_player_role_changed()


@export var _editor_group: PlayerData.Group:
	get: return _editor_group
	set(value):
		_editor_group = value
		_player_role_changed()


const _circle_segment_length: float = 3
const _radius_jitter: float = 0.25


@export_group("Ring")

var _ring_outer: Polygon2D
const _ring_outer_color: Color = Color(0.52, 0.36, 0)
const _ring_outer_width: float = 1.5


var _ring: Polygon2D
const _ring_color: Color = Color(1.0, 0.79, 0.31)
const _ring_width: float = 2


var _ring_inner: Polygon2D
const _ring_inner_color: Color = Color(0.72, 0.49, 0.07)
const _ring_inner_width: float = 0.75


@export_group("Background")


var _fill: Polygon2D

const _fill_color_tank: Color = Color(0.3, 0.35, 0.68)
const _fill_color_tank_highlight: Color = Color(0.41568628, 0.4627451, 0.81960785)
const _fill_color_healer: Color = Color(0.3, 0.47, 0.26)
const _fill_color_healer_highlight: Color = Color(0.40784314, 0.6039216, 0.34509805)
const _fill_color_dps: Color = Color(0.67, 0.32, 0.27)
const _fill_color_dps_highlight: Color = Color(0.78431374, 0.3764706, 0.32156864)
const _fill_color_unknown: Color = Color(0.5, 0.5, 0.5)
const _fill_color_unknown_highlight: Color = Color(0.6, 0.6, 0.6)


@export_group("Role Icons")
@export var _icon_role_t1: Texture2D
@export var _icon_role_t2: Texture2D
@export var _icon_role_h1: Texture2D
@export var _icon_role_h2: Texture2D
@export var _icon_role_m1: Texture2D
@export var _icon_role_m2: Texture2D
@export var _icon_role_r1: Texture2D
@export var _icon_role_r2: Texture2D


const _icon_color: Color = Color(1.0, 0.79, 0.31)
const _icon_color_highlight: Color = Color(1.0, 0.85, 0.59)


var player_data: PlayerData = null:
	get: return player_data
	set(value):
		if player_data != null:
			# We are already associated with player data. Unsubscribe from that now.
			player_data.role_changed.disconnect(self._player_role_changed)

		player_data = value
		player_data.role_changed.connect(self._player_role_changed)
		_player_role_changed()


var _role: PlayerData.Role:
	get:
		if Engine.is_editor_hint(): return PlayerData.simplify_detailed_role(_editor_role)
		elif player_data: return player_data.role
		else: return PlayerData.Role.NONE


var _group: PlayerData.Group:
	get:
		if Engine.is_editor_hint(): return _editor_group
		elif player_data: return player_data.group
		else: return PlayerData.Group.GROUP_ONE


var input_highlight: bool = false:
	get: return input_highlight
	set(value):
		input_highlight = value
		_update_colors()


func _init() -> void:
	print("haha")
	
	# Create background shapes.
	if _background_container:
		_create_polygons()
	

func _create_polygons() -> void:
	print("hahaha")
	_ring_outer = Polygon2D.new()
	_ring = Polygon2D.new()
	_ring_inner = Polygon2D.new()
	_fill = Polygon2D.new()
	
	_background_container.add_child(_ring_outer)
	_background_container.add_child(_ring)
	_background_container.add_child(_ring_inner)
	_background_container.add_child(_fill)
	
	_update_points()
	_update_colors()


func _update_points() -> void:
	if _background_container:
		var current_radius: float = _radius
		_build_circle(current_radius, _ring_outer)
		current_radius -= _ring_outer_width
		
		_build_circle(current_radius, _ring)
		current_radius -= _ring_width
		
		_build_circle(current_radius, _ring_inner)
		current_radius -= _ring_inner_width
		
		_build_circle(current_radius, _fill)
	

func _build_circle(radius: float, circle: Polygon2D) -> void:
	if radius <= 0:
		circle.set_polygon([])
		return

	# Determine the number of segments needed to smoothly draw the circle and the width of each segment.
	var circumference: float = 2 * PI * radius
	var num_segments: int = max(16, ceil(circumference / _circle_segment_length))
	var segment_arc_width: float = 2 * PI / num_segments
	
	# Get the minimum and maximum radius for the random factor.
	var rng = RandomNumberGenerator.new()
	var min_radius: float = radius - _radius_jitter
	var max_radius: float = radius + _radius_jitter
	var current_radius: float = radius
	
	# Build the list of points.
	var points: Array[Vector2]
	var current_angle: float = 0
	for count in num_segments:
		# Add a little bit of jitter to the radius, for the sake of charm, limiting the amount of jitter on a per-
		#   segment radius to the actual jitter amount.
		current_radius = rng.randf_range(max(min_radius, current_radius - _radius_jitter),
			min(max_radius, current_radius + _radius_jitter))
		
		var x: float = sin(current_angle) * current_radius
		var y: float = -cos(current_angle) * current_radius
		points.append(Vector2(x, y))
		
		current_angle += segment_arc_width
	
	circle.set_polygon(points)


func _update_colors() -> void:
	if _background_container:
		_ring_outer.color = _ring_outer_color
		_ring.color = _ring_color
		_ring_inner.color = _ring_inner_color
		
		match _role:
			PlayerData.Role.TANK:
				_fill.color = _fill_color_tank if not input_highlight else _fill_color_tank_highlight
			PlayerData.Role.HEALER:
				_fill.color = _fill_color_healer if not input_highlight else _fill_color_healer_highlight
			PlayerData.Role.MELEE, PlayerData.Role.RANGED:
				_fill.color = _fill_color_dps if not input_highlight else _fill_color_dps_highlight
			_:
				_fill.color = _fill_color_unknown if not input_highlight else _fill_color_unknown_highlight
	
	if icon:
		icon.self_modulate = _icon_color if not input_highlight else _icon_color_highlight


func _player_role_changed():
	if icon:
		match _role:
			PlayerData.Role.TANK:
				match _group:
					PlayerData.Group.GROUP_ONE:
						name = "player_T1"
						icon.texture = _icon_role_t1
					PlayerData.Group.GROUP_TWO:
						name = "player_T2"
						icon.texture = _icon_role_t2
			PlayerData.Role.HEALER:
				match _group:
					PlayerData.Group.GROUP_ONE:
						name = "player_H1"
						icon.texture = _icon_role_h1
					PlayerData.Group.GROUP_TWO:
						name = "player_H2"
						icon.texture = _icon_role_h2
			PlayerData.Role.MELEE:
				match _group:
					PlayerData.Group.GROUP_ONE:
						name = "player_M1"
						icon.texture = _icon_role_m1
					PlayerData.Group.GROUP_TWO:
						name = "player_M2"
						icon.texture = _icon_role_m2
			PlayerData.Role.RANGED:
				match _group:
					PlayerData.Group.GROUP_ONE:
						name = "player_R1"
						icon.texture = _icon_role_r1
					PlayerData.Group.GROUP_TWO:
						name = "player_R2"
						icon.texture = _icon_role_r2
			_:
				icon.texture = null
	
	_update_colors()
