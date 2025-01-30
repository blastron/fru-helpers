class_name UltimateRelativity extends Strat


@export_group("Tokens")
@export var traffic_lights: Array[TrafficLight]
@export var tether_anchor: Token

const _purple_tether_color: Color = Color(0.79, 0.05, 0.87)
const _yellow_tether_color: Color = Color(0.92, 0.92, 0.16)

const _blizzard_puddle_color: Color = Color(0.51, 0.85, 0.85)
const _darkness_puddle_color: Color = Color(0.92, 0.89, 0.39)
const _eruption_puddle_color: Color = Color(0.61, 0.4, 1.0)
const _fire_puddle_color: Color = Color(0.88, 0.32, 0.8)
const _laser_color: Color = Color(0.95, 1.0, 0.6)
const _return_puddle_color: Color = Color(0.1, 0.2, 0.9)
const _water_puddle_color: Color = Color(0.52, 0.69, 0.8)

const _first_lasers: Array[int] = [1, 4, 7]
const _second_lasers: Array[int] = [0, 3, 5]
const _third_lasers: Array[int] = [2, 6]

const _active_laser_pause: float = 0.5


@export_group("Locators - Setup")
@export var setup_north: Array[Locator]
@export var setup_south: Array[Locator]


@export_group("Locators - Mechanic")
@export var locator_groups: Array[UrLocatorGroup]
@export var locator_center: Locator


@export_group("Debuffs")
@export var _debuff_blizzard: BuffData
@export var _debuff_darkness: BuffData
@export var _debuff_eruption: BuffData
@export var _debuff_fire: BuffData
@export var _debuff_return: BuffData
@export var _debuff_return_waiting: BuffData
@export var _debuff_shadoweye: BuffData
@export var _debuff_water: BuffData


const _tag_short_resolution: String = "short_resolution"
const _tag_medium_resolution: String = "medium_resolution"
const _tag_long_resolution: String = "long_resolution"


enum Step {
	INITIAL_SETUP,
	ASSIGN_DEBUFFS,
	ORIENT_NORTH,
	FIRST_FIRE, FIRST_BAITS,
	SECOND_FIRE, SECOND_BAITS,
	THIRD_FIRE, THIRD_BAITS,
	REWIND
}


##########
## SETUP
##########


