extends Strat

const _conga_spots: Array[String] = ["conga_1", "conga_2", "conga_3", "conga_4", "conga_5", "conga_6", "conga_7", "conga_8"]
const _tether_tags: Array[String] = ["tether_1", "tether_2", "tether_3", "tether_4"]
const _bait_tags: Array[String]   = ["bait_1", "bait_2", "bait_3", "bait_4"]

const _fire_color: Color = Color(0.98, 0.75, 0.06)
const _lightning_color: Color = Color(0.18, 0.92, 0.92)

const _fire_cone_arc: float = deg_to_rad(90)
const _lightning_cone_arc: float = deg_to_rad(240)


@export_group("Tokens")
@export var _thancred: Thancred
@export var _clone_1: Thancred
@export var _clone_2: Thancred
@export var _clone_3: Thancred


@export_group("Locators - Mechanic")
@export var _conga_spot_locators: Array[Locator]
@export var _locator_west_center: Locator
@export var _locator_west_out: Locator
@export var _locator_west_north: Locator
@export var _locator_west_south: Locator
@export var _locator_east_center: Locator
@export var _locator_east_out: Locator
@export var _locator_east_north: Locator
@export var _locator_east_south: Locator


@export_group("Debuffs")
@export var _prey_debuff: BuffData
@export var _ruin_debuff: BuffData
@export var _mvuln_debuff: BuffData


enum Step {
	CONGA_LINE,
	TETHER_ONE, TETHER_TWO, TETHER_THREE, TETHER_FOUR,
	MOVE_TO_BAITS,
	SHOT_ONE, SHOT_TWO, SHOT_THREE, SHOT_FOUR
}


##########
## SETUP
##########


func _enter_setup(step_id: int, substep_id: int) -> void:
	match step_id:
		Step.CONGA_LINE:
			# Teleport all players to their starting locations.
			_assign_conga_spot(PlayerData.Role.RANGED, PlayerData.Group.GROUP_ONE, 0)
			_assign_conga_spot(PlayerData.Role.HEALER, PlayerData.Group.GROUP_ONE, 1)
			_assign_conga_spot(PlayerData.Role.MELEE, PlayerData.Group.GROUP_ONE, 2)
			_assign_conga_spot(PlayerData.Role.TANK, PlayerData.Group.GROUP_ONE, 3)
			_assign_conga_spot(PlayerData.Role.TANK, PlayerData.Group.GROUP_TWO, 4)
			_assign_conga_spot(PlayerData.Role.MELEE, PlayerData.Group.GROUP_TWO, 5)
			_assign_conga_spot(PlayerData.Role.HEALER, PlayerData.Group.GROUP_TWO, 6)
			_assign_conga_spot(PlayerData.Role.RANGED, PlayerData.Group.GROUP_TWO, 7)
			finish_state()
			
		Step.TETHER_ONE:
			# Assign first tether.
			var tether_type: String = "fire" if _use_fixed_data() else ["fire", "lightning"].pick_random()
			var player: PlayerToken = (_pick_tether_player() if not _use_fixed_data()
				else get_player_token(PlayerData.Role.HEALER, PlayerData.Group.GROUP_TWO))
			_assign_tether(player, _thancred, tether_type, 0)
			finish_state()
			
		Step.TETHER_TWO:
			# Assign second tether.
			match substep_id:
				0:
					add_dependency(_clone_1)
					_clone_1.on_stage = true
					finish_substep()
				1:
					var tether_type: String = "lightning" if _use_fixed_data() else ["fire", "lightning"].pick_random()
					var player: PlayerToken = (_pick_tether_player() if not _use_fixed_data()
						else get_player_token(PlayerData.Role.RANGED, PlayerData.Group.GROUP_ONE))
					_assign_tether(player, _clone_1, tether_type, 1)
					finish_state()
			
		Step.TETHER_THREE:
			# Assign third tether.
			match substep_id:
				0:
					add_dependency(_clone_2)
					_clone_2.on_stage = true
					finish_substep()
				1:
					var tether_type: String = "lightning" if _use_fixed_data() else ["fire", "lightning"].pick_random()
					var player: PlayerToken = (_pick_tether_player() if not _use_fixed_data()
						else get_player_token(PlayerData.Role.HEALER, PlayerData.Group.GROUP_ONE))
					_assign_tether(player, _clone_2, tether_type, 2)
					finish_state()
			
		Step.TETHER_FOUR:
			# Assign fourth tether.
			match substep_id:
				0:
					add_dependency(_clone_3)
					_clone_3.on_stage = true
					finish_substep()
				1:
					var tether_type: String = "lightning" if _use_fixed_data() else ["fire", "lightning"].pick_random()
					var player: PlayerToken = (_pick_tether_player() if not _use_fixed_data()
						else get_player_token(PlayerData.Role.TANK, PlayerData.Group.GROUP_TWO))
					_assign_tether(player, _clone_3, tether_type, 3)
					finish_state()
			
		Step.MOVE_TO_BAITS:
			_assign_bait_order()
			finish_state()
		
		Step.SHOT_ONE:
			# Deactivate first tether and add fetters. Boss turns to face first tether target.
			_clear_tether(0)
			_thancred.face_location(find_token_by_tag(_tether_tags[0]).position)
			finish_state()
			
		Step.SHOT_TWO:
			# Deactivate second tether and add fetters. Boss turns to face OT.
			_clear_tether(1)
			_thancred.set_aggro_target(get_player_token(PlayerData.Role.TANK, PlayerData.Group.GROUP_TWO))
			finish_state()
			
		Step.SHOT_THREE:
			# Deactivate third tether and add fetters.
			_clear_tether(2)
			finish_state()
			
		Step.SHOT_FOUR:
			# Deactivate fourth tether and add fetters.
			_clear_tether(3)
			finish_state()


