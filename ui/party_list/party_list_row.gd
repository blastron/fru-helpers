class_name PartyListRow extends HBoxContainer

# Nodes
@export var _role_icon: TextureRect
@export var _user_control_icon: TextureRect

@export var _dead_icon: TextureRect

@export var _buff_list: HBoxContainer
@export var _buff_type: PackedScene

# Icons
@export_group("Role Icons")
@export var icon_job_t1: Texture2D
@export var icon_job_t2: Texture2D
@export var icon_job_h1: Texture2D
@export var icon_job_h2: Texture2D
@export var icon_job_m1: Texture2D
@export var icon_job_m2: Texture2D
@export var icon_job_r1: Texture2D
@export var icon_job_r2: Texture2D
@export var icon_job_unknown: Texture2D


var player_data: PlayerData:
	get: return player_data
	set(value):
		assert(value != null, "Can't assign null player data.")
		assert(player_data == null, "Can't reassign player data after first set.")
		if value == null or player_data != null: return

		player_data = value
		_dead_changed()

		# Set visuals.
		_update_icons()
		
		# Clear the buff list of any preview data.
		if _buff_list:
			for child in _buff_list.get_children():
				_buff_list.remove_child(child)
				child.queue_free()
		
		# Populate the buff list with all active buffs on the player.
		for buff in player_data.get_active_buffs():
			_add_buff(buff, player_data.get_buff_instance(buff))
		
		# Subscribe to change events.
		player_data.dead_changed.connect(self._dead_changed)
		player_data.buff_added.connect(self._add_buff)
		player_data.buff_removed.connect(self._remove_buff)


func _update_icons() -> void:
	var role: PlayerData.Role = player_data.role if player_data else PlayerData.Role.NONE
	var group: PlayerData.Group = player_data.group if player_data else PlayerData.Group.GROUP_ONE
	
	if _role_icon:
		match role:
			PlayerData.Role.TANK, PlayerData.Role.MAIN_TANK, PlayerData.Role.OFF_TANK:
				match group:
					PlayerData.Group.GROUP_ONE: _role_icon.texture = icon_job_t1
					PlayerData.Group.GROUP_TWO: _role_icon.texture = icon_job_t2
			PlayerData.Role.HEALER, PlayerData.Role.PURE_HEALER, PlayerData.Role.BARRIER_HEALER:
				match group:
					PlayerData.Group.GROUP_ONE: _role_icon.texture = icon_job_h1
					PlayerData.Group.GROUP_TWO: _role_icon.texture = icon_job_h2
			PlayerData.Role.MELEE:
				match group:
					PlayerData.Group.GROUP_ONE: _role_icon.texture = icon_job_m1
					PlayerData.Group.GROUP_TWO: _role_icon.texture = icon_job_m2
			PlayerData.Role.RANGED, PlayerData.Role.PHYS_RANGED, PlayerData.Role.CASTER:
				match group:
					PlayerData.Group.GROUP_ONE: _role_icon.texture = icon_job_r1
					PlayerData.Group.GROUP_TWO: _role_icon.texture = icon_job_r2
			_: _role_icon.texture = icon_job_unknown
		
	if _user_control_icon:
		_user_control_icon.visible = player_data.user_controlled if player_data else false


func _add_buff(data: BuffData, instance: BuffInstance) -> void:
	if not _buff_list: return
	
	for child in _buff_list.get_children():
		var buff_icon: BuffIcon = child
		if buff_icon.instance == instance:
			assert(false, "Already have a reference to buff instance %s." % str(instance))
			return
	
	var buff_icon: BuffIcon = _buff_type.instantiate()
	buff_icon.data = data
	buff_icon.instance = instance
	_buff_list.add_child(buff_icon)

	
func _remove_buff(buff: BuffData, instance: BuffInstance) -> void:
	if not _buff_list: return

	for child in _buff_list.get_children():
		var buff_icon: BuffIcon = child
		if buff_icon.instance == instance:
			_buff_list.remove_child(child)
			child.queue_free()
			return

func _dead_changed() -> void:
	if _dead_icon: _dead_icon.visible = player_data.dead