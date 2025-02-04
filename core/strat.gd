class_name Strat extends ScriptedSequence


# Common UI containers
@export var __ui: StratUi
@export var _arena: Arena


@export var _title_key: String
@export var _subtitle_key: String


var player_tokens: Array[PlayerToken]
var user_token: PlayerToken = null


enum Mode {
	EXPLANATION,			# Explaining the strat at a high level to the user using fixed information.
	TUTORIAL,				# TODO: Walking the user through the strat, showing them what they specifically should do.
	PRACTICE				# The user is playing through the mechanic without assistance.
}
var _mode : Mode = Mode.PRACTICE


enum State {
	SETTING_UP,				# Playing out the mechanic's setup step.
	WAITING_FOR_DECISION,	# Waiting for the user to make a decision about movement.
	PLAYER_MOVEMENT,		# Moving player tokens in direct response to the player's decision.
	RESOLVING,				# Playing out the mechanic's resolution step.
	FAILING,				# The user failed to execute the strat and we are resolving the results of that failure.
	STRAT_COMPLETE			# No further steps in the strat are available, either because of success or failure.
}


# Gets the name of the state for logging purposes.
func get_state_name(state: State) -> String:
	return State.keys()[state]


##########
## INITIALIZATION
##########


func _ready() -> void:
	# Reset temporary state on the player data, since we aren't doing a deep copy.
	for player in UserSettings.player_data:
		player.reset_temporary_state()
	
	# Bind to signals from the description pane.
	if __ui:
		__ui.description_panel.title = tr(_title_key) if _title_key else "Untitled Strat"
		__ui.description_panel.subtitle = tr(_subtitle_key) if _subtitle_key else ""
		
		# Bind to navigation events.
		__ui.description_panel.next_pressed.connect(self._nav_next)
		__ui.description_panel.prev_pressed.connect(self._nav_prev)
		__ui.description_panel.start_pressed.connect(self._nav_start)
		__ui.description_panel.reset_pressed.connect(self._nav_reset)
		__ui.description_panel.explain_pressed.connect(self._nav_explain)
		
		# Fill the party list.
		__ui.party_list.set_player_data(UserSettings.player_data)
		
	if _arena:
		# Start listening for clicks on the locators in the arena.
		_arena.locator_clicked.connect(self.__locator_pressed)
		
		# Create player tokens and save off which is the user-controlled one.
		player_tokens = _arena.create_player_tokens(UserSettings.player_data)
		for token in player_tokens:
			if token.player_data.user_controlled:
				user_token = token
				break
	
	# Call the super function after all setup has completed, in case the state machine tries to do something requiring
	#   specific setup to already be complete.
	super()
	
	
##########
## STATE MACHINE FLOW
##########


func jump_to_first_state() -> void:
	jump_to_state(0, State.SETTING_UP)


func on_state_entered(new_step: int, new_state: int, previous_step: int, previous_state: int) -> void:
	# Disable user input by default. Individual states should re-enable it as necessary.
	__deactivate_locators()
	__ui.description_panel.next_enabled = false
	__ui.description_panel.prev_enabled = false
	__ui.description_panel.start_enabled = false
	__ui.description_panel.explain_enabled = false
	
	match new_state:
		State.SETTING_UP:
			if _mode == Mode.EXPLANATION:
				# Show the explanation message for the current step.
				var explainer_message: Array[String] = _get_explainer_message(new_step)
				__ui.description_panel.strat_description = explainer_message

			# All setup logic happens during substeps, so we don't need to do anything here.
			pass
			
		State.WAITING_FOR_DECISION:
			__selected_locator = null
	
			if new_step == 0:
				# We're on the first step. We always assume here that the strat has a first step that does nothing but
				#   initial setup, and that no user decisions are actually necessary.
				__ui.description_panel.start_enabled = true
				__ui.description_panel.explain_enabled = true
				print("Waiting for start or explain button press...")
			else:
				match _mode:
					Mode.EXPLANATION:
						_show_explainer_arrows(new_step)
						
						# Wait for the user to press the Next button.
						__ui.description_panel.next_enabled = true
						print("Waiting for next button press on step %d..." % new_step)
					Mode.TUTORIAL, Mode.PRACTICE:
						# Activate any locators associated with this step.
						if __try_activate_locators(new_step):
							print("Waiting for locator press on step %d..." % new_step)
						else:
							# No locators were activated, but we're still waiting for input. Show the Next button.
							__ui.description_panel.next_enabled = true
							print("Waiting for next button press on step %d..." % new_step)
			
		State.PLAYER_MOVEMENT:
			# Get the list of movements to perform.
			var user_selection: Locator = __selected_locator if _needs_user_decision(new_step) else null
			var movements: Dictionary = _get_actual_movements(new_step, user_selection)
		
			# Iterate through all players that have reported movement and move them to their selected locations.
			var total_moves: int = 0
			for key in movements.keys():
				var player_token: PlayerToken = key
				var destination: Locator = movements[key]
			
				add_dependency(player_token)
				player_token.move_to_locator(destination)
				total_moves += 1
			
			if total_moves <= 0:
				# No player movement is necessary. Skip straight to step resolution.
				print("No movement was necessary for step %d. Skipping to resolution." % new_step)
				jump_to_state(new_step, State.RESOLVING)
			else:
				print("Waiting on %d player movements for step %d..." % [total_moves, new_step])
			
				# Set a minimum amount of time for the player movement step.
				wait_for_duration(0.5)
			
				finish_state()
			
		State.RESOLVING:
			# All resolution logic happens during substeps, so we don't need to do anything here.
			pass
			
		State.FAILING:
			# All failure resolution logic happens during substeps, so we don't need to do anything here.
			pass
			
		State.STRAT_COMPLETE:
			if previous_state != State.FAILING:
				__ui.description_panel.strat_description = [tr("COMMON_STRAT_MESSAGE_COMPLETE")]
			
		_:
			assert(false, "Unknown state entered!")


