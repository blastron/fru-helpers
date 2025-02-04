class_name SextupleApocalypse extends Strat


@export_group("Tokens")
@export var boss: EnemyToken


@export_group("Locators - Setup")
@export var locator_setup_W_NW: Locator
@export var locator_setup_W_NE: Locator
@export var locator_setup_W_SW: Locator
@export var locator_setup_W_SE: Locator

@export var locator_setup_E_NW: Locator
@export var locator_setup_E_NE: Locator
@export var locator_setup_E_SW: Locator
@export var locator_setup_E_SE: Locator

@export var locator_first_stack_W: Locator
@export var locator_first_stack_E: Locator


@export_group("Locators - Spirit Taker")
@export var locator_spirit_taker_W_NW: Locator
@export var locator_spirit_taker_W_NE: Locator
@export var locator_spirit_taker_W_SW: Locator
@export var locator_spirit_taker_W_SE: Locator

@export var locator_spirit_taker_E_NW: Locator
@export var locator_spirit_taker_E_NE: Locator
@export var locator_spirit_taker_E_SW: Locator
@export var locator_spirit_taker_E_SE: Locator


@export_group("Locators - Groups")
# Collections of locators that are radially symmetrical around the stage. Index 0 is northwest, making 0-3 the support
#   slices and 4-7 the DPS.
@export var slices: Array[SexApocLocatorGroup]


@export_group("Debuffs")
@export var _debuff_water: BuffData


var _cast_arena: P3ArenaSextupleApocalypse:
	get: return _arena


const _tag_group_support: String = "group_supports"
const _tag_group_dps: String = "group_dps"
const _tag_spirit_taker: String = "spirit_taker"


const _burst_flare_color: Color = Color(1.0, 1.0, 1.0, 0.75)
const _burst_marker_color: Color = Color(1.0, 1.0, 1.0, 0.5)

const _stage_transition_color: Color = Color(0.42745098, 0.43529412, 0.8039216)

const _darkest_dance_color: Color = Color(1.0, 0.87058824, 0.5529412)
const _eruption_puddle_color: Color = Color(0.69803923, 0.5254902, 1.0)
const _knockback_color: Color = Color(0.88235295, 0.36862746, 1.0)
const _spirit_taker_color: Color = Color(0.8980392, 0.1882353, 1.0)
const _water_puddle_color: Color = Color(0.3019608, 0.68235296, 0.92941177)


enum Step {
	INITIAL_SETUP,
	TIMER_ASSIGNMENTS_AND_SWAP,
	DETERMINE_SAFE_SPOT, # Ground pulses start going out and indicate CW/CCW.
	FIRST_STACK,
	SPIRIT_TAKER, # AOE baited on a random player
	ERUPTION, # AOEs on every player
	SECOND_STACK, # Bait in center
	DARKEST_DANCE, # Jump to farthest player
	KNOCKBACK,
	THIRD_STACK
}


# The slice where the first apoc explosion happens.
var _apoc_origin: int = 0


# Whether the apocalypse explosions proceed clockwise or counterclockwise.
var _clockwise: bool = false


# The slices where eruptions are baited.
var _support_eruption_slice: int:
	get: return _offset_slice(_apoc_origin, -1)
var _dps_eruption_slice: int:
	get: return _offset_slice(_apoc_origin, 3)


# Offsets a slice index by a given number of steps, respecting direction.
func _offset_slice(slice: int, steps: int) -> int:
	var direction: int = 1 if _clockwise else -1
	return wrap(slice + steps * direction, 0, 8)



##########
## SETUP
##########