func _assign_conga_spot(role: PlayerData.Role, group: PlayerData.Group, spot: int):
	var player_token: PlayerToken = get_player_token(role, group)
	player_token.add_tag(_conga_spots[spot])
	player_token.teleport_to_locator(_conga_spot_locators[spot])
	

# Randomly pick an untethered player.
func _pick_tether_player() -> PlayerToken:
	var shuffled_players: Array[PlayerToken] = player_tokens.duplicate()
	shuffled_players.shuffle()
	for player in shuffled_players:
		if !player.has_any_tag(_tether_tags):
			return player
	
	return null


# Apply a tether between a player and a specific clone and wait for it to animate in.
func _assign_tether(player: PlayerToken, clone: Thancred, tether_type: String, tether_number: int) -> void:
	player.add_tag(_tether_tags[tether_number])
	player.add_tag(tether_type)
	clone.add_tag(tether_type)
	
	player.player_data.add_buff(_prey_debuff)

	var color: Color = _fire_color if tether_type == "fire" else _lightning_color
	create_tether(_tether_tags[tether_number], player, clone, color)


# Clear the given tether and wait for it to animate out.
func _clear_tether(tether_number: int):
	destroy_tether(_tether_tags[tether_number])
	
	# Find the tethered player and remove their debuff.
	var player: PlayerToken = find_token_by_tag(_tether_tags[tether_number])
	player.player_data.remove_buff(_prey_debuff)


# Apply bait tags to players who do not have tethers, in conga line order.
func _assign_bait_order():
	var bait_number: int = 0
	for conga_spot in _conga_spots:
		var conga_token: Token = find_tokens_by_tag(conga_spot)[0]
		if conga_token.has_any_tag(_tether_tags):
			continue
		
		conga_token.add_tag(_bait_tags[bait_number])
		bait_number += 1


##########
## EXPLANATION
##########


func _get_explainer_message(step_id: int) -> Array[String]:
	match step_id:
		Step.CONGA_LINE:	return [tr("P1_FOF_EXPLAIN_CONGA")]
		Step.TETHER_ONE:	return [tr("P1_FOF_FUSSLESS_EXPLAIN_TETHER_ONE")]
		Step.TETHER_TWO:	return [tr("P1_FOF_FUSSLESS_EXPLAIN_TETHER_TWO")]
		Step.TETHER_THREE:	return [tr("P1_FOF_FUSSLESS_EXPLAIN_TETHER_THREE")]
		Step.TETHER_FOUR:	return [tr("P1_FOF_FUSSLESS_EXPLAIN_TETHER_FOUR")]
		Step.MOVE_TO_BAITS:	return [tr("P1_FOF_FUSSLESS_EXPLAIN_CONGA_BAITS")]
		Step.SHOT_ONE:		return [tr("P1_FOF_FUSSLESS_EXPLAIN_SHOT_ONE")]
		Step.SHOT_TWO:		return [tr("P1_FOF_FUSSLESS_EXPLAIN_SHOT_TWO")]
		Step.SHOT_THREE:	return [tr("P1_FOF_FUSSLESS_EXPLAIN_FINAL_SHOTS")]
		Step.SHOT_FOUR:		return [tr("P1_FOF_FUSSLESS_EXPLAIN_FINAL_SHOTS")]
		_: return ["Unknown step!"]


