# Stores information about a specific instance of a buff, such as its duration.
class_name BuffInstance extends RefCounted

var stack_count: int = 0:
	get: return stack_count
	set(value):
		if stack_count != value:
			stack_count = value
			stack_count_changed.emit(self)

var duration: int = 0:
	get: return duration
	set(value):
		if duration != value:
			duration = value
			duration_changed.emit(self)

signal stack_count_changed(data: BuffData)
signal duration_changed(data: BuffData)