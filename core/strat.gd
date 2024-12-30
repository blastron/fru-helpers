class_name Strat extends ScriptedSequence


# UI elements
@export var description_pane: DescriptionPane

# Layers
@export var indicator_layer: Node2D
@export var token_layer: Node2D
@export var player_layer: Node2D

# Subscene types
@export var __player_token_type: PackedScene


var player_tokens: Array[PlayerToken]
var user_token: PlayerToken = null


enum Mode {
	EXPLANATION,			# Explaining the strat at a high level to the user using fixed information.
	TUTORIAL,				# Walking the user through the strat, showing them what they specifically should do.
	PRACTICE				# The user is playing through the mechanic without assistance.
}
var _mode : Mode = Mode.PRACTICE


enum State {
	SETTING_UP,				# Playing out the mechanic's setup step.
	WAITING_FOR_DECISION,	# Waiting for the user to make a decision about movement.
	PLAYER_MOVEMENT,		# Moving player tokens in direct response to the player's decision.
	RESOLVING,				# Playing out the mechanic's resolution step.
	STRAT_FAILED,			# The user failed to execute the strat and we have paused to let them know this.
	STRAT_COMPLETE			# The strat was successfully completed.
}


# Gets the name of the state for logging purposes.
func get_state_name(state: State) -> String:
	match state:
		State.SETTING_UP:
			return "SETTING_UP"
		State.WAITING_FOR_DECISION:
			return "WAITING_FOR_DECISION"
		State.PLAYER_MOVEMENT:
			return "PLAYER_MOVEMENT"
		State.RESOLVING:
			return "STRAT_RESOLVING"
		State.STRAT_FAILED:
			return "STRAT_FAILED"
		State.STRAT_COMPLETE:
			return "STRAT_COMPLETE"
	return "UNKNOWN"


# The last locator clicked by the user.
var __selected_locator: Locator = null
# The locator the user should have selected.
var __intended_locator: Locator = null


##########
## INITIALIZATION
##########


func _ready() -> void:
	# Bind to signals from the description pane.
	description_pane.next_button.pressed.connect(self._nav_next)
	description_pane.prev_button.pressed.connect(self._nav_prev)
	
	# Bind to the on-click signals for all locators.
	for locator: Locator in find_children("", "Locator"):
		locator.on_clicked.connect(self.__locator_pressed)
	
	# Create common objects from configuration data.
	__create_player_tokens()
	
	# Call the super function after all setup has completed, in case the state machine tries to do something requiring
	#   specific setup to already be complete.
	super()

	
func __create_player_tokens() -> void:
	for player_data in UserSettings.get_player_data():
		var new_token: PlayerToken = __player_token_type.instantiate()
		new_token.player_data = player_data
		if player_data.user_controlled:
			user_token = new_token
	
		player_layer.add_child(new_token)
		player_tokens.append(new_token)
	
	
##########
## STATE MACHINE FLOW
##########


func jump_to_first_state() -> void:
	jump_to_state(0, State.SETTING_UP)


func on_state_entered(new_step: int, new_state: int, previous_step: int, previous_state: int) -> void:
	# Disable user input by default. Individual states should re-enable it as necessary.
	__deactivate_locators()
	description_pane.next_button.disabled = true
	
	match new_state:
		State.SETTING_UP:
			# All setup logic happens during substeps, so we don't need to do anything here.
			pass
			
		State.WAITING_FOR_DECISION:
			__selected_locator = null
		
			match _mode:
				Mode.EXPLANATION:
					# We're in explanation mode. Draw arrows indicating where each token should move next and wait for
					#   the user to press the Next button.
					description_pane.next_button.disabled = false
					print("Waiting for next button press on step %d..." % new_step)
				Mode.TUTORIAL, Mode.PRACTICE:
					# Activate any locators associated with this step.
					if __try_activate_locators():
						print("Waiting for locator press on step %d..." % new_step)
					else:
						# No locators were activated, but we're still waiting for input. Show the Next button.
						description_pane.next_button.disabled = false
						print("Waiting for next button press on step %d..." % new_step)
			
		State.PLAYER_MOVEMENT:
			# Iterate through all of our players and move them to their selected locations.
			var valid_movements: Dictionary = _get_valid_movements(new_step, __selected_locator)
			var total_moves: int = 0
			for key in valid_movements.keys():
				var destinations: Array[Locator]
				destinations.assign(valid_movements[key])
				if destinations.is_empty(): continue

				var player: PlayerToken = key
				if len(destinations) > 1:
					# In the case where multiple locations are valid, pick the one that is closest to the player's
					#   current position. We're assuming here that all returned locations are equally valid, and that
					#   any logic around avoiding combinations will have already happened in _get_valid_movements().
					destinations = sort_locators_by_distance(destinations, player.position, true)

				var selected_destination: Locator = destinations[0]
				
				add_dependency(player)
				total_moves += 1
				player.move_to_locator(selected_destination)
			
			if total_moves <= 0:
				# No player movement is necessary. Skip straight to step resolution.
				print("No movement was necessary for step %d. Skipping to resolution." % new_step)
				jump_to_state(new_step, State.RESOLVING)
			else:
				print("Waiting on %d player movements for step %d..." % [total_moves, new_step])
				finish_state()
			
		State.RESOLVING:
			# All resolution logic happens during substeps, so we don't need to do anything here.
			pass
			
		State.STRAT_FAILED:
			# todo
			pass
			
		State.STRAT_COMPLETE:
			# todo
			pass
			
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

		State.STRAT_FAILED:
			pass

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

		State.STRAT_FAILED:
			pass

		State.STRAT_COMPLETE:
			pass

		_:
			assert(false, "Processing substep for unknown state!")
			finish_state()


