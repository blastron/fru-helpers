extends Strat

const _conga_spots: Array[String] = ["conga_1", "conga_2", "conga_3", "conga_4", "conga_5", "conga_6", "conga_7", "conga_8"]
const _tether_tags: Array[String] = ["tether_1", "tether_2", "tether_3", "tether_4"]
const _bait_tags: Array[String]   = ["bait_1", "bait_2", "bait_3", "bait_4"]

const _fire_color: Color = Color(0.98, 0.75, 0.06)
const _lightning_color: Color = Color(0.18039216, 0.5529412, 0.92156863)

const _fire_cone_arc: float = deg_to_rad(90)
const _lightning_cone_arc: float = deg_to_rad(240)


var _thancred: Thancred
var _clone_1: Thancred
var _clone_2: Thancred
var _clone_3: Thancred


@export var _prey_debuff: BuffData


func _ready() -> void:
	_thancred = find_child("thancred") # This is Thancred.
	_clone_1 = find_child("clone NW")
	_clone_2 = find_child("clone NE")
	_clone_3 = find_child("clone N")
	
	super()

func get_num_steps() -> int:
	return 9

##########
## SETUP
##########

func _enter_setup(step_id: int, substep_id: int) -> void:
	match step_id:
		0:
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
		1:
			# Assign first tether.
			var tether_type: String = "fire" if _use_fixed_data() else ["fire", "lightning"].pick_random()
			var player: PlayerToken = _pick_tether_player(PlayerData.Role.HEALER, PlayerData.Group.GROUP_TWO)
			_assign_tether(player, _thancred, tether_type, 0)
			finish_state()
		2:
			# Assign second tether.
			match substep_id:
				0:
					add_dependency(_clone_1)
					_clone_1.on_stage = true
					finish_substep()
				1:
					var tether_type: String = "lightning" if _use_fixed_data() else ["fire", "lightning"].pick_random()
					var player: PlayerToken = _pick_tether_player(PlayerData.Role.RANGED, PlayerData.Group.GROUP_ONE)
					_assign_tether(player, _clone_1, tether_type, 1)
					finish_state()
			
		3:
			# Assign third tether.
			match substep_id:
				0:
					add_dependency(_clone_2)
					_clone_2.on_stage = true
					finish_substep()
				1:
					var tether_type: String = "lightning" if _use_fixed_data() else ["fire", "lightning"].pick_random()
					var player: PlayerToken = _pick_tether_player(PlayerData.Role.HEALER, PlayerData.Group.GROUP_ONE)
					_assign_tether(player, _clone_2, tether_type, 2)
					finish_state()
		4:
			# Assign fourth tether.
			match substep_id:
				0:
					add_dependency(_clone_3)
					_clone_3.on_stage = true
					finish_substep()
				1:
					var tether_type: String = "lightning" if _use_fixed_data() else ["fire", "lightning"].pick_random()
					var player: PlayerToken = _pick_tether_player(PlayerData.Role.TANK, PlayerData.Group.GROUP_TWO)
					_assign_tether(player, _clone_3, tether_type, 3)
					
					# Assign bait order for remaining untethered players in conga order.
					var bait_number: int = 0
					for conga_spot in _conga_spots:
						var conga_token: Token = find_tokens_by_tag(conga_spot)[0]
						if conga_token.has_any_tag(_tether_tags):
							continue
						conga_token.add_tag(_bait_tags[bait_number])
						bait_number += 1

					finish_state()
		
		5:
			# Deactivate first tether and add fetters. Boss turns to face first tether target.
			_clear_tether(0)
			_thancred.face_location(find_token_by_tag(_tether_tags[0]).position)
	
			finish_state()
		6:
			# Deactivate second tether and add fetters. Boss turns to face OT.
			_clear_tether(1)
			_thancred.set_aggro_target(get_player_token(PlayerData.Role.TANK, PlayerData.Group.GROUP_TWO))
	
			finish_state()
		7:
			# Deactivate third tether and add fetters.
			_clear_tether(2)
			finish_state()
		8:
			# Deactivate fourth tether and add fetters.
			_clear_tether(3)
			finish_state()

func _assign_conga_spot(role: PlayerData.Role, group: PlayerData.Group, spot: int):
	var player_token: PlayerToken = get_player_token(role, group)
	player_token.add_tag(_conga_spots[spot])
	
	var locator: Locator = get_locator(_conga_spots[spot])
	player_token.teleport_to_locator(locator)
	
# Randomly pick an untethered player.
func _pick_tether_player(fixed_role: PlayerData.Role, fixed_group: PlayerData.Group) -> PlayerToken:
	if _use_fixed_data():
		return get_player_token(fixed_role, fixed_group)
	
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

	
##########
## MOVEMENT
##########

