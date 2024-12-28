class_name Strat extends ScriptedSequence

@export var description_pane: DescriptionPane

@export var indicator_layer: Node2D
@export var token_layer: Node2D
@export var player_layer: Node2D

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
				Mode.TUTORIAL:
					__activate_locators()
					print("Waiting for tutorial locator press on step %d..." % new_step)
				Mode.PRACTICE:
					__activate_locators()
					print("Waiting for locator press on step %d..." % new_step)
			
		State.PLAYER_MOVEMENT:
			# Retrieve movement orders. Note that we don't early-out if we have zero orders, as we want to run through
			#   the same code path as if all movements were completed, which will happen on the next tick.
			var movement_orders: Array[MovementOrder] = _get_movement_orders(new_step, __selected_locator)
				
			if movement_orders.is_empty():
				# No player movement is necessary. Skip straight to step resolution.
				print("No movement was necessary for step %d. Skipping to resolution." % new_step)
				jump_to_state(new_step, State.RESOLVING)
			else:
				# Issue movement orders to all tokens and mark them as dependencies. Then, since this step has no other
				#   logic to run, mark us as being finished.
				for movement_order in movement_orders:
					if movement_order.locator != null:
						add_dependency(movement_order.player)
						movement_order.player.move_to_locator(movement_order.locator)
				print("Waiting on %d player movements for step %d..." % [len(movement_orders), new_step])
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


# Returns whether the user needs to make a decision on this step.
func _needs_user_decision(step_id: int) -> bool:
	return _mode == Mode.EXPLANATION or not _get_permissible_moves(step_id).is_empty()

# Gets a list of locators that the user may move to during this step. By default, queries the list of movement orders
#   for this step and returns the one matching the user's token.
# If no moves are returned, the player is assumed to not have to make a movement decision on this step.
func _get_permissible_moves(step_id: int) -> Array[Locator]:
	if user_token == null:
		return []

	var output: Array[Locator]
	var movement_orders: Array[MovementOrder] = _get_movement_orders(step_id, null)
	for order in movement_orders:
		if order.player == user_token and order.locator != null:
			output.append(order.locator)
		
	return output

# Gets the locations players should move to during this step. Not all players need to have a location provided if they
#   do not need to move. Optionally, can read the selected locator so that if the user inputs an incorrect solution,
#   the other players can behave accordingly.
func _get_movement_orders(step_id: int, selected_locator: Locator = null) -> Array[MovementOrder]:
	# Override this in your strat.
	return []

	
##########
## LOCATORS
##########


func get_locator(name: String) -> Locator:
	var found_children: Array[Node] = find_children(name, "Locator")
	return null if found_children.is_empty() else found_children[0]

# Returns the IDs of the locators that should be clickable in this step. Other locators will either be deactivated or
#   hidden depending on their configuration.
func _get_active_locator_ids(step_id: int) -> Array[String]:
	return []

# Activates the locators for the current step, as provided by get_active_locator_ids().
func __activate_locators() -> void:
	if user_token != null:
		user_token.input_highlight = true
	
	var active_locators: Array[String] = _get_active_locator_ids(__current_step)
	for locator: Locator in find_children("", "Locator"):
		if locator.name in active_locators:
			locator.state = Locator.State.ENABLED

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
	
	
##########
## INDICATORS
##########


var __permanent_indicators: Dictionary


func __destroy_indicator(name: String, fade_time: float) -> void:
	if not __permanent_indicators.has(name):
		print("Attempted to remove an indicator %s, but none existed." % name)
		return

	var found_indicator: Indicator = __permanent_indicators[name]
	__permanent_indicators.erase(name)

	if fade_time > 0: add_dependency(found_indicator)
	
	
## CONES


func create_cone(name: String, position: Vector2, rotation: float, radius: float, arc_width: float, color: Color,
		lifespan: float = 0) -> Cone:
	if lifespan <= 0 and __permanent_indicators.has(name):
		print("Attempted to create a permanent cone named %s, but an indicator with that name already existed." % name)
		return null
	
	var cone: Cone = Cone.new(radius, arc_width, color, lifespan)
	cone.name = "%s (cone)" % name
	cone.position = position
	cone.rotation = rotation
	indicator_layer.add_child(cone)
	
	if lifespan <= 0: __permanent_indicators[name] = cone
	else: add_dependency(cone)
	
	return cone

	
func destroy_cone(name: String, fade_time: float = 0) -> void:
	__destroy_indicator(name, fade_time)

	
## CIRCLES


func create_circle(name: String, position: Vector2, radius: float, invert: bool, color: Color, lifespan: float = 0) -> Circle:
	if lifespan <= 0 and __permanent_indicators.has(name):
		print("Attempted to create a permanent circle named %s, but an indicator with that name already existed." % name)
		return null

	var circle: Circle = Circle.new(radius, invert, color, lifespan)
	circle.name = "%s (circle)" % name
	circle.position = position
	indicator_layer.add_child(circle)

	if lifespan <= 0: __permanent_indicators[name] = circle
	else: add_dependency(circle)

	return circle


func destroy_pool(name: String, fade_time: float = 0) -> void:
	__destroy_indicator(name, fade_time)
	
	
## TETHERS
# TODO: should tethers be indicators?? probably


var __spawned_tethers: Dictionary


# Creates a tether between two tokens. If instant is set to false, adds the animation to the dependencies.
func create_tether(name: String, token_a: Token, token_b: Token, color: Color, instant: bool = false) -> Tether:
	if __spawned_tethers.has(name):
		print("Attempted to create a tether named %s, but one already existed." % name)
		return null
	
	var new_tether: Tether = Tether.new(token_a, token_b, color, instant)
	new_tether.name = name
	indicator_layer.add_child(new_tether)
	
	if not instant: add_dependency(new_tether)
	
	__spawned_tethers[name] = new_tether
	return new_tether
	

# Destroys the tether with the given name. If instant is set to false, adds the animation to the dependencies.
func destroy_tether(name: String, instant: bool = false) -> void:
	if not __spawned_tethers.has(name):
		print("Attempted to destroy a tether named %s, but none existed." % name)
		return
	
	var found_tether: Tether = __spawned_tethers[name]
	__spawned_tethers.erase(name)
	
	if not instant: add_dependency(found_tether)
	found_tether.destroy(instant)


# Finds a tether with the given name. Asserts if one is not found.
func find_tether(name: String) -> Tether:
	assert(__spawned_tethers.has(name), "Attempted to find a tether named %s, but none existed." % name)
	return __spawned_tethers[name]

## TIMERS

func set_delay(time: float) -> void:
	add_dependency(TimerTask.new(time))


##########
## QUERIES
##########


func __compare_distance(a: Token, b: Token, query_location: Vector2, ascending: bool) -> bool:
	var dist_a: float = query_location.distance_squared_to(a.position)
	var dist_b: float = query_location.distance_squared_to(b.position)
	var a_closer: bool = dist_a < dist_b
	return a_closer if ascending else not a_closer


func sort_by_distance(options: Array[Token], query_location: Vector2, ascending: bool) -> Array[Token]:
	var sort_lambda = func(a: Token, b: Token): return __compare_distance(a, b, query_location, ascending)
	var sorted_options: Array[Token] = options.duplicate()
	sorted_options.sort_custom(sort_lambda)
	return sorted_options
	

func __get_by_distance(options: Array[Token], in_quantity: int, query_location: Vector2, ascending: bool) -> Array[Token]:
	var sorted_options: Array[Token] = sort_by_distance(options, query_location, ascending)
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