func _enter_setup(step_id: int, substep_id: int) -> void:
	match step_id:
		Step.INITIAL_SETUP:
			# Place players on the starting setup markers.
			for player in player_tokens:
				player.teleport_to_locator(_get_default_setup_locator(player))
			
			_cast_arena.sa_mode = false
			_cast_arena.sa_percent = 0
		
			finish_state()
			
		Step.TIMER_ASSIGNMENTS_AND_SWAP:
			# Assign debuffs and determine swaps. First, build the list of possible debuffs, then shuffle it.
			var durations: Array[int] = [0, 0, 10, 10, 29, 29, 38, 38]
			durations.shuffle()
	
			# Assign debuffs to the DPS group in reverse swap priority order. Past the first assignment, if we assign
			#   something that's already been assigned, mark that player as needing to swap to the other group.
			var dps_order: Array[PlayerToken] = [
				get_player_token(PlayerData.Role.RANGED, PlayerData.Group.GROUP_TWO),
				get_player_token(PlayerData.Role.RANGED, PlayerData.Group.GROUP_ONE),
				get_player_token(PlayerData.Role.MELEE, PlayerData.Group.GROUP_TWO),
				get_player_token(PlayerData.Role.MELEE, PlayerData.Group.GROUP_ONE)
			]
			_assign_stacks(dps_order, durations.slice(0, 4), _tag_group_dps, _tag_group_support)
	
			# Do the same for the supports.
			var support_order: Array[PlayerToken] = [
				get_player_token(PlayerData.Role.HEALER, PlayerData.Group.GROUP_TWO),
				get_player_token(PlayerData.Role.HEALER, PlayerData.Group.GROUP_ONE),
				get_player_token(PlayerData.Role.TANK, PlayerData.Group.GROUP_TWO),
				get_player_token(PlayerData.Role.TANK, PlayerData.Group.GROUP_ONE)
			]
			_assign_stacks(support_order, durations.slice(4, 8), _tag_group_support, _tag_group_dps)
			
			finish_state()

		Step.DETERMINE_SAFE_SPOT:
			match substep_id:
				0:
					# Set initial variables.
					_apoc_origin = randi_range(0, 3)
					_clockwise = randi_range(0, 1)
		
					# Drop marker puddles at the starting locations.
					_place_apoc_setup_markers(0)
					wait_for_duration(1)
					
					finish_state()
				
				1: # TODO: Spin the first markers halfway.
					pass
			
		# No more setup! Everything else is handled in resolution.
		
		_: finish_state()


func _assign_stacks(players: Array[PlayerToken], durations: Array[int], group_tag: String, swap_tag: String) -> void:
	for index in range(4):
		var player: PlayerToken = players[index]
		var duration: int = durations[index]
		
		# If the duration is non-zero, apply the debuff.
		if duration != 0:
			var instance: BuffInstance = player.player_data.add_buff(_debuff_water)
			instance.duration = durations[index]
			
		# Test to see if any players we've already processed have the same duration this one does. If so, have them
		#   swap to the other group.
		var found_duplicate: bool = false		
		if index > 0:
			for previous_index in range(index):
				if durations[previous_index] == durations[index]:
					found_duplicate = true
					break
		player.add_tag(swap_tag if found_duplicate else group_tag)


func _get_apoc_indices_for_step(apoc_step: int) -> Array[int]:
	var output: Array[int]
	
	# Each step adds up to three pairs of explosions.
	var min_step: int = max(0, apoc_step - 2)
	for step in range(min_step, apoc_step + 1):
		output += [_offset_slice(_apoc_origin, step), _offset_slice(_apoc_origin, step + 4)]
		
	# Steps that don't have three pairs (namely, the first two) explode in the center.
	if apoc_step < 2:
		output.append(-1)
		
	return output


func _place_apoc_setup_markers(apoc_step: int):
	var step_slice_indices: Array[int] = _get_apoc_indices_for_step(apoc_step)
	
	for slice_index in step_slice_indices:
		var location: Vector2
		if slice_index == -1:
			location = Vector2(0, 0)
		else:
			location = slices[slice_index].flare_locator.position
		
		var flare: Circle = _arena.add_circle_indicator("apoc flare", 25, false, _burst_flare_color)
		flare.background_opacity = 1
		flare.position = location
		flare.fade_out(1)
		
		var marker_name: String = "apoc marker %d" % slice_index
		if _arena.get_indicator(marker_name) == null:
			var marker: Circle = _arena.add_circle_indicator(marker_name, 15, false, _burst_marker_color)
			marker.border_opacity = 0
			marker.background_opacity = 1
			marker.position = location


func _get_default_setup_locator(player: PlayerToken) -> Locator:
	var is_g1: bool = player.player_data.group == PlayerData.Group.GROUP_ONE
	match player.player_data.role:
		PlayerData.Role.HEALER: return locator_setup_W_NW if is_g1 else locator_setup_W_SW
		PlayerData.Role.TANK: return locator_setup_W_NE if is_g1 else locator_setup_W_SE
		PlayerData.Role.MELEE: return locator_setup_E_NW if is_g1 else locator_setup_E_SW
		PlayerData.Role.RANGED: return locator_setup_E_NE if is_g1 else locator_setup_E_SE
		_: return null


