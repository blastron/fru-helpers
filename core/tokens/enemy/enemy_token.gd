@tool
class_name EnemyToken extends Token


func _init() -> void:
	super()
	
	if Engine.is_editor_hint():
		_update_on_stage_visuals()
		return

		
func _ready() -> void:
	super()

	if Engine.is_editor_hint():
		return
		
	_on_stage_percent = 1 if on_stage else 0
	_update_on_stage_visuals()


func _process(delta: float) -> void:
	super(delta)
	
	if Engine.is_editor_hint():
		return
		
	_process_on_stage(delta)
	_process_facing(delta)


func has_outstanding_tasks() -> bool:
	return (super() or
		_is_in_stage_transition or
		_is_spinning
	)


##########
## ON-STAGE
##########


# Whether or not the token is present on the stage. Animates in and out when set. This is distinct from self.visible,
#   as visible is a binary visible/invisible check as opposed to this fade in/out check.
@export var on_stage: bool = true:
	get: return on_stage
	set(value):
		on_stage = value
		_update_on_stage_visuals()


var _on_stage_percent: float = 0
const _on_stage_speed: float = 10
const _on_stage_displacement: float = 50


var _is_in_stage_transition: bool :
	get: return (on_stage and _on_stage_percent < 1) or (not on_stage and _on_stage_percent > 0)


func _process_on_stage(delta: float) -> void:
	if on_stage and _on_stage_percent < 1:
		_on_stage_percent = min(1, _on_stage_percent + delta * _on_stage_speed)
		_update_on_stage_visuals()

		if _on_stage_percent == 1:
			_try_emit_completion()

	elif not on_stage and _on_stage_percent > 0:
		_on_stage_percent = max(0, _on_stage_percent - delta * _on_stage_speed)
		_update_on_stage_visuals()

		if _on_stage_percent == 0:
			_try_emit_completion()


func _update_on_stage_visuals() -> void:
	# If we're in the editor, show a semi-transparent icon to indicate we're on or off stage.
	if Engine.is_editor_hint():
		if icon: icon.self_modulate.a = 1.0 if on_stage else 0.3
		if hitbox: hitbox.self_modulate.a = 1.0 if on_stage else 0.3
		return
	
	var displacement: Vector2 = Vector2(0, -_on_stage_displacement * ease(1 - _on_stage_percent, 2))
	if icon: icon.position = displacement
	
	var alpha: float = ease(_on_stage_percent, 2)
	if icon: icon.self_modulate.a = alpha
	if hitbox: hitbox.self_modulate.a = alpha

	
##########
## MOVEMENT
##########

func move_to_position(new_position: Vector2, speed_override: float = -1) -> void:
	super(new_position, speed_override)
	
	if _is_moving:
		# Start spinning to face the angle of movement.
		face_direction(_get_movement_angle(), false)


func _get_movement_angle() -> float:
	if _is_moving:
		return _start_position.angle_to_point(Vector2(-_end_position.y, _end_position.x))
	return 0


# Move towards the target location, stopping when the edge of our hitbox touches it. If the location is already in the
#   target radius, moves forward a tiny little bit to emphasize that movement is occuring.
func approach_position(target_location: Vector2, radius_override: float = -1, speed_override: float = -1) -> void:
	var actual_radius: float = radius_override if radius_override > 0 else hitbox_radius
	
	var vector_to_target: Vector2 = target_location - position
	var travel_distance: float = vector_to_target.length()
	
	vector_to_target /= travel_distance
	travel_distance = max(travel_distance - actual_radius, 5)
	vector_to_target *= travel_distance

	move_to_position(position + vector_to_target, speed_override)


##########
## HITBOX AND FACING
##########


@export var hitbox_radius: float:
	get:
		return hitbox.radius if hitbox else 0.0
	set(value):
		if hitbox:
			hitbox.radius = value


@export var hitbox: Hitbox
@export var show_hitbox: bool = true:
	get:
		return hitbox.visible if hitbox != null else false
	set(value):
		if hitbox != null:
			hitbox.visible = value


@export var hitbox_angle: float = -PI / 2:
	get:
		return hitbox.rotation if hitbox != null else 0.0
	set(value):
		if hitbox != null:
			hitbox.rotation = wrapf(value, -PI, PI)


const _spin_rate: float = PI * 6
var _start_spin_angle: float
var _end_spin_angle: float
var _spin_elapsed_time: float
var _spin_total_time: float


var _is_spinning: bool :
	get: return _spin_elapsed_time < _spin_total_time


var _aggro_target: Node2D = null


func face_direction(angle: float, instant: bool = false):
	if instant:
		hitbox_angle = angle
		
		if _is_spinning:
			_spin_elapsed_time = 0
			_spin_total_time = 0
			_try_emit_completion()
	else:
		_start_spin_angle = hitbox_angle
		_end_spin_angle = wrapf(angle, -PI, PI)
		
		# Determine the shortest path between the current and target angle.
		var delta: float = _end_spin_angle - hitbox_angle
		if delta < -PI:
			delta += 2 * PI
			_end_spin_angle += 2 * PI
		elif delta > PI:
			delta -= 2 * PI
			_end_spin_angle -= 2 * PI
	
		_spin_total_time = abs(delta) / _spin_rate
		_spin_elapsed_time = 0
		
		# If we don't actually need to spin, immediately emit the completion event, just in case we've already been
		#   added as a dependency.
		if _spin_total_time <= 0:
			_try_emit_completion()


func face_location(location: Vector2, instant: bool = false):
	var angle: float = position.angle_to_point(location)
	face_direction(angle, instant)


func set_aggro_target(new_target: Node2D, snap_to_face: bool = false):
	if new_target == null:
		_aggro_target = null
		
		if _is_spinning:
			_spin_elapsed_time = 0
			_spin_total_time = 0
			_try_emit_completion()
	else:
		_aggro_target = new_target
		face_location(_aggro_target.position, snap_to_face)


func _process_facing(delta: float):
	if _is_spinning:
		_spin_elapsed_time += delta
		if _spin_elapsed_time < _spin_total_time:
			var elapsed_percent: float = _spin_elapsed_time / _spin_total_time
			var eased_percent: float = ease(elapsed_percent, -2.0)
			hitbox_angle = lerp_angle(_start_spin_angle, _end_spin_angle, eased_percent)
		else:
			hitbox_angle = _end_spin_angle
			_try_emit_completion()
	elif _is_moving:
		face_direction(_get_movement_angle())
	elif _aggro_target != null:
		# Snap to directly face the aggro target.
		face_location(_aggro_target.position, true)