func _get_active_locator_ids(step_id: int) -> Array[String]:
	match step_id:
		1, 2, 3, 4:
			return [
				"west_center", "west_out", "west_north", "west_south",
				"east_center", "east_out", "east_north", "east_south"
			]
		5:
			return [
				"west_out", "west_south", "east_south", "east_out"
			]
		6:
			return ["west_center", "west_north"]
		7:
			return ["east_center", "east_north"]
	return []

func _get_movement_orders(step_id: int, selected_locator: Locator = null) -> Array[MovementOrder]:
	var target_1: Token = find_token_by_tag(_tether_tags[0])
	var target_2: Token = find_token_by_tag(_tether_tags[1])
	var target_3: Token = find_token_by_tag(_tether_tags[2])
	var target_4: Token = find_token_by_tag(_tether_tags[3])
	
	match step_id:
		1:
			var destination: String = "west_north" if target_1.has_tag("fire") else "west_center"
			return [MovementOrder.new(target_1, get_locator(destination))]
		2:
			var destination: String = "east_north" if target_2.has_tag("fire") else "east_center"
			return [MovementOrder.new(target_2, get_locator(destination))]
		3:
			var destination: String = "west_center" if target_1.has_tag("fire") else "west_north"
			return [MovementOrder.new(target_3, get_locator(destination))]
		4:
			var destination: String = "east_center" if target_2.has_tag("fire") else "east_north"
			return [MovementOrder.new(target_4, get_locator(destination))]
		5:
			# Move all remaining players to their fuss-free static positions
			return [
				MovementOrder.new(find_token_by_tag(_bait_tags[0]), get_locator("west_out")),
				MovementOrder.new(find_token_by_tag(_bait_tags[1]), get_locator("west_south")),
				MovementOrder.new(find_token_by_tag(_bait_tags[2]), get_locator("east_south")),
				MovementOrder.new(find_token_by_tag(_bait_tags[3]), get_locator("east_out"))
			]
		6:
			# Swap tethers 1 and 3 if needed
			var destination_1: String = "west_center" if target_3.has_tag("fire") else "west_north"
			var destination_3: String = "west_north" if target_3.has_tag("fire") else "west_center"
			return [
				MovementOrder.new(target_1, get_locator(destination_1)),
				MovementOrder.new(target_3, get_locator(destination_3))
			]
		7:
			# Swap tethers 2 and 4 if needed
			var destination_2: String = "east_center" if target_4.has_tag("fire") else "east_north"
			var destination_4: String = "east_north" if target_4.has_tag("fire") else "east_center"
			return [
				MovementOrder.new(target_2, get_locator(destination_2)),
				MovementOrder.new(target_4, get_locator(destination_4))
			]
	return []

##########
## RESOLUTION
##########

const clone_dash_distance: float = 50

func _enter_resolution(step_id: int, substep_id: int) -> void:
	match step_id:
		0, 1, 2, 3, 4:
			# No resolution yet.
			finish_state()
		5:
			_resolve_tether(0, substep_id)
		6:
			_resolve_tether(1, substep_id)
		7:
			_resolve_tether(2, substep_id)
		8:
			_resolve_tether(3, substep_id)
		_:
			finish_state()

func _resolve_tether(tether_number: int, substep: int) -> void:
	if tether_number == 0:
		# No clones need to dash, so we just fire the first set of cones.
		_launch_cones(tether_number)
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
				_launch_cones(tether_number)
				finish_substep()
			2:	# Clone dashes out
				add_dependency(clone)
				clone.on_stage = false
				finish_state()
		
func _launch_cones(tether_number: int) -> void:
	var target: PlayerToken = find_token_by_tag(_tether_tags[tether_number]) as PlayerToken
	var is_fire: bool = target.has_tag("fire")
	
	var color: Color = _fire_color if is_fire else _lightning_color
	var arc_width: float = (PI / 2) if is_fire else (PI * 2 / 3)

	var origin: Vector2 = target.position
	
	var other_players: Array[Token]
	other_players.assign(get_other_player_tokens(target))
	var baits: Array[Token] = filter_closest(other_players, 1 if is_fire else 3, target.position)
	
	for bait in baits:
		var bait_location: Vector2 = bait.position
		var rotation: float = origin.angle_to_point(bait_location)
		create_cone("fof_cone", origin, rotation, -1, arc_width, color, 1)
		
		var victims: Array[Token] = filter_in_cone(other_players, origin, rotation, 10000, arc_width)
		for victim in victims:
			create_circle("", victim.position, 50, false, Color.WHITE, 1)