func _get_default_spirit_taker_locator(player: PlayerToken) -> Locator:
	var is_g1: bool = player.player_data.group == PlayerData.Group.GROUP_ONE
	match player.player_data.role:
		PlayerData.Role.HEALER: return locator_spirit_taker_W_NW if is_g1 else locator_spirit_taker_W_SW
		PlayerData.Role.TANK: return locator_spirit_taker_W_NE if is_g1 else locator_spirit_taker_W_SE
		PlayerData.Role.MELEE: return locator_spirit_taker_E_SW if is_g1 else locator_spirit_taker_E_NW
		PlayerData.Role.RANGED: return locator_spirit_taker_E_SE if is_g1 else locator_spirit_taker_E_NE
		_: return null
	


##########
## EXPLANATION
##########


func _should_pause_for_explanation(step_id: int) -> bool:
	return true


func _get_explainer_message(step_id: int) -> Array[String]:
	match step_id:
		Step.INITIAL_SETUP: return ["spread out in a rectangle"]
		Step.TIMER_ASSIGNMENTS_AND_SWAP: return ["check for duplicate assignments and swap as needed"]
		Step.DETERMINE_SAFE_SPOT: return ["look for the safe spot based on the first bursts and CW/CCW"]
		Step.FIRST_STACK: return ["stack up in your swap group"]
		Step.SPIRIT_TAKER: return ["spread out to take a single AOE"]
		Step.ERUPTION: return ["spread in the safe spots for eruption, in your original group"]
		Step.SECOND_STACK: return ["get back to the center and into your stack group"]
		Step.DARKEST_DANCE: return ["OT runs out to get stepped on :)"]
		Step.KNOCKBACK: return ["cluster behind the boss in your stack group for a knockback"]
		Step.THIRD_STACK: return ["group back up for the last stack"]
		
	return []


##########
## MOVEMENT
##########


#func _needs_user_decision(step_id: int) -> bool:
#	return false


func _get_active_locators(step_id: int) -> Array[Locator]:
	match step_id:
		Step.TIMER_ASSIGNMENTS_AND_SWAP:
			# For the sake of convenience, only return a single marker on each side, because in practice nobody has to
			#   know who exactly on the other team is swapping where.
			return [locator_first_stack_E, locator_first_stack_W]

		Step.FIRST_STACK, Step.SPIRIT_TAKER:
			# To be very mean, fake out the user with the ability to spread out during the stack or stack up during
			#   the spread.
			if user_token.has_tag(_tag_group_support):
				return [
					locator_first_stack_W,
					locator_spirit_taker_W_NW, locator_spirit_taker_W_NE,
					locator_spirit_taker_W_SW, locator_spirit_taker_W_SE,
				]
			else:
				return [
					locator_first_stack_E,
					locator_spirit_taker_E_NW, locator_spirit_taker_E_NE,
					locator_spirit_taker_E_SW, locator_spirit_taker_E_SE,
				]
		
		Step.ERUPTION:
			var output: Array[Locator]
			for locator_group in slices:
				output += locator_group.eruption_locators
			return output
		
		Step.SECOND_STACK: return [
			slices[_support_eruption_slice].second_stack_in,
			slices[_dps_eruption_slice].second_stack_in
		]
		
		Step.DARKEST_DANCE:
			# Only the OT moves during Darkest Dance.
			var t2_token: PlayerToken = get_player_token(PlayerData.Role.TANK, PlayerData.Group.GROUP_TWO)
			if user_token == t2_token:
				# Show all tank bait locators.
				var output: Array[Locator]
				for slice in slices:
					output.append(slice.tank_bait)
				return output
			else: return []
			
		Step.KNOCKBACK:
			# Get the locator the OT is at, then get the knockback locators from that locator's slice.
			var t2_token: PlayerToken = get_player_token(PlayerData.Role.TANK, PlayerData.Group.GROUP_TWO)
			var t2_locator: Locator = t2_token.current_locator
			for locator_group in slices:
				if locator_group.tank_bait == t2_locator:
					return [locator_group.kb_origin_east, locator_group.kb_origin_west]
			return []

	return []


