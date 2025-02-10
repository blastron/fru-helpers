class_name Indicator extends Node2D


signal task_completed(shape: Indicator)


# Whether or not this indicator is important and should be sorted to the top of the Z-order.
signal importance_changed(indicator: Indicator)
var is_important: bool = false:
	get: return is_important
	set(value):
		if is_important != value:
			is_important = value
			importance_changed.emit(self)


# Whether this indicator is in a fixed position on the stage or if it's moving. Used to determine z-order.
func is_static_indicator() -> bool : return true


# Whether to destroy this indicator automatically on fade out.
@export var _permanent: bool = false


@export var _alpha: float = 1 :
	get: return _alpha
	set(value):
		_alpha = value
		_update_alpha()


func _update_alpha() -> void:
	pass


var __fade_in_time: float = 0
var __fade_out_time: float = 0
var __fade_percentage: float = 1


var label: String = ""


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	if __fade_in_time > 0:
		__fade_percentage += delta / __fade_in_time
		if __fade_percentage >= 1:
			__fade_in_time = 0
			__fade_percentage = 1
		
			_alpha = 1
		
			if __fade_out_time <= 0:
				# We're only fading in. Emit task completion.
				task_completed.emit(self)
			
		else:
			_alpha = ease(clamp(__fade_percentage, 0, 1), 0.3)
	
	elif __fade_out_time > 0:
		__fade_percentage -= delta / __fade_out_time
		if __fade_percentage <= 0:
			# We've finished fading out.
			task_completed.emit(self)
		
			if !_permanent:
				# We're set to destroy ourselves after fade out. Try to remove the indicator from the arena it's in,
				#   if any.
				var did_remove_from_arena: bool = false
				var current_parent: Node = get_parent()
				while current_parent:
					if current_parent is Arena:
						did_remove_from_arena = true
						current_parent.remove_indicator(self)
						break
					else: current_parent = current_parent.get_parent()
				
				# The indicator was not in an arena. Destroy it directly.
				if not did_remove_from_arena: queue_free()
		else:
			_alpha = ease(clamp(__fade_percentage, 0, 1), 0.3)


func fade_in(time: float) -> void:
	__fade_percentage = 0
	__fade_in_time = time
	_alpha = 0


func fade_out(time: float) -> void:
	__fade_percentage = 1
	__fade_out_time = time
	_alpha = 1
	

func fade_in_out(in_time: float, out_time: float) -> void:
	__fade_percentage = 0
	__fade_in_time = in_time
	__fade_out_time = out_time
	_alpha = 0