##########
## MOVEMENT
##########


func _needs_user_decision(step_id: int) -> bool:
	if super(step_id): return true
	
	match step_id:
		# Initial tethers move into position
		Step.TETHER_ONE: return user_token.has_tag(_tether_tags[0])
		Step.TETHER_TWO: return user_token.has_tag(_tether_tags[1])
		# Secondary tethers move to bait initial cones
		Step.TETHER_THREE: return user_token.has_tag(_tether_tags[2])
		Step.TETHER_FOUR: return user_token.has_tag(_tether_tags[3])
		# Remaining players move to bait spots.
		Step.MOVE_TO_BAITS: return user_token.has_any_tag(_bait_tags)
		# Initial and secondary tether players change spots, if needed.
		Step.SHOT_TWO: return user_token.has_any_tag([_tether_tags[0], _tether_tags[2]])
		Step.SHOT_THREE: return user_token.has_any_tag([_tether_tags[1], _tether_tags[3]])
		
	return false


func _get_active_locators(step_id: int) -> Array[Locator]:
	match step_id:
		Step.TETHER_ONE, Step.TETHER_TWO, Step.TETHER_THREE, Step.TETHER_FOUR:
			# Tethered players move to their spots.
			return [
				_locator_west_center, _locator_west_out, _locator_west_north, _locator_west_south,
				_locator_east_center, _locator_east_out, _locator_east_north, _locator_east_south
			]
		Step.MOVE_TO_BAITS: # Conga players move into spots.
			return [
				_locator_west_out, _locator_west_south, _locator_east_south, _locator_east_out
			]
		Step.SHOT_TWO: # West side tethers swap.
			return [
				_locator_west_center, _locator_west_out, _locator_west_north, _locator_west_south,
			]
		Step.SHOT_THREE: # East side tethers swap.
			return [
				_locator_east_center, _locator_east_out, _locator_east_north, _locator_east_south
			]
		_: return []


func _get_valid_movements(step_id: int) -> Dictionary:
	var target_1: Token = find_token_by_tag(_tether_tags[0])
	var target_2: Token = find_token_by_tag(_tether_tags[1])
	var target_3: Token = find_token_by_tag(_tether_tags[2])
	var target_4: Token = find_token_by_tag(_tether_tags[3])
	
	match step_id:
		Step.TETHER_ONE:
			var destination: Locator = _locator_west_north if target_1.has_tag("fire") else _locator_west_center
			return { target_1 : [destination] }
			
		Step.TETHER_TWO:
			var destination: Locator = _locator_east_north if target_2.has_tag("fire") else _locator_east_center
			return { target_2 : [destination] }
			
		Step.TETHER_THREE:
			# If either of the cone target positions is occupied, move to the other one. This will put us in the correct
			#   spot for us to bait the first player's cones if the first player moved correctly. If neither cone
			#   position is occupied, move to the correct one.
			if _locator_west_center.occupants.is_empty(): return { target_3 : [_locator_west_center] }
			elif _locator_west_north.occupants.is_empty(): return { target_3 : [_locator_west_north] }
			else:
				var destination: Locator = _locator_west_center if target_1.has_tag("fire") else _locator_west_north
				return { target_3 : [destination] }
			
		Step.TETHER_FOUR:
			# As above, but on the east side.
			if _locator_east_center.occupants.is_empty(): return { target_4 : [_locator_east_center] }
			elif _locator_east_north.occupants.is_empty(): return { target_4 : [_locator_east_north] }
			else:
				var destination: Locator = _locator_east_center if target_2.has_tag("fire") else _locator_east_north
				return { target_4 : [destination] }
			
		Step.MOVE_TO_BAITS:
			# Move all remaining players to their fuss-free static positions
			return {
				find_token_by_tag(_bait_tags[0]) : [_locator_west_out],
				find_token_by_tag(_bait_tags[1]) : [_locator_west_south],
				find_token_by_tag(_bait_tags[2]) : [_locator_east_south],
				find_token_by_tag(_bait_tags[3]) : [_locator_east_out]
			}
		Step.SHOT_TWO:
			# Swap tethers 1 and 3 if needed
			var destination_1: Locator = _locator_west_center if target_3.has_tag("fire") else _locator_west_north
			var destination_3: Locator = _locator_west_north if target_3.has_tag("fire") else _locator_west_center
			return {
				target_1 : [destination_1],
				target_3 : [destination_3]
			}
			
		Step.SHOT_THREE:
			# Swap tethers 2 and 4 if needed
			var destination_2: Locator = _locator_east_center if target_4.has_tag("fire") else _locator_east_north
			var destination_4: Locator = _locator_east_north if target_4.has_tag("fire") else _locator_east_center
			return {
				target_2 : [destination_2],
				target_4 : [destination_4]
			}
	
	return {}


