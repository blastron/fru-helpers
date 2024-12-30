class_name Token extends Node2D


@export var icon: Sprite2D


func _init() -> void:
	pass


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_tags = _initial_tags.duplicate(false)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	_process_movement(delta)


##########
## TAGS
##########


@export var _initial_tags: Array[String]
var _tags: Array[String]


func add_tag(tag: String) -> void:
	if not _tags.has(tag):
		_tags.append(tag)
		print("Added tag %s to token %s."%[tag, name])
		_on_tags_changed()
	else:
		print("Tried to add tag %s to token %s, but it already had it."%[tag, name])


func remove_tag(tag: String) -> void:
	var tag_index: int = _tags.find(tag)
	if tag_index > -1:
		_tags.remove_at(tag_index)
		print("Removed tag %s from token %s."%[tag, name])
		_on_tags_changed()
	else:
		print("Tried to remove tag %s from token %s, but it didn't have it."%[tag, name])


func has_tag(tag: String) -> bool:
	return _tags.has(tag)


func has_any_tag(tags: Array[String]) -> bool:
	for tag in tags:
		if _tags.has(tag):
			return true
	return false


func has_all_tags(tags: Array[String]) -> bool:
	for tag in tags:
		if not _tags.has(tag):
			return false
	return true


func _on_tags_changed() -> void:
	pass


##########
## TASKS
##########


# Fired when all outstanding tasks are completed.
signal task_completed(token: Token)


func _try_emit_completion():
	if not has_outstanding_tasks():
		task_completed.emit(self)


func has_outstanding_tasks() -> bool:
	return _is_moving


##########
## MOVEMENT
##########


# The speed, in units per second, that the token moves when given a move_to command.
@export var movement_speed: float = 500


var _start_position: Vector2
var _end_position: Vector2
var _movement_elapsed_time: float
var _movement_total_time: float


var current_locator: Locator:
	get: return _current_locator
var _current_locator: Locator


var _is_moving: bool :
	get: return _movement_elapsed_time < _movement_total_time


func _set_locator(locator: Locator) -> void:
	if _current_locator: _clear_locator()
	
	_current_locator = locator
	if _current_locator.occupants.find(self) < 0: _current_locator.occupants.append(self)
	

func _clear_locator() -> void:
	if _current_locator:
		# Remove ourselves from our current locator.
		var occupant_index: int = _current_locator.occupants.find(self)
		if occupant_index >= 0: _current_locator.occupants.remove_at(occupant_index)
		_current_locator = null


func teleport_to_locator(locator: Locator, pile_index: int = 0, pile_size: int = 0) -> void:
	teleport_to_position(_get_locator_position(locator, pile_index, pile_size))
	_set_locator(locator)
	
	

func move_to_locator(locator: Locator, pile_index: int = 0, pile_size: int = 0, speed_override: float = -1) -> void:
	move_to_position(_get_locator_position(locator, pile_index, pile_size), speed_override)
	_set_locator(locator)


func _get_locator_position(locator: Locator, pile_index: int, pile_size: int) -> Vector2:
	return locator.position


func teleport_to_position(new_position: Vector2) -> void:
	_clear_locator()
	
	position = new_position
	
	# If we were in the middle of a movement, end it.
	if _is_moving:
		_movement_elapsed_time = 0
		_movement_total_time = 0
		_try_emit_completion()


func move_to_position(new_position: Vector2, speed_override: float = -1) -> void:
	_clear_locator()
	
	_start_position = position
	_end_position = new_position

	# Determine how long it will take for the token to reach the target location based on its movement speed.
	var actual_speed: float = speed_override if speed_override > 0 else movement_speed
	_movement_elapsed_time = 0
	_movement_total_time = _start_position.distance_to(_end_position) / actual_speed
	
	# If we don't actually wind up moving anywhere, immediately emit the completion event, just in case we've already
	#   been added as a dependency.
	if _movement_total_time == 0:
		_try_emit_completion()


func _process_movement(delta: float) -> void:
	if not _is_moving:
		return
	
	# Ease between the start and end position. We do this instead of anything more video-gamey like tracking velocity
	#   and acceleration because this whole thing is a glorified slideshow.
	_movement_elapsed_time += delta
	if _movement_elapsed_time < _movement_total_time:
		var elapsed_percent: float = _movement_elapsed_time / _movement_total_time
		var eased_percent: float = ease(elapsed_percent, -2.0)
		position = _start_position.lerp(_end_position, eased_percent)
	else:
		position = _end_position
		_try_emit_completion()
