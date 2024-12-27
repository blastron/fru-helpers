@tool

class_name PartyListRow extends HBoxContainer

# Nodes
@export var _role_icon: TextureRect
@export var _user_control_icon: TextureRect

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
		player_data = value
		_update_icons()


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