func _get_valid_movements(step_id: int) -> Dictionary:
	match step_id:
		Step.TIMER_ASSIGNMENTS_AND_SWAP:
			if _mode == Mode.EXPLANATION:
				# In explainer mode, we want to show arrows indicating who swaps to where, so we run that logic here.
				return _get_swapped_spots(step_id)
				
			else:
				# When not explaining, we only show users two locators to click on, so as to focus on letting them
				#   determine whether or not to swap. We'll send them to the correct location after they've made their
				#   choice.
				var output: Dictionary
				for player in player_tokens:
					if player.has_tag(_tag_group_support): output[player] = [locator_first_stack_W]
					else: output[player] = [locator_first_stack_E]
				return output
		
		Step.FIRST_STACK:
			# All players condense into their stacks. This step is only reached in explainer mode; when the user is in
			#   control, they've already clicked on the stack they should go to, so this is redundant.
			var output: Dictionary
			for player in player_tokens:
				if player.has_tag(_tag_group_support): output[player] = [locator_first_stack_W]
				else: output[player] = [locator_first_stack_E]
			return output
			
		Step.SPIRIT_TAKER:
			# Send players to either their default or swapped spots.
			return _get_swapped_spots(step_id)
	
		Step.ERUPTION:
			var output: Dictionary
			for player in player_tokens:
				var slice_index: int = _support_eruption_slice if player.player_data.is_support else _dps_eruption_slice
				match player.player_data.role:
					PlayerData.Role.TANK, PlayerData.Role.MELEE:
						if player.player_data.group == PlayerData.Group.GROUP_TWO:
							# The player is in group 2, so they position themselves at the next slice over. We want them
							#   to wind up _almost_ at the next step over, so we have locators there, but we also don't
							#   want to show a huge pile of locators at each step. So, the "valid" movement for a player
							#   in practice mode is in the next slide over, but when we're in explainer mode or actually
							#   moving the token, we want to use the slightly closer locator.
							if _mode == Mode.EXPLANATION:
								var slice: SexApocLocatorGroup = slices[slice_index]
								output[player] = [slice.eruption_in_ccw if _clockwise else slice.eruption_in_cw]
							else:
								slice_index = _offset_slice(slice_index, -1)
								var slice: SexApocLocatorGroup = slices[slice_index]
								output[player] = [slice.eruption_in_center]
						else:
							var slice: SexApocLocatorGroup = slices[slice_index]
							output[player] = [slice.eruption_in_center]
					
					PlayerData.Role.HEALER, PlayerData.Role.RANGED:
						var slice: SexApocLocatorGroup = slices[slice_index]
						output[player] = [slice.eruption_out_cw if \
 							player.player_data.group == PlayerData.Group.GROUP_TWO else slice.eruption_out_ccw]
					_: pass
			
			return output
			
		Step.SECOND_STACK:
			var output: Dictionary = {}
			for player in player_tokens:
				var slice_index: int = \
 					_support_eruption_slice if player.has_tag(_tag_group_support) else _dps_eruption_slice
				output[player] = [slices[slice_index].second_stack_in]
			
			return output
		
		Step.DARKEST_DANCE:
			# The OT baits a leap where the first explosion landed, which is one over from the original safe spot. They
			#   should ideally go to the spot that's closer to where they currently are, but either spot is fine. The
			#   tank baits are 2 spots forward the original explosion, putting the bait spots 1 spot behind where the
			#   safe spots originally were.
			var t2_token: PlayerToken = get_player_token(PlayerData.Role.TANK, PlayerData.Group.GROUP_TWO)
			var current_slice: int = \
				_support_eruption_slice if t2_token.has_tag(_tag_group_support) else _dps_eruption_slice

			return {
				t2_token: [
					slices[_offset_slice(current_slice, -1)].tank_bait,
					slices[_offset_slice(current_slice, 3)].tank_bait
				]
			}
				
		Step.KNOCKBACK, Step.THIRD_STACK:
			# Get the locator the OT is at, then get the knockback locators from that locator's slice. This is the same
			#   for both positioning for the knockback and running back in for the third stack.
			var boss_locator: Locator = boss.current_locator
	
			var boss_slice: SexApocLocatorGroup
			for locator_group in slices:
				if locator_group.boss_leap == boss_locator:
					boss_slice = locator_group
					break
			
			var output: Dictionary = {}
			for player in player_tokens:
				output[player] = \
					[boss_slice.kb_origin_east if player.has_tag(_tag_group_support) else boss_slice.kb_origin_west]
	
			return output

	return {}
	
	