func _enter_setup(step_id: int, substep_id: int) -> void:
	match step_id:
		Step.INITIAL_SETUP:
			# TODO: Customize who is on the outside.
			get_player_token(PlayerData.Role.HEALER, PlayerData.Group.GROUP_TWO).teleport_to_locator(setup_north[0])
			get_player_token(PlayerData.Role.HEALER, PlayerData.Group.GROUP_ONE).teleport_to_locator(setup_north[1])
			get_player_token(PlayerData.Role.TANK, PlayerData.Group.GROUP_ONE).teleport_to_locator(setup_north[2])
			get_player_token(PlayerData.Role.TANK, PlayerData.Group.GROUP_TWO).teleport_to_locator(setup_north[3])

			get_player_token(PlayerData.Role.RANGED, PlayerData.Group.GROUP_TWO).teleport_to_locator(setup_south[0])
			get_player_token(PlayerData.Role.RANGED, PlayerData.Group.GROUP_ONE).teleport_to_locator(setup_south[1])
			get_player_token(PlayerData.Role.MELEE, PlayerData.Group.GROUP_ONE).teleport_to_locator(setup_south[2])
			get_player_token(PlayerData.Role.MELEE, PlayerData.Group.GROUP_TWO).teleport_to_locator(setup_south[3])
			
			finish_state()
			
		Step.ASSIGN_DEBUFFS:
			var support_pool: Array[PlayerToken] = [
				get_player_token(PlayerData.Role.HEALER, PlayerData.Group.GROUP_TWO),
				get_player_token(PlayerData.Role.HEALER, PlayerData.Group.GROUP_ONE),
				get_player_token(PlayerData.Role.TANK, PlayerData.Group.GROUP_ONE),
				get_player_token(PlayerData.Role.TANK, PlayerData.Group.GROUP_TWO)
			]

			var dps_pool: Array[PlayerToken] = [
				get_player_token(PlayerData.Role.RANGED, PlayerData.Group.GROUP_TWO),
				get_player_token(PlayerData.Role.RANGED, PlayerData.Group.GROUP_ONE),
				get_player_token(PlayerData.Role.MELEE, PlayerData.Group.GROUP_ONE),
				get_player_token(PlayerData.Role.MELEE, PlayerData.Group.GROUP_TWO)
			]
			
			var long_returns: Array[PlayerToken]
			var short_returns: Array[PlayerToken]
			
			# Assign Blizzard to either a support of a DPS.
			if randi_range(0, 1) == 0:
				# Assign Blizzard to a support.
				var blizzard_player: PlayerToken = _pick_from_pool(support_pool)
				_give_buff(blizzard_player, _debuff_blizzard, 20)
				blizzard_player.add_tag(_tag_short_resolution)
				short_returns.append(blizzard_player)
				_assign_slice(blizzard_player, 0)
			
				# Assign a long Fire to a DPS.
				var fire_player: PlayerToken = _pick_from_pool(dps_pool)
				_give_buff(fire_player, _debuff_fire, 30)
				fire_player.add_tag(_tag_long_resolution)
				long_returns.append(fire_player)
				_assign_slice(fire_player, 4)
			else:
				# Assign Blizzard to a DPS.
				var blizzard_player: PlayerToken = _pick_from_pool(dps_pool)
				_give_buff(blizzard_player, _debuff_blizzard, 20)
				blizzard_player.add_tag(_tag_long_resolution)
				long_returns.append(blizzard_player)
				_assign_slice(blizzard_player, 4)
			
				# Assign a short Fire to a support.
				var fire_player: PlayerToken = _pick_from_pool(support_pool)
				_give_buff(fire_player, _debuff_fire, 10)
				fire_player.add_tag(_tag_short_resolution)
				short_returns.append(fire_player)
				_assign_slice(fire_player, 0)

	
			# Assign long fires to two supports, and short fires to two DPS.
			var fire_supports: Array[PlayerToken] = _assign_twin_fire(support_pool, [7, 1], 30, _tag_long_resolution)
			long_returns += fire_supports
	
			var fire_dps: Array[PlayerToken] = _assign_twin_fire(dps_pool, [5, 3], 10, _tag_short_resolution)
			short_returns += fire_dps
			
			# Assign medium fires to the remaining support and DPS players.
			_give_buff(support_pool[0], _debuff_fire, 20)
			support_pool[0].add_tag(_tag_medium_resolution)
			short_returns.append(support_pool[0])
			_assign_slice(support_pool[0], 6)
	
			_give_buff(dps_pool[0], _debuff_fire, 20)
			dps_pool[0].add_tag(_tag_medium_resolution)
			short_returns.append(dps_pool[0])
			_assign_slice(dps_pool[0], 2)
			
			# Assign returns.
			for player in short_returns: _give_buff(player, _debuff_return_waiting, 15)
			for player in long_returns: _give_buff(player, _debuff_return_waiting, 25)
	
			# Assign darkness.
			var short_darkness_pool: Array[PlayerToken] = player_tokens.filter(func(token):
				return !token.has_tag(_tag_short_resolution))
			var short_darkness_player: PlayerToken = _pick_from_pool(short_darkness_pool)
			_give_buff(short_darkness_player, _debuff_darkness, 10)

			var medium_darkness_pool: Array[PlayerToken] = player_tokens.filter(func(token):
				return !token.has_tag(_tag_medium_resolution) and !token.player_data.has_buff(_debuff_darkness))
			var medium_darkness_player: PlayerToken = _pick_from_pool(medium_darkness_pool)
			_give_buff(medium_darkness_player, _debuff_darkness, 20)

			var long_darkness_pool: Array[PlayerToken] = player_tokens.filter(func(token):
				return !token.has_tag(_tag_long_resolution) and !token.player_data.has_buff(_debuff_darkness))
			var long_darkness_player: PlayerToken = _pick_from_pool(long_darkness_pool)
			_give_buff(long_darkness_player, _debuff_darkness, 30)
			
			# Assign shadoweye to long return players.
			for player in long_returns: _give_buff(player, _debuff_shadoweye, 42)
			
			# Assign water to the DPS with the 20-second fire, then eruption to all other short returns.
			var eruption_pool: Array[PlayerToken] = short_returns.duplicate(false)
			for player_index in range(len(eruption_pool)):
				var player: PlayerToken = eruption_pool[player_index]
				if not player.player_data.role in [PlayerData.Role.MELEE, PlayerData.Role.RANGED]:
					continue
			
				var fire_buff_instance: BuffInstance = player.player_data.get_buff_instance(_debuff_fire)
				if fire_buff_instance and fire_buff_instance.duration == 20:
					_give_buff(player, _debuff_water, 42)
					eruption_pool.remove_at(player_index)
					break
			
			for player in eruption_pool: _give_buff(player, _debuff_eruption, 42)
			
			finish_state()

		Step.ORIENT_NORTH:
			# Show tethers between traffic lights.
			var tether_targets: Array[int] = [1, 2, 4, 6, 7]
			for tether_index in range(5):
				var name: String = "orient_%d" % tether_index
				var light: Token = traffic_lights[tether_targets[tether_index]]
				var color: Color = _yellow_tether_color if tether_index % 2 == 0 else _purple_tether_color
				var tether: Tether = _arena.add_tether_indicator(name, light, tether_anchor, color)
				wait_for_fade_in(tether, 0.5)
			
			finish_state()
		