func _get_actual_movements(step_id: int, user_selection: Locator) -> Dictionary:
	if user_selection:
		var target_1: Token = find_token_by_tag(_tether_tags[0])
		var target_2: Token = find_token_by_tag(_tether_tags[1])
		var target_3: Token = find_token_by_tag(_tether_tags[2])
		var target_4: Token = find_token_by_tag(_tether_tags[3])
		
		# If the user is one of the tether targets, and it's their turn to swap, ignore the actual results and instead
		#   have the player swap with whoever is at their target location.
		var first_swap: bool = step_id == Step.SHOT_TWO and (user_token == target_1 or user_token == target_3)
		var second_swap: bool = step_id == Step.SHOT_THREE and (user_token == target_2 or user_token == target_4)
		if first_swap or second_swap:
			if user_selection.occupants.is_empty():
				# Failsafe for if the user somehow selects an empty spot.
				return { user_token : user_selection }
			elif user_selection.occupants[0] == user_token:
				# The user is not swapping.
				return {}
			elif user_token.current_locator != null:
				return {
					user_token : user_selection,
					user_selection.occupants[0] : user_token.current_locator
				}
			
	return super._get_actual_movements(step_id, user_selection)


##########
## RESOLUTION
##########


func _enter_resolution(step_id: int, substep_id: int) -> void:
	match step_id:
		Step.CONGA_LINE, Step.TETHER_ONE, Step.TETHER_TWO, Step.TETHER_THREE, Step.TETHER_FOUR, Step.MOVE_TO_BAITS:
			# Moving to initial spots; no resolution yet.
			finish_state()
		Step.SHOT_ONE:
			_resolve_tether(0, substep_id)
		Step.SHOT_TWO:
			_resolve_tether(1, substep_id)
		Step.SHOT_THREE:
			_resolve_tether(2, substep_id)
		Step.SHOT_FOUR:
			_resolve_tether(3, substep_id)
		_:
			finish_state()


func _resolve_tether(tether_number: int, substep: int) -> void:
	if tether_number == 0:
		match substep:
			0: # No clones need to dash, so we just fire the first set of cones.
				_launch_cones(tether_number, false)
				finish_substep()
			1:
				_remove_vulns()
				finish_state()
	else:
		var clone: Thancred = _clone_1 if tether_number == 1 else _clone_2 if tether_number == 2 else _clone_3
		match substep:
			0:	# Clone dashes in
				var target: Token = find_token_by_tag(_tether_tags[tether_number])
				add_dependency(clone)
				clone.approach_position(target.position, 75, 1000)
				finish_substep()
			1:	# Fire cones
				_launch_cones(tether_number, false)
				finish_substep()
			2:	# Clone dashes out
				add_dependency(clone)
				clone.on_stage = false
				_remove_vulns()
				finish_state()