func _get_swapped_spots(step: int) -> Dictionary:
	var output: Dictionary

	# First, go through the list of players, figure out where they would go if they didn't have to swap, and either
	#   assign them to that spot (if they don't have to swap) or mark that spot as open (if they do).
	var empty_support_spots: Array[Locator]
	var empty_dps_spots: Array[Locator]
	for player in player_tokens:
		var default_spot: Locator = _get_default_setup_locator(player) if step == Step.TIMER_ASSIGNMENTS_AND_SWAP else \
			_get_default_spirit_taker_locator(player)
		if player.player_data.is_support:
			if player.has_tag(_tag_group_support): output[player] = [default_spot]
			else: empty_support_spots.append(default_spot)
		else:
			if player.has_tag(_tag_group_dps): output[player] = [default_spot]
			else: empty_dps_spots.append(default_spot)
			
	# Now, if any players have not been assigned spots, indicate that they can go to any of the spots that are free.
	#   If there are multiple free spots, return them all; the swapped players are expected to use their eyes to avoid
	#   running into each other.
	for player in player_tokens:
		if output.has(player): continue
		elif player.player_data.is_support: output[player] = empty_dps_spots
		else: output[player] = empty_support_spots
		
	return output


##########
## RESOLUTION
##########


func _enter_resolution(step_id: int, substep_id: int) -> void:
	match step_id:
#		Step.INITIAL_SETUP: return ["spread out in a rectangle"]
		Step.TIMER_ASSIGNMENTS_AND_SWAP:
			match substep_id:
				0:
					wait_for_duration(0.25)
					finish_substep()
					
				1:
					var transition_marker: Circle = \
						_arena.add_circle_indicator("transition", 300, false, _stage_transition_color)
					transition_marker.border_opacity = 0
					transition_marker.background_opacity = 0.25
					wait_for_fade_in(transition_marker, 0.5)

					_cast_arena.sa_mode = true
				
					finish_substep()
				2:
					var transition_marker: Circle = _arena.get_indicator("transition")
					wait_for_fade_out(transition_marker, 0.5)
					finish_substep()
					
				3:
					wait_for_duration(0.5)
					finish_state()
	
		Step.FIRST_STACK:
			match substep_id:
				0:
					_decrement_debuffs(10) # TEMP: split this up
					for player in player_tokens:
						if player.player_data.get_buff_duration(_debuff_water) == 0:
							player.player_data.remove_buff(_debuff_water)
							_handle_water_stack(player)
			
					wait_for_duration(0.5)
					finish_substep()
		
				1:
					_place_apoc_setup_markers(1)
					wait_for_duration(1)
					finish_state()
					
					
		Step.SPIRIT_TAKER:
			match substep_id:
				0:
					# Drop the third step of apoc markers.
					_place_apoc_setup_markers(2)
					wait_for_duration(0.5)
				
					finish_substep()
				1:
					# Pick a random person for Spirit Taker and have the boss move to them.
					var taker_player: PlayerToken = player_tokens[randi_range(0, 7)]
					taker_player.add_tag(_tag_spirit_taker)
			
					boss.face_location(taker_player.position)
					boss.approach_position(taker_player.position)
					wait_for_duration(0.25)
					
					finish_substep()
				2:
					var taker_player: PlayerToken = find_token_by_tag(_tag_spirit_taker)
					_handle_spirit_taker(taker_player)
					wait_for_duration(0.75)

					finish_substep()
					
				3:
					# Pop off the stage to recenter.
					boss.on_stage = false
			
					# Drop the fourth set of apoc markers.
					_place_apoc_setup_markers(3)
					wait_for_duration(0.25)
			
					finish_substep()
				4:
					# Pop back on.
					boss.teleport_to_position(Vector2(0, 0))
					boss.face_direction(PI / 2)
					boss.on_stage = true
			
					# Wait for a lengthy bit to give the apoc markers time to tick.
					wait_for_duration(1.25)
					finish_substep()
				5:
					# Drop the fifth set of apoc markers.
					_place_apoc_setup_markers(4)
					wait_for_duration(0.5)
			
					finish_state()
			
		Step.ERUPTION:
			match substep_id:
				0:
					# Place the last set of apoc markers.
					_place_apoc_setup_markers(5)
					wait_for_duration(1.5)
					finish_substep()
				1:
					# Handle the first apocalypse explosions.
					_handle_apocalypse(0)
					wait_for_duration(1.5)
					finish_substep()
				2:
					# Handle the second apocalypse explosions.
					_handle_apocalypse(0)
					wait_for_duration(0.75)
					finish_substep()
				3:
					# Detonate eruptions on all players.
					for player in player_tokens:
						_handle_eruption(player)
					wait_for_duration(0.75)
					finish_state()
			
		Step.SECOND_STACK:
			_decrement_debuffs(19) # TEMP: split this up
			for player in player_tokens:
				if player.player_data.get_buff_duration(_debuff_water) == 0:
					player.player_data.remove_buff(_debuff_water)
					_handle_water_stack(player)
			wait_for_duration(1)
			finish_state()
			
			
		Step.DARKEST_DANCE:
			var t2: PlayerToken = get_player_token(PlayerData.Role.TANK, PlayerData.Group.GROUP_TWO)
			match substep_id:
				0:
					# The boss jumps to the tank.
					var t2_slice: SexApocLocatorGroup
					for locator_group in slices:
						if locator_group.tank_bait == t2.current_locator:
							t2_slice = locator_group
							break

					add_dependency(boss)
					boss.move_to_locator(t2_slice.boss_leap)
					
					finish_substep()
			
				1:
					_handle_darkest_dance(t2)
					finish_state()
	
		Step.KNOCKBACK:
			match substep_id:
				0:
					wait_for_duration(0.5)
					finish_substep()
				1:
					var knockback_pool: Circle = _arena.add_circle_indicator("knockback", 145, false, _knockback_color)
					knockback_pool.position = boss.position
					knockback_pool.fade_in_out(0.25, 0.25)
					for player in player_tokens:
						player.knockback(boss.position, 250)
					wait_for_duration(0.5)
					finish_state()

		Step.THIRD_STACK:
			_decrement_debuffs(9) # TEMP: split this up
			for player in player_tokens:
				if player.player_data.get_buff_duration(_debuff_water) == 0:
					player.player_data.remove_buff(_debuff_water)
					_handle_water_stack(player)
			wait_for_duration(1)
			finish_state()

		_: finish_state()
		