#		Step.FIRST_FIRE:
#			finish_state()
#		
		Step.FIRST_BAITS:
			for light_index in _first_lasers:
				traffic_lights[light_index].clockwise = randi_range(0, 1)
				traffic_lights[light_index].spinner_visible = true
			wait_for_duration(0.5)
					
			finish_state()
#
#		Step.SECOND_FIRE:
#			finish_state()
#
		Step.SECOND_BAITS:
			for light_index in _second_lasers:
				traffic_lights[light_index].clockwise = randi_range(0, 1)
				traffic_lights[light_index].spinner_visible = true
			wait_for_duration(0.5)
			
			finish_state()
#
#		Step.THIRD_FIRE:
#			finish_state()
#
		Step.THIRD_BAITS:
			for light_index in _third_lasers:
				traffic_lights[light_index].clockwise = randi_range(0, 1)
				traffic_lights[light_index].spinner_visible = true
			wait_for_duration(0.5)
			
			finish_state()
#
#		Step.REWIND:
#			finish_state()

		_:
			finish_state()


# Assign two fire debuffs to a group of players. As part of this, assign their slices, respecting the conga order.
func _assign_twin_fire(player_pool: Array[PlayerToken], slice_indices: Array[int], duration: int,
	tag: String) -> Array[PlayerToken]:
	
	var picked_players: Array[PlayerToken]
	
	# Pick a pair of players.
	var possible_patterns: Array[Array] = [[0, 1], [0, 2], [1, 2]]
	var pattern: Array = possible_patterns[randi_range(0, 2)]
	
	for index in range(2):
		var player: PlayerToken = player_pool[pattern[index]]
		_give_buff(player, _debuff_fire, duration)
		player.add_tag(tag)
		_assign_slice(player, slice_indices[index])
		picked_players.append(player)

	player_pool.remove_at(pattern[1])
	player_pool.remove_at(pattern[0])
	
	return picked_players


func _assign_slice(player: PlayerToken, slice_index: int) -> void:
	var tag_name: String = "slice_%d" % slice_index
	player.add_tag(tag_name)

	
func _get_slice(player: PlayerToken) -> UrLocatorGroup:
	for slice_index in range(8):
		var tag_name: String = "slice_%d" % slice_index
		if player.has_tag(tag_name):
			return locator_groups[slice_index]
	return null


func _get_slice_light(slice: UrLocatorGroup) -> TrafficLight:
	var slice_index: int = locator_groups.find(slice)
	return traffic_lights[slice_index]
			

## TODO: These utility functions should be cleaned up and added to the common set.
	
# Picks and returns player token at random from the given pool, removing them from the pool in the process.
func _pick_from_pool(pool: Array[PlayerToken]) -> PlayerToken:
	var pool_index: int = randi_range(0, len(pool) - 1)
	var picked_player: PlayerToken = pool[pool_index]
	pool.remove_at(pool_index)
	return picked_player

func _give_buff(player: PlayerToken, buff: BuffData, duration: int) -> void:
	var instance: BuffInstance = player.player_data.add_buff(buff)
	instance.duration = duration
	


##########
## EXPLANATION
##########


func _should_pause_for_explanation(step_id: int) -> bool:
	return step_id in [
		Step.ASSIGN_DEBUFFS, Step.ORIENT_NORTH,
		Step.FIRST_FIRE, Step.SECOND_FIRE, Step.THIRD_FIRE,
		Step.FIRST_BAITS, Step.SECOND_BAITS, Step.THIRD_BAITS,
		Step.REWIND
	]