func on_substep_entered(current_step: int, current_state: int, current_substep: int) -> void:
	match current_state:
		State.SETTING_UP:
			_enter_setup(current_step, current_substep)

		State.WAITING_FOR_DECISION:
			pass

		State.PLAYER_MOVEMENT:
			pass

		State.RESOLVING:
			_enter_resolution(current_step, current_substep)

		State.FAILING:
			_enter_failure(current_step, current_substep)

		State.STRAT_COMPLETE:
			pass

		_:
			assert(false, "Substep for unknown state entered!")
			finish_state()


func process_substep(current_step: int, current_state: int, current_substep: int, delta: float) -> void:
	match current_state:
		State.SETTING_UP:
			_process_setup(current_step, current_substep, delta)

		State.WAITING_FOR_DECISION:
			pass

		State.PLAYER_MOVEMENT:
			pass

		State.RESOLVING:
			_process_resolution(current_step, current_substep, delta)

		State.FAILING:
			_process_failure(current_step, current_substep, delta)

		State.STRAT_COMPLETE:
			pass

		_:
			assert(false, "Processing substep for unknown state!")
			finish_state()


func on_state_finished(current_step: int, current_state: int) -> void:
	match current_state:
		State.SETTING_UP:
			# Setup logic has finished. Check to see if we require player input.
			if current_step == 0:
				# Always wait for user decision on the first step, since we require the user to press the start button.
				jump_to_state(current_step, State.WAITING_FOR_DECISION)
			elif _mode == Mode.EXPLANATION:
				# In explainer mode, possibly pause for the player to press the Next button.
				if _should_pause_for_explanation(current_step): jump_to_state(current_step, State.WAITING_FOR_DECISION)
				else: jump_to_state(current_step, State.PLAYER_MOVEMENT)
			elif _needs_user_decision(current_step):
				# The strat wants the player to make a decision.
				jump_to_state(current_step, State.WAITING_FOR_DECISION)
			else:
				jump_to_state(current_step, State.PLAYER_MOVEMENT)
			
		State.WAITING_FOR_DECISION:
			if _mode == Mode.EXPLANATION:
				# Remove all explainer elements.
				_arena.clear_explainers()
		
			# TODO: handle undo
			var valid_movements: Dictionary = _get_valid_movements(current_step)
			var user_locators = valid_movements[user_token] if valid_movements.has(user_token) else []
			if __selected_locator and not user_locators.has(__selected_locator):
				# The user selected the incorrect locator. Mark it as incorrect, then highlight the valid locators.
				if __selected_locator:
					__selected_locator.state = Locator.State.INCORRECT
		
				for valid_locator in _get_failure_hint_movements(current_step):
					valid_locator.state = Locator.State.CORRECT
		
				# Show the error message.
				var failure_message: Array[String] = _get_failure_message(current_step, __selected_locator)
				__ui.description_panel.strat_description = failure_message
			
				# Skip to failure resolution.
				jump_to_state(current_step, State.FAILING)
				
			else:
				# Either no actual decision needed to be made or the user made the correct decision.
				jump_to_state(current_step, State.PLAYER_MOVEMENT)
			
		State.PLAYER_MOVEMENT:
			# Player movement has finished. Start resolving the mechanic.
			jump_to_state(current_step, State.RESOLVING)
			
		State.RESOLVING:
			# Resolution has finished.
			var next_step_id: int = _get_next_step(current_step)
			if next_step_id >= 0:
				jump_to_state(next_step_id, State.SETTING_UP)
			else:
				# The user has completed the strat.
				jump_to_state(current_step, State.STRAT_COMPLETE)
			
		State.FAILING:
			# Failure resolution has finished. Jump straight to completion, ignoring all remaining steps.
			jump_to_state(current_step, State.STRAT_COMPLETE)
			
		State.STRAT_COMPLETE:
			# TODO: handle undo
			pass
			
		_:
			assert(false, "Unknown state exited!")


