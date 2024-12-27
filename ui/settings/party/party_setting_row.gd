@tool

class_name PartySettingRow extends HBoxContainer

# Nodes
@export var _up_arrow: TextureButton
@export var _down_arrow: TextureButton

@export var _role_icon: TextureRect
@export var _job_list: OptionButton

@export var user_control_checkbox: TextureButton

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

# All exports after this are purely for preview purposes in the editor.
@export_group("Preview Settings")


func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	if _up_arrow:
		_up_arrow.pressed.connect(self._up_pressed)
		_up_arrow.disabled = up_disabled
	
	if _down_arrow:
		_down_arrow.pressed.connect(self._down_pressed)
		_down_arrow.disabled = down_disabled
	
##########
## Party list ordering
##########

@export var up_disabled: bool = true:
	get: return up_disabled
	set(value):
		up_disabled = value
		if _up_arrow: _up_arrow.disabled = value

signal up_pressed(row: PartySettingRow)
func _up_pressed():
	up_pressed.emit(self)

@export var down_disabled: bool = true:
	get: return down_disabled
	set(value):
		down_disabled = value
		if _down_arrow: _down_arrow.disabled = value

signal down_pressed(row: PartySettingRow)
func _down_pressed():
	down_pressed.emit(self)
	
##########
## Icon and role
##########

@export var role: PlayerData.Role = PlayerData.Role.TANK:
	get: return role
	set(value):
		role = value
		_update_role_options()

@export var group: PlayerData.Group = PlayerData.Group.GROUP_ONE:
	get: return group
	set(value):
		group = value
		_update_role_options()

func _update_role_options() -> void:
	# Update icon.
	if _role_icon:
		# TODO: Add a toggle to show job icons instead of role icons.
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
	
	# Populate option list.
	if _job_list:
		# TODO: Allow fake roles.
		_job_list.clear()
		for role_job in PlayerData.get_jobs_for_role(role):
			_job_list.add_item(PlayerData.get_job_name(role_job))

##########
## Jobs
##########
		
var job: PlayerData.Job:
	get:
		var jobs: Array[PlayerData.Job] = PlayerData.get_jobs_for_role(role)
		return jobs[_job_list.selected]
	set(value):
		var job_name: String = PlayerData.get_job_name(value)
		for row_index in range(_job_list.item_count):
			if _job_list.get_item_text(row_index) == job_name:
				_job_list.select(row_index)
				return
		assert(false, "Attempted to set selected job to %s, but a matching row could not be found." % job_name)

##########
## User-controlled player
##########
	
@export var user_controlled: bool:
	get: return user_control_checkbox.is_pressed() if user_control_checkbox else false
	set(value):
		if user_control_checkbox:
			user_control_checkbox.set_pressed(value)