func _launch_cones(tether_number: int, instant: bool) -> void:
	var target: PlayerToken = find_token_by_tag(_tether_tags[tether_number])
	_apply_damage(target)
	
	var is_fire: bool = target.has_tag("fire")
	
	var color: Color = _fire_color if is_fire else _lightning_color
	var arc_width: float = (PI / 2) if is_fire else (PI * 2 / 3)

	var origin: Vector2 = target.position
	
	var other_players: Array[Token] = _downcast_player_tokens(filter_living_only(get_other_player_tokens(target)))
	var baits: Array[Token] = filter_closest(other_players, 1 if is_fire else 3, target.position)
	
	var hit_players: Array[PlayerToken]
	hit_players.append(target)
	
	for bait_index in range(len(baits)):
		var bait: Token = baits[bait_index]
		var bait_location: Vector2 = bait.position
		var rotation: float = origin.angle_to_point(bait_location)
		
		var cone_name: String = "fof_cone_%d_%d" % [tether_number, bait_index]
		create_cone(cone_name, origin, rotation, -1, arc_width, color, 1 if not instant else 0)
		
		var cone_hits: Array[Token] = filter_in_cone(other_players, origin, rotation, 10000, arc_width)
		for cone_hit in cone_hits:
			var hit_player: PlayerToken = cone_hit as PlayerToken
			_apply_damage(hit_player)
			if not hit_players.has(hit_player):
				hit_players.append(hit_player)
				
	# Apply ruin debuff if there weren't three people in the stack.
	# TODO: The fussless strat is super forgiving and lets the middle player stand basically wherever. We need to cheat here.
	if is_fire and len(hit_players) < 4:
		for player in hit_players:
			if not player.player_data.has_buff(_ruin_debuff):
				player.player_data.add_buff(_ruin_debuff)


func _apply_damage(target: PlayerToken) -> void:
	var target_data: PlayerData = target.player_data
	if target_data.has_buff(_mvuln_debuff):
		target_data.dead = true
	else:
		var buff_instance: BuffInstance = target_data.add_buff(_mvuln_debuff)
		buff_instance.stack_count = -2


func _remove_vulns() -> void:
	for player_token in player_tokens:
		var player_data: PlayerData = player_token.player_data
		if !player_data.dead and player_data.has_buff(_mvuln_debuff):
			var vuln_instance: BuffInstance = player_data.get_buff_instance(_mvuln_debuff)
			vuln_instance.stack_count += 1
			if vuln_instance.stack_count == 0:
				player_data.remove_buff(_mvuln_debuff)


##########
## FAILURE/COMPLETION
##########


func _get_next_step(current_step: int) -> int:
	if current_step == Step.SHOT_FOUR: return -1
	else: return current_step + 1