# Either moves to the next step in the strat or jumps to Complete.
func _advance_step(current_step: int) -> void:
	var next_step_id: int = _get_next_step(current_step)
	if next_step_id >= 0:
		jump_to_state(next_step_id, State.SETTING_UP)
	else:
		# The user has completed the strat.
		jump_to_state(current_step, State.STRAT_COMPLETE)
	


##########
## EXPLANATION AND NAVIGATION
##########


func _nav_next() -> void:
	if _current_state == State.WAITING_FOR_DECISION:
		# We were waiting for a movement decisision. The next button submits a decision of "no decision".
		finish_state()


func _nav_prev() -> void:
	pass


func _nav_start() -> void:
	# We assume here that the only time the start button would be shown is if we have just finished the first setup step
	#   and are waiting for the user to acknowledge that they want to start.
	assert(__current_step == 0 and _current_state == State.WAITING_FOR_DECISION)
	finish_state()


func _nav_reset() -> void:
	get_tree().reload_current_scene()


func _nav_explain() -> void:
	# We assume here that the only time the explanation button would be shown would be at the very start of a strat.
	assert(__current_step == 0 and _current_state == State.WAITING_FOR_DECISION)
	
	_mode = Mode.EXPLANATION
	
	# Show the next button and show the setup step's explanation message.
	__ui.description_panel.next_enabled = true
	__ui.description_panel.start_enabled = false
	__ui.description_panel.explain_enabled = false
	
	var explainer_message: Array[String] = _get_explainer_message(__current_step)
	__ui.description_panel.strat_description = explainer_message


# Determines whether the "next" button should be shown at the current step in the explanation process. By default, tests
#   if that step prompts any player movements.
func _should_pause_for_explanation(step_id: int) -> bool:
	return !_get_valid_movements(step_id).is_empty()


# Gets the message to show to the player for this step in explanation mode. Returns an array of strings, which will be
#   joined together by a locale-appropriate sentence separator.
func _get_explainer_message(step_id: int) -> Array[String]:
	return ["Explanation for step %d" % step_id]


# Draws arrows indicating how tokens should move. By default, retrieves the list of valid movements and draws straight
#   lines from the token to its intended destination.
func _show_explainer_arrows(step_id: int) -> void:
	var valid_movements: Dictionary = _get_valid_movements(step_id)
	for token in valid_movements.keys():
		var possible_destinations: Array = valid_movements[token]
		for destination in possible_destinations:
			# Determine how long the arrow is.
			var relative_destination: Vector2  = destination.position - token.position
			var arrow_length: float = relative_destination.length()

			var minimum_arrow_length: float = 15
			if arrow_length < minimum_arrow_length:
				# The arrow is extremely short, indicating that no real movement is necessary.
				# TODO: Some sort of indication that no movement is necessary.
				pass
			else:
				# Determine how long the arrow is and where it should originate from. For the sake
				#   of visual clarity, we want the arrow to start slightly outside the player's
				#   radius and go until slightly before the destination point.
				var source_offset: float = 22
				var destination_offset: float = 10

				# If shortening the arrow would reduce it below the minimum length, reduce the
				#   offsets, bringing the start of the arrow closer to the token's center until it
				#   is as far away from the center as the end of the arrow is away from the target,
				#   then bring both of those together equally.
				var adjusted_arrow_length: float = arrow_length - source_offset - destination_offset
				var spillover: float = minimum_arrow_length - adjusted_arrow_length
				if spillover > 0:
					# Reduce the source offset until it equals the destination offset.
					var reduction: float = min(source_offset - destination_offset, spillover)
					spillover -= reduction
					source_offset -= reduction
				if spillover > 0:
					# The arrow is still too short. Reduce the source and destination offsets
					#   equally.
					var reduction: float = min(source_offset + destination_offset, spillover)
					spillover -= reduction
					destination_offset -= reduction / 2
					source_offset -= reduction / 2

				# Determine where along the line the start and end of the arrow should lie.
				var arrow_direction: Vector2 = relative_destination.normalized()
				var points: Array[Vector2] = [
					token.position + arrow_direction * source_offset,
					destination.position - arrow_direction * destination_offset
				]
			
				# Add the arrow to the arena.
				_arena.add_explainer_arrow(points)


