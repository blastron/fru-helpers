class_name TimerTask extends Node

signal task_completed(timer: TimerTask)

var _remaining_time: float = 1

func _init(time: float) -> void:
	_remaining_time = time
	
func _process(delta: float) -> void:
	_remaining_time -= delta
	if _remaining_time <= 0:
		task_completed.emit(self)
		queue_free()