func on_state_finished(current_step: int, current_state: int) -> void:
	match current_state:
		State.SETTING_UP:
			# Setup logic has finished. Check to see if we require player input.
			if _needs_user_decision(current_step):
				jump_to_state(current_step, State.WAITING_FOR_DECISION)
			else:
				jump_to_state(current_step, State.PLAYER_MOVEMENT)
			
		State.WAITING_FOR_DECISION:
			# TODO: handle undo/restart
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
			
		State.STRAT_FAILED:
			# TODO: handle undo/restart
			pass
			
		State.STRAT_COMPLETE:
			# TODO: handle undo/restart
			pass
			
		_:
			assert(false, "Unknown state entered!")


##########
## DESCRIPTION PANEL AND NAVIGATION
##########


func _nav_prev() -> void:
	pass


func _nav_next() -> void:
	if _current_state == State.WAITING_FOR_DECISION:
		# We were waiting for a movement decisision. The next button submits a decision of "no decision".
		finish_state()


##########
## SETUP
##########


# Whether to use fixed data when determining random events in a mechanic.
func _use_fixed_data() -> bool:
	return _mode == Mode.EXPLANATION


func _enter_setup(step_id: int, substep_id: int) -> void:
	# Override this in your strat.
	assert(false, "_enter_setup must be overridden in a strat.")
	finish_state()


func _process_setup(step_id: int, substep_id: int, delta: float) -> void:
	# Override this in your strat if you want any processing to happen.
	pass

	
##########
## MOVEMENT
##########


# Returns whether the user needs to make a decision on this step. Override this in your strat.
func _needs_user_decision(step_id: int) -> bool:
	return step_id == 0 or _mode == Mode.EXPLANATION


# Gets lists of valid locations that each player can move to. If a player either is not part of the output or if they
#   have an empty list of locations, it is assumed that they should not move. Conversely, if multiple locations are
#   returned, it is assumed that it is valid to send that player to any of them.
# Optionally, the locator selected by the user may be passed in to this function, so as to have movement decisions
#   respond to the user's choice. This function will still return a result for the player, and it may not necessarily
#   match the user's choice, depending on how the strat is authored.
# Returns a dictionary whose keys are PlayerTokens and whose values are Array[Locator].
func _get_valid_movements(step_id: int, user_selection: Locator = null) -> Dictionary:
	# Override this in your strat.
	assert(false, "_get_valid_movements() must be overridden in a strat.")
	return {}

	
##########
## LOCATORS
##########


# Returns the list of locators that should be clickable in this step. Other locators will either be deactivated or
#   hidden depending on their configuration.
func _get_active_locators(step_id: int) -> Array[Locator]:
	# Override this in your strat.
	assert(false, "_get_active_locators() must be overridden in a strat.")
	return []


# Activates the locators for the current step, as provided by get_active_locator_ids(). Returns whether any locators
#   were activated.
func __try_activate_locators() -> bool:
	var active_locators: Array[Locator] = _get_active_locators(__current_step)
	var found_any_locators: bool = false
	for locator: Locator in find_children("", "Locator"):
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

	for locator: Locator in find_children("", "Locator"):
		locator.state = locator.initial_state

		
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


func _enter_resolution(step_id: int, substep_id: int) -> void:
	# Override this in your strat.
	assert(false, "_enter_resolution must be overridden in a strat.")
	finish_state()