##########
## SETUP
##########


# Whether to use fixed data when determining random events in a mechanic.
func _use_fixed_data() -> bool:
	return _mode == Mode.EXPLANATION


# Called when each setup substep is entered.
func _enter_setup(step_id: int, substep_id: int) -> void:
	# Override this in your strat.
	assert(false, "_enter_setup must be overridden in a strat.")
	finish_state()


# Called every tick while setup is running.
func _process_setup(step_id: int, substep_id: int, delta: float) -> void:
	# Override this in your strat if you want any processing to happen.
	pass

	
##########
## MOVEMENT
##########


# Returns whether the user needs to make a decision on this step. By default, returns true if there are locators for the
#   player to click on.
func _needs_user_decision(step_id: int) -> bool:
	return !_get_active_locators(step_id).is_empty()


# Returns the list of locators that should be clickable in this step. Other locators will either be deactivated or
#   hidden depending on their configuration.
func _get_active_locators(step_id: int) -> Array[Locator]:
	# Override this in your strat.
	assert(false, "_get_active_locators() must be overridden in a strat.")
	return []


# Gets lists of valid locations that each player can move to. If a player either is not part of the output or if they
#   have an empty list of locations, it is assumed that they should not move. Conversely, if multiple locations are
#   returned, it is assumed that it is valid to send that player to any of them.
# Optionally, the locator selected by the user may be passed in to this function, so as to have movement decisions
#   respond to the user's choice. This function will still return a result for the player, and it may not necessarily
#   match the user's choice, depending on how the strat is authored.
# Returns a dictionary whose keys are PlayerTokens and whose values are Array[Locator].
func _get_valid_movements(step_id: int) -> Dictionary:
	# Override this in your strat.
	assert(false, "_get_valid_movements() must be overridden in a strat.")
	return {}


# Gets a specific location for each player to move to. By default, this queries _get_valid_movements() and picks the
#   closest locator to the token, except for the user's token, for which we will return the user's selection, if any.
# Strats may override this to provide different behavior based on the user's selection. Note that it is valid to have
#   the user's token go to a location other than their selection, if desired.
func _get_actual_movements(step_id: int, user_selection: Locator) -> Dictionary:
	var output: Dictionary = {}
	var valid_movements: Dictionary = _get_valid_movements(step_id)
	for key in valid_movements.keys():
		var player_token: PlayerToken = key
		if player_token.player_data.dead:
			# Dead players do not move.
			continue
	
		if player_token == user_token and user_selection != null:
			output[player_token] = user_selection
			continue
		
		if valid_movements[key].is_empty(): continue
	
		var destinations: Array[Locator]
		destinations.assign(valid_movements[key])

		if len(destinations) > 1:
			# In the case where multiple locations are valid, pick the one that is closest to the player's
			#   current position. We're assuming here that all returned locations are equally valid, and that
			#   any logic around avoiding combinations will have already happened in _get_valid_movements().
			destinations = sort_locators_by_distance(destinations, player_token.position, true)

		output[player_token] = destinations[0]
	
	return output


# Gets the locators to show as "correct" when the user has picked an incorrect location. By default, retrieves all
#   valid locators from _get_valid_movements().
func _get_failure_hint_movements(step_id: int) -> Array[Locator]:
	var output: Array[Locator] = []
	
	var valid_movements: Dictionary = _get_valid_movements(step_id)
	if user_token in valid_movements:
		output.assign(valid_movements[user_token])
	
	return output

	
##########
## LOCATORS
##########