func _get_explainer_message(step_id: int) -> Array[String]:
	match step_id:
		Step.INITIAL_SETUP: return []
		Step.ASSIGN_DEBUFFS: return ["P3_UR_EXPLAIN_BUFFS", "P3_UR_EXPLAIN_BUFFS_2", "P3_UR_EXPLAIN_BUFFS_3"]
		Step.ORIENT_NORTH: return ["P3_UR_EXPLAIN_ORIENT", "P3_UR_EXPLAIN_ORIENT_2"]
		Step.FIRST_FIRE: return ["P3_UR_EXPLAIN_FIRST_FIRE"]
		Step.FIRST_BAITS: return ["P3_UR_EXPLAIN_FIRST_BAITS", "P3_UR_EXPLAIN_FIRST_BAITS_2", "P3_UR_EXPLAIN_FIRST_BAITS_3"]
		Step.SECOND_FIRE: return ["P3_UR_EXPLAIN_SECOND_FIRE"]
		Step.SECOND_BAITS: return ["P3_UR_EXPLAIN_SECOND_BAITS"]
		Step.THIRD_FIRE: return ["P3_UR_EXPLAIN_THIRD_FIRE"]
		Step.THIRD_BAITS: return ["P3_UR_EXPLAIN_THIRD_BAITS"]
		Step.REWIND: return ["P3_UR_EXPLAIN_REWIND", "P3_UR_EXPLAIN_REWIND_2", "P3_UR_EXPLAIN_REWIND_3"]
	
	return []


##########
## MOVEMENT
##########


func _needs_user_decision(step_id: int) -> bool:
	if super(step_id): return true
		
	# Every player needs to do some sort of movement at every step.
	if step_id >= Step.FIRST_FIRE and step_id <= Step.THIRD_BAITS:
		return true
	
	return false


func _get_active_locators(step_id: int) -> Array[Locator]:
	# Show every possible indicator, all the time. No free rides :)
	if step_id >= Step.FIRST_FIRE and step_id <= Step.THIRD_BAITS:
		var all_locators: Array[Locator] = [locator_center]
		for locator_group in locator_groups:
			all_locators += locator_group.as_array()
		return all_locators
	
	return []


func _get_valid_movements(step_id: int) -> Dictionary:
	# Retrieve the list of valid movements, possibly allowing any center location if we are not in explainer mode.
	return _get_valid_movements_inner(step_id, !_use_fixed_data())


func _get_actual_movements(step_id: int, user_selection: Locator) -> Dictionary:
	var output: Dictionary = {}
	
	# Retrieve the list of valid movements, with the flag that disables moving to all possible centers. This still
	#   returns arrays of possible locations, which need to be extracted to single options.
	var valid_movements: Dictionary = _get_valid_movements_inner(step_id, false)
	for token in valid_movements.keys():
		output[token] = valid_movements[token][0]
	
	if user_selection: output[user_token] = user_selection
		
	return output

	
func _get_valid_movements_inner(step_id: int, any_center: bool) -> Dictionary:
	var output: Dictionary = {}
	for player in player_tokens:
		var slice: UrLocatorGroup = _get_slice(player)
		match step_id:
			Step.FIRST_FIRE:
				if player.has_tag(_tag_short_resolution) and player.player_data.has_buff(_debuff_fire):
					# Short fire players go out to explode.
					output[player] = [slice.fire_bait]
				else:
					# All other players stay center to soak the first stack.
					output[player] = [locator_center, slice.center_bait] if any_center else [locator_center]
				
			Step.FIRST_BAITS:
				if player.has_tag(_tag_long_resolution):
					# Long fire players bait lasers first.
					output[player] = [slice.cw_line_bait if _get_slice_light(slice).clockwise else slice.ccw_line_bait]
				elif player.player_data.has_buff(_debuff_eruption):
					# Eruption players have short rewind timers and need to place their eruptions out.
					output[player] = [slice.eruption_bait]
				else:
					# The remaining player has a short water rewind, and places their rewind slightly off center.
					output[player] = [slice.center_bait]
				
			Step.SECOND_FIRE:
				if player.has_tag(_tag_medium_resolution) and player.player_data.has_buff(_debuff_fire):
					# Medium fire players go out to explode.
					output[player] = [slice.fire_bait]
				else:
					# All other players stay center to soak the second stack and/or place the blizzard donut.
					output[player] = [locator_center, slice.center_bait] if any_center else [locator_center]
					
			Step.SECOND_BAITS:
				if player.has_tag(_tag_short_resolution):
					# Short fire players bait lasers second.
					output[player] = [slice.cw_line_bait if _get_slice_light(slice).clockwise else slice.ccw_line_bait]
				elif player.player_data.has_buff(_debuff_return_waiting):
					# Players who have long returns all have shadoweye and should all stack slightly off center.
					output[player] = [slice.center_bait]
				else:
					# All other players should move back to center in preparation for the third darkness stack.
					output[player] = [locator_center, slice.center_bait] if any_center else [locator_center]
					
			Step.THIRD_FIRE:
				if player.has_tag(_tag_long_resolution) and player.player_data.has_buff(_debuff_fire):
					# Long fire players go out to explode.
					output[player] = [slice.fire_bait]
				else:
					# All other players stay center to soak the third stack.
					output[player] = [locator_center, slice.center_bait] if any_center else [locator_center]
					
			Step.THIRD_BAITS:
				if player.has_tag(_tag_medium_resolution):
					# Medium fire players bait lasers third.
					output[player] = [slice.cw_line_bait if _get_slice_light(slice).clockwise else slice.ccw_line_bait]
				else:
					# All other players chill mid, since rewinds have been placed.
					output[player] = [slice.center_bait]
		
			Step.REWIND:
				# If the player just baited a laser, have them move in a little bit so as to not get sniped.
				if player.has_tag(_tag_medium_resolution): output[player] = [slice.final_safety_spot]
	
	return output