func _process_resolution(step_id: int, substep_id: int, delta: float) -> void:
	# Override this in your strat if you want any processing to happen.
	pass
	

##########
## FAILURE/COMPLETION
##########


# Gets index of the next step. Returns -1 if there is no next step to advance to, either because the strat is complete
#   or because the player failed the mechanic.
func _get_next_step(step_id: int) -> int:
	assert(false, "get_next_step() must be overridden within a strat subclass.")
	return -1
	

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


func _downcast_player_tokens(tokens: Array[PlayerToken]) -> Array[Token]:
	var downcast_tokens: Array[Token]
	downcast_tokens.assign(tokens)
	return downcast_tokens
	
	
##########
## INDICATORS
##########


var __permanent_indicators: Dictionary


func __destroy_indicator(indicator_name: String, fade_time: float) -> void:
	if not __permanent_indicators.has(indicator_name):
		print("Attempted to remove an indicator %s, but none existed." % name)
		return

	var found_indicator: Indicator = __permanent_indicators[indicator_name]
	__permanent_indicators.erase(indicator_name)

	if fade_time > 0: add_dependency(found_indicator)
	
	
## CONES


func create_cone(indicator_name: String, position: Vector2, rotation: float, radius: float, arc_width: float,
		color: Color, lifespan: float = 0) -> Cone:
	var cone_name: String = "%s (cone)" % indicator_name
	
	if lifespan <= 0 and __permanent_indicators.has(cone_name):
		print("Attempted to create a permanent cone named %s, but an indicator with that name already existed." %
			indicator_name)
		return null	
	
	var cone: Cone = Cone.new(radius, arc_width, color, lifespan)
	cone.name = cone_name
	cone.position = position
	cone.rotation = rotation
	indicator_layer.add_child(cone)
	
	if lifespan <= 0: __permanent_indicators[cone_name] = cone
	else: add_dependency(cone)
	
	return cone

	
func destroy_cone(indicator_name: String, fade_time: float = 0) -> void:
	__destroy_indicator("%s (cone)" % indicator_name, fade_time)

	
## CIRCLES


func create_circle(indicator_name: String, position: Vector2, radius: float, invert: bool, color: Color,
		lifespan: float = 0) -> Circle:
	var circle_name: String = "%s (cone)" % indicator_name
	
	if lifespan <= 0 and __permanent_indicators.has(circle_name):
		print("Attempted to create a permanent circle named %s, but an indicator with that name already existed." %
		circle_name)
		return null

	var circle: Circle = Circle.new(radius, invert, color, lifespan)
	circle.name = "%s (circle)" % circle_name
	circle.position = position
	indicator_layer.add_child(circle)

	if lifespan <= 0: __permanent_indicators[circle_name] = circle
	else: add_dependency(circle)

	return circle


func destroy_pool(indicator_name: String, fade_time: float = 0) -> void:
	__destroy_indicator("%s (circle)" % indicator_name, fade_time)
	
	
## TETHERS
# TODO: should tethers be indicators?? probably


var __spawned_tethers: Dictionary


# Creates a tether between two tokens. If instant is set to false, adds the animation to the dependencies.
func create_tether(tether_name: String, token_a: Token, token_b: Token, color: Color, instant: bool = false) -> Tether:
	if __spawned_tethers.has(tether_name):
		print("Attempted to create a tether named %s, but one already existed." % tether_name)
		return null
	
	var new_tether: Tether = Tether.new(token_a, token_b, color, instant)
	new_tether.name = tether_name
	indicator_layer.add_child(new_tether)
	
	if not instant: add_dependency(new_tether)
	
	__spawned_tethers[tether_name] = new_tether
	return new_tether
	

# Destroys the tether with the given name. If instant is set to false, adds the animation to the dependencies.
func destroy_tether(tether_name: String, instant: bool = false) -> void:
	if not __spawned_tethers.has(tether_name):
		print("Attempted to destroy a tether named %s, but none existed." % tether_name)
		return
	
	var found_tether: Tether = __spawned_tethers[tether_name]
	__spawned_tethers.erase(tether_name)
	
	if not instant: add_dependency(found_tether)
	found_tether.destroy(instant)


# Finds a tether with the given name. Asserts if one is not found.
func find_tether(tether_name: String) -> Tether:
	assert(__spawned_tethers.has(tether_name), "Attempted to find a tether named %s, but none existed." % tether_name)
	return __spawned_tethers[tether_name]


## TIMERS


func set_delay(time: float) -> void:
	add_dependency(TimerTask.new(time))


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