# Activates the locators for the current step, as provided by get_active_locator_ids(). Returns whether any locators
#   were activated.
func __try_activate_locators(step_id: int) -> bool:
	var active_locators: Array[Locator] = _get_active_locators(step_id)
	var found_any_locators: bool = false
	for locator: Locator in _arena.get_locators():
		if locator.state in [Locator.State.INCORRECT, Locator.State.CORRECT]:
			# Don't change the state of locators we're using to show failure. We ideally shouldn't get here, as we don't
			#   want any user input after the user has made an incorrect choice.
			continue
		
		if locator in active_locators:
			locator.state = Locator.State.ENABLED
			found_any_locators = true
	
	if user_token != null and found_any_locators:
		user_token.input_highlight = true
	
	return found_any_locators


# Deactivates all locators.
func __deactivate_locators() -> void:
	if user_token != null:
		user_token.input_highlight = false

	for locator: Locator in _arena.get_locators():
		if locator.state in [Locator.State.INCORRECT, Locator.State.CORRECT]:
			# Don't reset locators we're using to show the results of a user decision. It's okay for us to get here even
			#   after failure, as we still want to be able to deactivate locators after the user's interaction.
			continue
		
		locator.state = Locator.State.DISABLED

		
func __locator_pressed(locator: Locator) -> void:
	if _current_state == State.WAITING_FOR_DECISION:
		__selected_locator = locator
		finish_state()


func __compare_locator_distance(a: Locator, b: Locator, query_location: Vector2, ascending: bool) -> bool:
	var dist_a: float = query_location.distance_squared_to(a.position)
	var dist_b: float = query_location.distance_squared_to(b.position)
	var a_closer: bool = dist_a < dist_b
	return a_closer if ascending else not a_closer


func sort_locators_by_distance(options: Array[Locator], query_location: Vector2, ascending: bool) -> Array[Locator]:
	var sort_lambda = func(a: Locator, b: Locator): return __compare_locator_distance(a, b, query_location, ascending)
	var sorted_options: Array[Locator] = options.duplicate()
	sorted_options.sort_custom(sort_lambda)
	return sorted_options


##########
## RESOLUTION
##########


# Called when each resolution substep is entered.
func _enter_resolution(step_id: int, substep_id: int) -> void:
	# Override this in your strat.
	assert(false, "_enter_resolution must be overridden in a strat.")
	finish_state()


# Called on every tick while resolution is running.
func _process_resolution(step_id: int, substep_id: int, delta: float) -> void:
	# Override this in your strat if you want any processing to happen.
	pass
	

##########
## FAILURE/COMPLETION
##########


# The last locator clicked by the user.
var __selected_locator: Locator = null


# The locators that should have been selected, but weren't. Used to highlight correct choices at the end of any
#   post-failure resolution operations.
var __valid_user_locators: Array[Locator]


# Gets index of the next step. Returns -1 if there is no next step to advance to, either because the strat is complete
#   or because the player failed the mechanic.
func _get_next_step(current_step: int) -> int:
	assert(false, "get_next_step() must be overridden within a strat subclass.")
	return -1


# Gets the message to show to the player once they failed. Returns an array of strings, which will be joined together by
#   a locale-appropriate sentence separator.
func _get_failure_message(step_id: int, user_selection: Locator) -> Array[String]:
	return ["Incorrect."]


# Gets the locator that the user selected that caused the failure.
func _get_incorrect_selection() -> Locator:
	return __selected_locator


# Called when each failure resolution substep is entered. By default, moves the player to their selected locator and
#   immediately exits without waiting for the movement to complete.
func _enter_failure(step_id: int, substep_id: int) -> void:
	if __selected_locator: user_token.move_to_locator(__selected_locator)
	finish_state()


# Called on every tick while failure resolution is running.
func _process_failure(step_id: int, substep_id: int, delta: float) -> void:
	# Override this in your strat if you want any processing to happen.
	pass
	

##########
## TOKENS
##########


# Finds the first token that has the given tag. If none exists, returns null.
func find_token_by_tag(tag: String) -> Token:
	var found_tokens: Array[Token] = find_tokens_by_tag(tag)
	return found_tokens[0] if not found_tokens.is_empty() else null


# Finds all tokens that have the given tag.
func find_tokens_by_tag(tag: String) -> Array[Token]:
	var found_tokens: Array[Node] = find_children("", "Token", true, false)
	var matching_tokens: Array[Token]

	for token in found_tokens:
		if token.has_tag(tag):
			matching_tokens.append(token)
	return matching_tokens


# Retrieves the token belonging to the player matching the given criteria
func get_player_token(role: PlayerData.Role, group: PlayerData.Group) -> PlayerToken:
	for token in player_tokens:
		if (token.player_data.role == role or token.player_data.detailed_role == role) and token.player_data.group == group:
			return token
	return null