func _get_failure_hint_movements(step_id: int) -> Array[Locator]:
	var output: Array[Locator] = []
	
	# This strat either has one valid location for the player to move to, or they could be in either center spot. When
	#   we return centers, we return locator_center first, and that's what we'd prefer to show them as the correct move.
	var all_movements: Array[Locator] = super(step_id)
	if all_movements: output.append(all_movements[0])
	
	return output

##########
## RESOLUTION
##########


func _enter_resolution(step_id: int, substep_id: int) -> void:
	match step_id:
		Step.ASSIGN_DEBUFFS:
			# Finish the state immediately. This technically takes 3 seconds, and we should technically tick the debuff
			#   counters down as a result, but this is better UX for training purposes.
			finish_state()
			
		Step.FIRST_FIRE:
			# Fade out the tethers while the fire puddles go off, but don't wait for them.
			for tether_index in range(5):
				var name: String = "orient_%d" % tether_index
				var tether: Tether = _arena.get_indicator(name)
				tether.fade_out(1)
			
			# Decrement debuffs by 10 seconds. If we were being very pedantic, this would be 7 seconds, and the above
			#   step would wait for 3.
			_decrement_debuffs(10)

			# Trigger explosions, then end the state.
			_trigger_explosions()
			wait_for_duration(1)
			finish_state()

		Step.FIRST_BAITS:
			# Have the new lasers target their closest player and fire their first beam.
			var new_laser_set: Array[int] = _first_lasers
			_point_traffic_lights(new_laser_set)
			_shoot_light_beams(new_laser_set, 0)
			wait_for_duration(1)

			# Place rewinds for characters that have them.
			_decrement_debuffs(5)
			_place_returns(24)

			finish_state()
			
			
		Step.SECOND_FIRE, Step.THIRD_FIRE:
			# When resolving the next sets of AOEs, lasers are firing. Draw those first.
			var active_laser_set: Array[int] = _first_lasers if step_id == Step.SECOND_FIRE else _second_lasers
			match substep_id:
				0:
					# Pause momentarily to establish rhythm. We also decrement the debuffs here because the lasers don't
					#   actually fire once per second, so we need to fudge it.
					_decrement_debuffs(1)
					wait_for_duration(_active_laser_pause / 2)
					finish_substep()
				
				1, 2, 3:
					# Shoot 3 consecutive beams. After this, 4 beams (including the original) will have fired.
					_decrement_debuffs(1)
					_shoot_light_beams(active_laser_set, substep_id + 1)
					wait_for_duration(_active_laser_pause if substep_id != 3 else (_active_laser_pause / 2))
					finish_substep()
				
				4:
					# Trigger explosions.
					_decrement_debuffs(1)
					_trigger_explosions()
					
					wait_for_duration(_active_laser_pause / 2)
					finish_substep()
			
				5:
					# Fire the fifth laser.
					_shoot_light_beams(active_laser_set, 4)
					wait_for_duration(_active_laser_pause)
					finish_state()
			
			
		Step.SECOND_BAITS, Step.THIRD_BAITS:
			var active_laser_set: Array[int] = _first_lasers if step_id == Step.SECOND_BAITS else _second_lasers
		
			match substep_id:
				0:
					# Pause momentarily to establish rhythm. We also decrement the debuffs here because the lasers don't
					#   actually fire once per second, so we need to fudge it.
					_decrement_debuffs(1)
					wait_for_duration(_active_laser_pause / 2)
					finish_substep()
				1, 2, 3, 4:
					# Shoot 4 consecutive beams. After this, 9 beams (including the original) will have fired.
					_decrement_debuffs(1)
					_shoot_light_beams(active_laser_set, substep_id + 4)
					wait_for_duration(_active_laser_pause if substep_id != 4 else (_active_laser_pause / 2))
					finish_substep()
			
				5:
					# Have the new lasers target the closest player and shoot their first beams.
					var new_laser_set: Array[int] = _second_lasers if step_id == Step.SECOND_BAITS else _third_lasers
					_point_traffic_lights(new_laser_set)
					_shoot_light_beams(new_laser_set, 0)
			
					if step_id == Step.SECOND_BAITS:
						# Place rewinds for characters that have them. By now, we will have decremented debuffs five
						#   in this step, so we don't have to worry about doing that ourselves here.
						_place_returns(14)

					wait_for_duration(_active_laser_pause / 2)
					finish_substep()
					
				6:
					# Fire the last beam from the previously active laser sets.
					_shoot_light_beams(active_laser_set, 10)
					wait_for_duration(_active_laser_pause)
					finish_state()
			
		Step.REWIND:
			var active_laser_set: Array[int] = _third_lasers
			
			match substep_id:
				0, 1, 2, 3:
					# Shoot 4 consecutive beams. After this, 5 beams (including the original) will have fired.
					_decrement_debuffs(1)
					_shoot_light_beams(active_laser_set, substep_id + 1)
					wait_for_duration(_active_laser_pause if substep_id != 3 else (_active_laser_pause / 2))
					finish_substep()
				4:
					# Move all tokens to their rewind spots. Since we got here without failing, we can just warp
					#   everyone to the right spot without having to track where they technically dropped their rewinds.
					_clear_returns()

					for player in player_tokens:
						player.player_data.remove_buff(_debuff_return)
						
						var slice: UrLocatorGroup = _get_slice(player)
						if player.player_data.has_buff(_debuff_eruption): player.move_to_locator(slice.eruption_bait)
						else: player.move_to_locator(slice.center_bait)

					wait_for_duration(_active_laser_pause / 2)
					finish_substep()
					
				5, 6:
					# Fire the sixth and seventh beams.
					_decrement_debuffs(1)
					_shoot_light_beams(active_laser_set, substep_id)
					wait_for_duration(_active_laser_pause if substep_id != 3 else (_active_laser_pause / 2))
					finish_substep()
				
				7:
					# Trigger the darkness and water explosions.
					_decrement_debuffs(1)
					_trigger_explosions()
					finish_substep()
			
				8, 9, 10:
					# Fire the last three beams.
					_shoot_light_beams(active_laser_set, substep_id - 1)
					wait_for_duration(_active_laser_pause)
					finish_state()
			
		_:
			finish_state()