func _get_failure_message(step_id: int, user_selection: Locator) -> Array[String]:
	# Check to see if the user should have moved to a static bait spot.
	if user_token.has_any_tag(_bait_tags):
		# Bait players only move once, so there's only one error message to show.
		if user_token.has_tag(_bait_tags[0]): return [tr("P1_FOF_FUSSLESS_FAILED_BAIT_ONE")]
		if user_token.has_tag(_bait_tags[1]): return [tr("P1_FOF_FUSSLESS_FAILED_BAIT_TWO")]
		if user_token.has_tag(_bait_tags[2]): return [tr("P1_FOF_FUSSLESS_FAILED_BAIT_THREE")]
		if user_token.has_tag(_bait_tags[3]): return [tr("P1_FOF_FUSSLESS_FAILED_BAIT_FOUR")]
		return ["ERROR: Non-tether player did not have a bait tag to show an error message for."]
	
	# The user has a tether. Check to see if they are on the wrong side.
	var is_west: bool = user_selection in [
		_locator_west_center, _locator_west_north, _locator_west_out, _locator_west_south
	]
	var should_be_west: bool = user_token.has_any_tag([
		_tether_tags[0], _tether_tags[2], _bait_tags[0], _bait_tags[1]
	])
	
	if is_west != should_be_west:
		if should_be_west: return [tr("P1_FOF_FUSSLESS_FAILED_WRONG_TETHER_SIDE_WEST")]
		else: return [tr("P1_FOF_FUSSLESS_FAILED_WRONG_TETHER_SIDE_EAST")]
	
	# Determine if we're on the first or second set of tethers and if the user's tether is about to resolve.
	var is_first_shot: bool = (is_west and step_id < Step.SHOT_ONE) or (not is_west and step_id < Step.SHOT_TWO)
	var takes_first_shot: bool = user_token.has_any_tag([_tether_tags[0], _tether_tags[1]])
	var taking_this_shot: bool = takes_first_shot if is_first_shot else not takes_first_shot
	
	# Get the other token in the group. Note that this could wind up being null if the user messes up before all tethers
	#   are assigned.
	var other_tether_token: Token
	if user_token.has_tag(_tether_tags[0]):
		other_tether_token = find_token_by_tag(_tether_tags[2])
	elif user_token.has_tag(_tether_tags[1]):
		other_tether_token = find_token_by_tag(_tether_tags[3])
	elif user_token.has_tag(_tether_tags[2]):
		other_tether_token = find_token_by_tag(_tether_tags[0])
	elif user_token.has_tag(_tether_tags[3]):
		other_tether_token = find_token_by_tag(_tether_tags[1])
		
	# Check to see if the user wound up in a fixed bait spot instead of a tether placement spot.
	var is_in_fixed_bait_spot: bool = user_selection in [
		_locator_west_out, _locator_west_south, _locator_east_south, _locator_east_out
	]
	if is_in_fixed_bait_spot:
		if taking_this_shot:
			if user_token.has_tag("fire"): return [tr("P1_FOF_FUSSLESS_FAILED_TETHER_PLACE_FIRE")]
			else: return [tr("P1_FOF_FUSSLESS_FAILED_TETHER_PLACE_LIGHTNING")]
		else:
			if other_tether_token.has_tag("fire"): return [
				tr("P1_FOF_FUSSLESS_FAILED_TETHER_BAIT_FIRE"), tr("P1_FOF_FUSSLESS_FAILED_FIRE_ADDENDUM")
			]
			else: return [tr("P1_FOF_FUSSLESS_FAILED_TETHER_BAIT_LIGHTNING")]
	
	# The user moved to the wrong tether spot on the correct side. If this is the first shot, inform them that they
	#   baited wrong, and if it's not, informed them that they swapped incorrectly.
	if is_first_shot:
		if taking_this_shot:
			if user_token.has_tag("fire"): return [tr("P1_FOF_FUSSLESS_FAILED_TETHER_PLACE_FIRE")]
			else: return [tr("P1_FOF_FUSSLESS_FAILED_TETHER_PLACE_LIGHTNING")]
		else:
			if other_tether_token.has_tag("fire"): return [
				tr("P1_FOF_FUSSLESS_FAILED_TETHER_BAIT_FIRE"), tr("P1_FOF_FUSSLESS_FAILED_FIRE_ADDENDUM")
			]
			else: return [tr("P1_FOF_FUSSLESS_FAILED_TETHER_BAIT_LIGHTNING")]
	else:
		var is_fire: bool = user_token.has_tag("fire") if taking_this_shot else other_tether_token.has_tag("fire")
		var needed_swap: bool = ((user_token.has_tag("fire") and other_tether_token.has_tag("fire")) or
			(user_token.has_tag("lightning") and other_tether_token.has_tag("lightning")))
		if needed_swap: return [
			tr("P1_FOF_FUSSLESS_FAILED_DID_NOT_SWAP_IN") if taking_this_shot else tr("P1_FOF_FUSSLESS_FAILED_DID_NOT_SWAP_OUT"),
			tr("P1_FOF_FUSSLESS_FAILED_SWAP_FIRE") if is_fire else tr("P1_FOF_FUSSLESS_FAILED_SWAP_LIGHTNING")
		]
		else: return [
			tr("P1_FOF_FUSSLESS_FAILED_UNNECESSARY_SWAP")
		]