# Get all tokens belonging to all players except the querier
func get_other_player_tokens(query_player: PlayerToken) -> Array[PlayerToken]:
	var output: Array[PlayerToken] = player_tokens.duplicate()
	var query_index: int = output.find(query_player)
	if query_index != -1:
		output.remove_at(query_index)
	return output


# Returns the subset of player tokens that are alive.
func filter_living_only(query_tokens: Array[PlayerToken]) -> Array[PlayerToken]:
	var output: Array[PlayerToken] = query_tokens.duplicate()
	output.filter(func(player: PlayerToken): return not player.player_data.dead)
	return output


# Casts an array of player tokens to an array of generic tokens.
func _downcast_player_tokens(tokens: Array[PlayerToken]) -> Array[Token]:
	var downcast_tokens: Array[Token]
	downcast_tokens.assign(tokens)
	return downcast_tokens


# Casts an array of generic tokens to an array of player tokens. Asserts if any token in the array is not a player.
func _upcast_player_tokens(tokens: Array[Token]) -> Array[PlayerToken]:
	var upcast_tokens: Array[PlayerToken]
	upcast_tokens.assign(tokens)
	return upcast_tokens
	
	
##########
## TASKS
##########


## INDICATORS


func wait_for_fade_in(indicator: Indicator, time: float) -> void:
	indicator.fade_in(time)
	add_dependency(indicator)
	
	
func wait_for_fade_out(indicator: Indicator, time: float) -> void:
	indicator.fade_out(time)
	add_dependency(indicator)


func wait_for_fade_in_out(indicator: Indicator, in_time: float, out_time: float) -> void:
	indicator.fade_in_out(in_time, out_time)
	add_dependency(indicator)


## TIMERS


func wait_for_duration(time: float) -> void:
	var timer: TimerTask = TimerTask.new(time)
	add_child(timer)
	add_dependency(timer)

	
## NAVIGATION EVENTS


# Temporarily enables the next button and adds clicking it as a dependency for the current substep.
func add_next_button_dependency() -> void:
	var signal_task: WaitForSignalTask = WaitForSignalTask.new(__ui.description_panel.next_pressed)
	add_dependency(signal_task)
	signal_task.task_completed.connect(self.__next_button_dependency_triggered)
	__ui.description_panel.next_enabled = true


func __next_button_dependency_triggered(task: WaitForSignalTask):
	__ui.description_panel.next_enabled = false
	task.task_completed.disconnect(self.__next_button_dependency_triggered)


##########
## QUERIES
##########


func __compare_token_distance(a: Token, b: Token, query_location: Vector2, ascending: bool) -> bool:
	var dist_a: float = query_location.distance_squared_to(a.position)
	var dist_b: float = query_location.distance_squared_to(b.position)
	var a_closer: bool = dist_a < dist_b
	return a_closer if ascending else not a_closer


func sort_tokens_by_distance(options: Array[Token], query_location: Vector2, ascending: bool) -> Array[Token]:
	var sort_lambda = func(a: Token, b: Token): return __compare_token_distance(a, b, query_location, ascending)
	var sorted_options: Array[Token] = options.duplicate()
	sorted_options.sort_custom(sort_lambda)
	return sorted_options
	

func __get_by_distance(options: Array[Token], in_quantity: int, query_location: Vector2, ascending: bool) -> Array[Token]:
	var sorted_options: Array[Token] = sort_tokens_by_distance(options, query_location, ascending)
	var quantity: int = min(in_quantity, len(sorted_options))
	return sorted_options.slice(0, quantity)


func filter_closest(options: Array[Token], quantity: int, query_location: Vector2) -> Array[Token]:
	return __get_by_distance(options, quantity, query_location, true)


func filter_farthest(options: Array[Token], quantity: int, query_location: Vector2) -> Array[Token]:
	return __get_by_distance(options, quantity, query_location, false)


func filter_in_cone(options: Array[Token], position: Vector2, rotation: float, radius: float, arc_width: float) -> Array[Token]:
	var forward: Vector2 = Vector2(cos(rotation), sin(rotation))
	var half_arc_width: float = arc_width / 2
	
	var output: Array[Token]
	for option in options:
		var option_vector: Vector2 = option.position - position
		var option_angle: float = option_vector.angle_to(forward)
		if abs(option_angle) <= half_arc_width:
			output.append(option)
		
	return output