func _decrement_debuffs(amount: int) -> void:
	var debuff_list: Array[BuffData] = [_debuff_blizzard, _debuff_darkness, _debuff_eruption, _debuff_fire,
		_debuff_return, _debuff_return_waiting, _debuff_shadoweye, _debuff_water]
	
	for player in player_tokens:
		for debuff in debuff_list:
			var instance: BuffInstance = player.player_data.get_buff_instance(debuff)
			if instance: instance.duration -= amount


func _trigger_explosions() -> void:
	for player in player_tokens:
		if _ready_to_explode(player, _debuff_blizzard): _handle_blizzard(player)
		elif _ready_to_explode(player, _debuff_darkness): _handle_darkness(player)
		elif _ready_to_explode(player, _debuff_eruption): _handle_eruption(player)
		elif _ready_to_explode(player, _debuff_fire): _handle_fire(player)
		elif _ready_to_explode(player, _debuff_shadoweye): _handle_shadoweye(player)
		elif _ready_to_explode(player, _debuff_water): _handle_water(player)


func _ready_to_explode(player: PlayerToken, debuff: BuffData) -> bool:
	return player.player_data.has_buff(debuff) and player.player_data.get_buff_duration(debuff) <= 0


func _handle_blizzard(player: PlayerToken) -> void:
	player.player_data.remove_buff(_debuff_blizzard)

	var donut_indicator: Donut = _arena.add_donut_indicator("blizzard", 80, 200, _blizzard_puddle_color)
	donut_indicator.position = player.position
	donut_indicator.fade_out(1)


func _handle_darkness(player: PlayerToken) -> void:
	player.player_data.remove_buff(_debuff_darkness)

	var circle_indicator: Circle = _arena.add_circle_indicator("darkness", 70, false, _darkness_puddle_color)
	circle_indicator.position = player.position
	circle_indicator.fade_out(1)


func _handle_eruption(player: PlayerToken) -> void:
	player.player_data.remove_buff(_debuff_eruption)

	var circle_indicator: Circle = _arena.add_circle_indicator("eruption", 90, false, _eruption_puddle_color)
	circle_indicator.position = player.position
	circle_indicator.fade_out(1)