func _decrement_debuffs(amount: int) -> void:
	for player in player_tokens:
		var instance: BuffInstance = player.player_data.get_buff_instance(_debuff_water)
		if instance: instance.duration -= amount


func _handle_apocalypse(apoc_step: int) -> void:
	var step_slice_indices: Array[int] = _get_apoc_indices_for_step(apoc_step)

	for slice_index in step_slice_indices:
		var location: Vector2
		if slice_index == -1:
			location = Vector2(0, 0)
		else:
			location = slices[slice_index].flare_locator.position
		
		var circle_indicator: Circle = _arena.add_circle_indicator("water", 145, false, _water_puddle_color)
		circle_indicator.position = location
		circle_indicator.fade_out(1)


func _handle_darkest_dance(player: PlayerToken) -> void:
	var circle_indicator: Circle = _arena.add_circle_indicator("darkest dance", 90, false, _darkest_dance_color)
	circle_indicator.position = player.position
	wait_for_fade_out(circle_indicator, 1)

	
func _handle_eruption(player: PlayerToken) -> void:
	var circle_indicator: Circle = _arena.add_circle_indicator("eruption", 90, false, _eruption_puddle_color)
	circle_indicator.position = player.position
	circle_indicator.fade_out(1)


func _handle_spirit_taker(player: PlayerToken) -> void:
	var circle_indicator: Circle = _arena.add_circle_indicator("eruption", 75, false, _spirit_taker_color)
	circle_indicator.position = player.position
	circle_indicator.fade_out(1)


func _handle_water_stack(player: PlayerToken) -> void:
	player.player_data.remove_buff(_debuff_water)

	var circle_indicator: Circle = _arena.add_circle_indicator("water", 70, false, _water_puddle_color)
	circle_indicator.position = player.position
	circle_indicator.fade_out(1)


##########
## FAILURE/COMPLETION
##########


func _get_next_step(current_step: int) -> int:
	if current_step == Step.THIRD_STACK: return -1
	else: return current_step + 1


func _get_failure_message(step_id: int, user_selection: Locator) -> Array[String]:
	return ["oh no"]


func _enter_failure(step_id: int, substep_id: int) -> void:
	finish_state()
