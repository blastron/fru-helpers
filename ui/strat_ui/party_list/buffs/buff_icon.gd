class_name BuffIcon extends Control


@export var _icon: TextureRect
@export var _stack_label: Label
@export var _duration_label: Label


var data: BuffData:
	get: return data
	set(value):
		assert(value != null, "Can't assign null buff data.")
		assert(data == null, "Can't reassign buff data after first set.")
		if value == null or data != null: return

		data = value
		_icon.texture = data.icon if data.icon else null


var instance: BuffInstance:
	get: return instance
	set(value):
		assert(value != null, "Can't assign a null buff instance.")
		assert(instance == null, "Can't reassign the buff instance after first set.")
		if value == null or instance != null: return

		instance = value
		instance.stack_count_changed.connect(self._stack_count_changed)
		instance.duration_changed.connect(self._duration_changed)

		_stack_count_changed(instance)
		_duration_changed(instance)


func _stack_count_changed(_instance: BuffInstance):
	if _stack_label:
		_stack_label.text = str(instance.stack_count)
		_stack_label.visible = instance.stack_count > 0

		
func _duration_changed(_instance: BuffInstance):
	if _duration_label:
		_duration_label.text = str(instance.duration)
		_duration_label.visible = instance.duration > 0