func _handle_fire(player: PlayerToken) -> void:
	player.player_data.remove_buff(_debuff_fire)

	var circle_indicator: Circle = _arena.add_circle_indicator("fire", 160, false, _fire_puddle_color)
	circle_indicator.position = player.position
	circle_indicator.fade_out(1)


func _handle_shadoweye(player: PlayerToken) -> void:
	player.player_data.remove_buff(_debuff_shadoweye)


func _handle_water(player: PlayerToken) -> void:
	player.player_data.remove_buff(_debuff_water)

	var circle_indicator: Circle = _arena.add_circle_indicator("eruption", 70, false, _water_puddle_color)
	circle_indicator.position = player.position
	circle_indicator.fade_out(1)


func _place_returns(new_duration: int) -> void:
	for player in player_tokens:
		if _ready_to_explode(player, _debuff_return_waiting):
			player.player_data.remove_buff(_debuff_return_waiting)
			
			var return_instance: BuffInstance = player.player_data.add_buff(_debuff_return)
			return_instance.duration = new_duration

			var circle_indicator: Circle = _arena.add_circle_indicator("return", 25, false, _return_puddle_color)
			circle_indicator.position = player.position
			wait_for_fade_in(circle_indicator, 0.5)


func _clear_returns() -> void:
	for indicator in _arena.get_indicators("return"):
		indicator.fade_out(0.5)

	
func _point_traffic_lights(indices: Array[int]) -> void:
	for index in indices:
		var light: TrafficLight = traffic_lights[index]
		light.spinner_visible = false
		
		var closest_player: Token = filter_closest(_downcast_player_tokens(player_tokens), 1, light.position)[0]
		light.face_location(closest_player.position, true)


func _shoot_light_beams(indices: Array[int], step: int) -> void:
	for index in indices:
		var light: TrafficLight = traffic_lights[index]
		
		var color: Color = _laser_color
		if step != 0: color.a *= 0.25
	
		var beam_indicator: Beam = _arena.add_beam_indicator("beam", 1000, 90, color)
		beam_indicator.position = light.position
		beam_indicator.rotation = light.hitbox_angle + (step * deg_to_rad(15) * (1 if light.clockwise else -1))
		beam_indicator.fade_out(1 if step == 0 else 0.5)


##########
## FAILURE/COMPLETION
##########


func _get_next_step(current_step: int) -> int:
	if current_step == Step.REWIND: return -1
	else: return current_step + 1


func _get_failure_message(step_id: int, user_selection: Locator) -> Array[String]:
	# Report an error if the user has selected something outside of their slice.
	var user_slice: UrLocatorGroup = _get_slice(user_token)
	var is_right_slice: bool = user_selection in user_slice.as_array()
	if !is_right_slice and user_selection != locator_center: return _get_slice_error_message(user_selection)

	match step_id:
		Step.FIRST_FIRE:
			if user_token.has_tag(_tag_short_resolution) and user_token.player_data.has_buff(_debuff_fire):
				return ["P3_UR_FAILURE_FIRST_FIRE_FIRE"]
			else: return ["P3_UR_FAILURE_FIRST_FIRE_OTHER"]
			
		Step.FIRST_BAITS:
			if user_token.has_tag(_tag_long_resolution): return _get_laser_error_message(step_id, user_selection)
			elif user_token.player_data.has_buff(_debuff_eruption):
				if user_token.player_data.is_support:
					if user_token.has_tag(_tag_short_resolution): return ["P3_UR_FAILURE_FIRST_BAIT_RETURN_N"]
					else: return ["P3_UR_FAILURE_FIRST_BAIT_RETURN_W"]
				else: return ["P3_UR_FAILURE_FIRST_BAIT_RETURN_SWSE"]
			elif user_token.player_data.has_buff(_debuff_water):
				if user_selection == locator_center: return ["`P3_UR_FAILURE_BAIT_RETURN_OFF_CENTER`"]
				else: return ["P3_UR_FAILURE_FIRST_BAIT_RETURN_E"]
			else: return ["P3_UR_FAILURE_BAIT_IDLE"]
			
		Step.SECOND_FIRE:
			if user_token.has_tag(_tag_medium_resolution) and user_token.player_data.has_buff(_debuff_fire):
				return ["P3_UR_FAILURE_SECOND_FIRE_FIRE"]
			elif user_token.player_data.has_buff(_debuff_blizzard): return ["P3_UR_FAILURE_SECOND_FIRE_BLIZZARD"]
			else: return ["P3_UR_FAILURE_SECOND_FIRE_OTHER"]
			
		Step.SECOND_BAITS:
			if user_token.has_tag(_tag_short_resolution): return _get_laser_error_message(step_id, user_selection)
			elif user_token.player_data.has_buff(_debuff_shadoweye):
				if user_selection == locator_center: return ["P3_UR_FAILURE_BAIT_RETURN_OFF_CENTER"]
				elif user_token.player_data.is_support: return ["P3_UR_FAILURE_SECOND_BAIT_RETURN_NWNE"]
				else: return ["P3_UR_FAILURE_SECOND_BAIT_RETURN_S"]
			else: return ["P3_UR_FAILURE_BAIT_IDLE"]
			
		Step.THIRD_FIRE:
			if user_token.has_tag(_tag_long_resolution) and user_token.player_data.has_buff(_debuff_fire):
				return ["P3_UR_FAILURE_THIRD_FIRE_FIRE"]
			else: return ["P3_UR_FAILURE_THIRD_FIRE_OTHER"]
			
		Step.THIRD_BAITS:
			if user_token.has_tag(_tag_medium_resolution): return _get_laser_error_message(step_id, user_selection)
			else: return ["P3_UR_FAILURE_THIRD_BAIT_CENTERUP"]

	return []

	
