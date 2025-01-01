# A generalized state machine that repeatedly cycles through states based on a (probably) linear series of steps.
class_name ScriptedSequence extends Node


# The index of the step we are currently on.
var __current_step: int = -1

# The index of the state we are currently in within the step. If a sequence uses states, it is expected that it will
#   wrap this in an enum for clarity's sake.
var _current_state: int = -1

# The index of the substep within the state. Used so that a given stage within a step can execute several actions in
#   sequence while still remaining in the same logical state.
var __current_substep: int = 0

	
func _ready() -> void:
	pass # Replace with function body.

	
func _process(delta: float) -> void:
	# We haven't started anything yet. 
	if __current_step == -1:
		# Jump to the first state.
		__can_state_jump = true
		__did_state_jump = false
		jump_to_first_state()
		__can_state_jump = false
		assert(__did_state_jump, "Call to jump_to_first_state() did not result in a call to jump_to_state().")
		
		# If the jump call did not immediately mark the substep as complete, start it now.
		if not __substep_finished:
			print("STATE_MACHINE: Starting substep: %s" %
				describe_step(__current_step, _current_state, __current_substep))
			on_substep_entered(__current_step, _current_state, __current_substep)
	
		# Since we just changed states, exit now, so as to maintain the same general call pattern as when we change
		#   states after startup.
		return
	
	# If we haven't yet been asked to advance to the next substep, send it a tick. This may cause the substep to be
	#   marked as finished.
	if not __substep_finished:
		process_substep(__current_step, _current_state, __current_substep, delta)
	
	# If we still haven't been asked to advance, or if we have but still have outstanding dependencies, do nothing.
	if not __substep_finished or not __outstanding_dependencies.is_empty():
		return
		
	if not __state_finished:
		# We have not finished all substeps in the state. Move to the next substep.
		__current_substep += 1
		__substep_finished = false

		print("STATE_MACHINE: Starting substep: %s" % describe_step(__current_step, _current_state, __current_substep))
		on_substep_entered(__current_step, _current_state, __current_substep)
	else:
		__current_substep = 0
		__substep_finished = false
		__state_finished = false	
		
		# Finalize the current state, which will then cause us to jump to the next one.
		__can_state_jump = true
		__did_state_jump = false
		on_state_finished(__current_step, _current_state)
		__can_state_jump = false
		assert(__did_state_jump, "Call to on_state_substeps_finished() did not result in a call to jump_to_state().")

		# If the jump call did not immediately mark the substep as complete, start it now.
		if not __substep_finished:
			print("STATE_MACHINE: Starting substep: %s" %
				describe_step(__current_step, _current_state, __current_substep))
			on_substep_entered(__current_step, _current_state, __current_substep)

		
func describe_step(step: int, state: int, substep: int = -1) -> String:
	if substep >= 0:
		return "%s step %d (substep %d)" % [get_state_name(state), step, substep]
	else:
		return "%s step %d" % [get_state_name(state), step]
	
		
##########
## STATES
##########

# Get the name of the current state for logging purposes. Should be overridden by subclasses.
func get_state_name(state: int) -> String:
	return str(state)

# Call to jump to a different state. Should never be called outside of state transition events.
func jump_to_state(new_step: int, new_state: int) -> void:
	if not __can_state_jump:
		assert(false, "Can't call jump_to_state() outside of specific state transition contexts. Skipping.")
		return
	__did_state_jump = true
	
	var old_step: int = __current_step
	var old_state: int = _current_state
	__current_step = new_step
	_current_state = new_state
	
	print("STATE_MACHINE: %s transition: %s --> %s" % ["---- Step" if __current_step != old_step else "State",
		describe_step(old_step, old_state), describe_step(__current_step, _current_state)])
	
	on_state_entered(new_step, new_state, old_step, old_state)
	return # Must immediately return, since jump_to_state might wind up nested if a state immediately exits.
		
# Safety checks for tracking state transition behavior.
var __can_state_jump: bool = false
var __did_state_jump: bool = false

# Called after all setup is complete and we are ready to enter the first state.
func jump_to_first_state() -> void:
	assert(false, "jump_to_first_state() must be overridden within a sequence subclass.")

# Called when the state is first entered. It is valid to call jump_to_state() here to immediately leave the state, if
#   there are no substeps to process.
func on_state_entered(new_step: int, new_state: int, previous_step: int, previous_state: int) -> void:
	assert(false, "on_state_entered() must be overridden within a sequence subclass.")

# Called when all substeps in this state have completed. Something in here must call jump_to_state().
func on_state_finished(current_step: int, current_state: int) -> void:
	assert(false, "on_state_finished() must be overridden within a sequence subclass.")


##########
## SUBSTEPS
##########

var __substep_finished: bool = false
var __state_finished: bool = false

# Called when the given substep is first entered. Override this in your subclasses.
func on_substep_entered(current_step: int, current_state: int, current_substep: int) -> void:
	assert(false, "enter_substep() must be overridden within a sequence subclass.")
	finish_state()

# Called every tick while the given substep is active. Override this in your subclasses.
func process_substep(current_step: int, current_state: int, current_substep: int, delta: float) -> void:
	assert(false, "process_substep() must be overridden within a sequence subclass.")
	finish_state()

# Marks that all user scripting within the current substep is done, and that the state is ready to advance as soon as
#   its outstanding dependencies (if any) have been completed.
func finish_substep() -> void:
	assert(not __substep_finished, "finish_substep() called multiple times! Please only call this once.")
	
	if !__outstanding_dependencies.is_empty():
		print("STATE_MACHINE: %s is waiting on %d dependencies to complete: %s" %
			["Final substep" if __state_finished else "Substep", len(__outstanding_dependencies),
			describe_step(__current_step, _current_state, __current_substep)])
	else:
		print("STATE_MACHINE: %s complete: %s" % ["Final substep" if __state_finished else "Substep",
			describe_step(__current_step, _current_state, __current_substep)])
	
	__substep_finished = true
	
# Marks that all user scripting within the whole state is done, and that there are no further substeps to run.
func finish_state() -> void:
	__state_finished = true
	finish_substep()
	

##########
## DEPENDENCIES
##########

var __outstanding_dependencies: Array[Variant]

# Adds a dependency to the substep. Substeps will not complete as long as they have pending dependencies.
# NOTE: Dependencies must implement a task_completed(self) signal in order to be added to the list. 
func add_dependency(dependency: Variant) -> void:
	if dependency.has_signal("task_completed"):
		print("STATE_MACHINE: Adding dependency %s to current substep." % dependency)
		dependency.task_completed.connect(self.__dependency_completed)
		__outstanding_dependencies.append(dependency)
	else:
		assert(false, ("Tried to add object %s as a dependency, but it does not implement an task_completed " +
			"signal. Skipping.") % dependency)

# Triggered when a dependency fires task_completed.
func __dependency_completed(dependency: Variant) -> void:
	var dependency_index: int = __outstanding_dependencies.find(dependency)
	if dependency_index != -1:
		print("STATE_MACHINE: Dependency %s has completed. %d remaining." %
			[dependency, len(__outstanding_dependencies) - 1])
		__outstanding_dependencies.remove_at(dependency_index)
	else:
		assert(false, ("Received task_completed() from an object not tracked as a dependency. Ignoring and " +
			"unhooking." % dependency))

	dependency.task_completed.disconnect(self.__dependency_completed)