func _enter_failure(step_id: int, substep_id: int) -> void:
	if substep_id == 0: # Move everyone into position.
		var user_selection: Locator = _get_incorrect_selection()
		user_token.move_to_locator(user_selection)
		add_dependency(user_token)
		
		# Assign any remaining tethers and conga spots. The user will have already been assigned their tether.
		if step_id < Step.TETHER_ONE:
			_thancred.on_stage = true
			_assign_tether(_pick_tether_player(), _thancred, ["fire", "lightning"].pick_random(), 0)
		if step_id < Step.TETHER_TWO:
			_clone_1.on_stage = true
			_assign_tether(_pick_tether_player(), _clone_1, ["fire", "lightning"].pick_random(), 1)
		if step_id < Step.TETHER_THREE:
			_clone_2.on_stage = true
			_assign_tether(_pick_tether_player(), _clone_2, ["fire", "lightning"].pick_random(), 2)
		if step_id < Step.TETHER_FOUR:
			_clone_3.on_stage = true
			_assign_tether(_pick_tether_player(), _clone_3, ["fire", "lightning"].pick_random(), 3)
		if step_id < Step.MOVE_TO_BAITS:
			_assign_bait_order()
		
		if step_id <= Step.MOVE_TO_BAITS:
			# Move bait players into position, if they're not the player. We don't care about the player's choice here,
			#   as the baiting players don't react to anything.
			var bait_1: Token = find_token_by_tag(_bait_tags[0])
			if bait_1 != user_token:
				bait_1.move_to_locator(_locator_west_out)
				add_dependency(bait_1)
		
			var bait_2: Token = find_token_by_tag(_bait_tags[1])
			if bait_2 != user_token:
				bait_2.move_to_locator(_locator_west_south)
				add_dependency(bait_2)
			
			var bait_3: Token = find_token_by_tag(_bait_tags[2])
			if bait_3 != user_token:
				bait_3.move_to_locator(_locator_east_south)
				add_dependency(bait_3)
			
			var bait_4: Token = find_token_by_tag(_bait_tags[3])
			if bait_4 != user_token:
				bait_4.move_to_locator(_locator_east_out)
				add_dependency(bait_4)

		# Move the tether target players into place. If the user is standing in one of the two tether spots on that
		#   side, select the other one; otherwise, go to the correct location for the given tether configuration.
		var target_1: Token = find_token_by_tag(_tether_tags[0])
		var target_2: Token = find_token_by_tag(_tether_tags[1])
		var target_3: Token = find_token_by_tag(_tether_tags[2])
		var target_4: Token = find_token_by_tag(_tether_tags[3])
		
		if target_1 != user_token:
			add_dependency(target_1)
			if user_selection == _locator_west_north: target_1.move_to_locator(_locator_west_center)
			elif user_selection == _locator_west_center: target_1.move_to_locator(_locator_west_north)
			elif step_id < Step.SHOT_ONE:
				target_1.move_to_locator(_locator_west_north if target_1.has_tag("fire") else _locator_west_center)
			else:
				target_1.move_to_locator(_locator_west_center if target_3.has_tag("fire") else _locator_west_north)
			
		if target_2 != user_token:
			add_dependency(target_2)
			if user_selection == _locator_east_north: target_2.move_to_locator(_locator_east_center)
			elif user_selection == _locator_east_center: target_2.move_to_locator(_locator_east_north)
			elif step_id < Step.SHOT_TWO:
				target_2.move_to_locator(_locator_east_north if target_2.has_tag("fire") else _locator_east_center)
			else:
				target_2.move_to_locator(_locator_east_center if target_4.has_tag("fire") else _locator_east_north)
			
		if target_3 != user_token:
			add_dependency(target_3)
			if user_selection == _locator_west_north: target_3.move_to_locator(_locator_west_center)
			elif user_selection == _locator_west_center: target_3.move_to_locator(_locator_west_north)
			elif step_id < Step.SHOT_ONE:
				target_3.move_to_locator(_locator_west_center if target_1.has_tag("fire") else _locator_west_north)
			else:
				target_3.move_to_locator(_locator_west_north if target_3.has_tag("fire") else _locator_west_center)
		
		if target_4 != user_token:
			add_dependency(target_4)
			if user_selection == _locator_east_north: target_4.move_to_locator(_locator_east_center)
			elif user_selection == _locator_east_center: target_4.move_to_locator(_locator_east_north)
			elif step_id < Step.SHOT_TWO:
				target_4.move_to_locator(_locator_east_center if target_2.has_tag("fire") else _locator_east_north)
			else:
				target_4.move_to_locator(_locator_east_north if target_4.has_tag("fire") else _locator_east_center)
		
		finish_substep()
	
	elif substep_id == 1: # Fire incorrectly baited cones.
		var is_west: bool = user_token.current_locator in [
			_locator_west_center, _locator_west_north, _locator_west_out, _locator_west_south
		]
		var should_be_west: bool = user_token.has_any_tag([
			_tether_tags[0], _tether_tags[2], _bait_tags[0], _bait_tags[1]
		])
		
		if is_west != should_be_west:
			# The user is meant to be on the opposite side from where they are. Fire the first two sets of cones. Note
			#   that this can only happen during initial setup.
			_launch_cones(0, true)
			_launch_cones(1, true)
		elif is_west:
			# The user is on the correct side, but in the wrong spot. Fire the cones for that side.
			if step_id < Step.SHOT_ONE: _launch_cones(0, true)
			else: _launch_cones(2, true)
		else:
			# The user is on the correct side, but in the wrong spot. Fire the cones for that side.
			if step_id < Step.SHOT_TWO: _launch_cones(1, true)
			else: _launch_cones(3, true)
		
		finish_state()