func _get_slice_error_message(user_selection: Locator) -> Array[String]:
	var output: Array[String]
	
	# Check to see if we should tell the user they are in the wrong slice or if they're on the wrong side of center.
	var center_locators: Array[Locator] = [locator_center]
	for slice in locator_groups:
		center_locators.append(slice.center_bait)
	if user_selection in center_locators: output.append("P3_UR_FAILURE_WRONG_SLICE_CENTER")	
	else: output.append("P3_UR_FAILURE_WRONG_SLICE")
	
	var user_slice: UrLocatorGroup = _get_slice(user_token)
	if user_slice == locator_groups[0]:
		output.append("P3_UR_FAILURE_WRONG_SLICE_N")
	elif user_slice == locator_groups[1]:
		output.append("P3_UR_FAILURE_WRONG_SLICE_NWNE")
		if user_token.player_data.role == PlayerData.Role.HEALER: output.append("P3_UR_FAILURE_WRONG_SLICE_HH")
	elif user_slice == locator_groups[2]:
		output.append("P3_UR_FAILURE_WRONG_SLICE_E")
	elif user_slice == locator_groups[3]:
		output.append("P3_UR_FAILURE_WRONG_SLICE_SWSE")
		if user_token.player_data.role == PlayerData.Role.RANGED: output.append("P3_UR_FAILURE_WRONG_SLICE_RR")
	elif user_slice == locator_groups[4]:
		output.append("P3_UR_FAILURE_WRONG_SLICE_S")
	elif user_slice == locator_groups[5]:
		output.append("P3_UR_FAILURE_WRONG_SLICE_SWSE")
		if user_token.player_data.role == PlayerData.Role.MELEE: output.append("P3_UR_FAILURE_WRONG_SLICE_MM")
	elif user_slice == locator_groups[6]:
		output.append("P3_UR_FAILURE_WRONG_SLICE_NW")
	elif user_slice == locator_groups[7]:
		output.append("P3_UR_FAILURE_WRONG_SLICE_NWNE")
		if user_token.player_data.role == PlayerData.Role.TANK: output.append("P3_UR_FAILURE_WRONG_SLICE_TT")
	
	return output

	
func _get_laser_error_message(step_id: int, user_selection: Locator) -> Array[String]:
	var user_slice: UrLocatorGroup = _get_slice(user_token)
	if user_selection == user_slice.cw_line_bait: return ["P3_UR_FAILURE_BAIT_LASER_DIRECTION_CCW"]
	elif user_selection == user_slice.ccw_line_bait: return ["P3_UR_FAILURE_BAIT_LASER_DIRECTION_CW"]
	elif step_id == Step.FIRST_BAITS:
		if user_token.player_data.is_support: return ["P3_UR_FAILURE_FIRST_BAIT_LASER_NWNE"]
		else: return ["P3_UR_FAILURE_FIRST_BAIT_LASER_S"]
	elif step_id == Step.SECOND_BAITS:
		if user_token.player_data.is_support: return ["P3_UR_FAILURE_SECOND_BAIT_LASER_N"]
		else: return ["P3_UR_FAILURE_SECOND_BAIT_LASER_SWSE"]
	elif step_id == Step.THIRD_BAITS:
		if user_token.player_data.is_support: return ["P3_UR_FAILURE_THIRD_BAIT_LASER_W"]
		else: return ["P3_UR_FAILURE_THIRD_BAIT_LASER_E"]
	
	return []


func _enter_failure(step_id: int, substep_id: int) -> void:
	finish_state()
