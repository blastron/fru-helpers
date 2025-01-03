# A dependency task for a ScriptedSequence that waits for a specific signal to be emitted.
class_name WaitForSignalTask extends TaskDependency


var _bound_signal: Signal


func _init(in_signal: Signal):
	_bound_signal = in_signal
	_bound_signal.connect(self._handle_event)


func _handle_event():
	_bound_signal.disconnect(self._handle_event)
	task_completed.emit(self)