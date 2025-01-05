class_name PlayerToken extends Token


@export var _highlight: Sprite2D


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


var player_data: PlayerData = null:
	get: return player_data
	set(value):
		if player_data != null:
			# We are already associated with player data. Unsubscribe from that now.
			player_data.role_changed.disconnect(self.player_role_changed)

		player_data = value
		player_data.role_changed.connect(self.player_role_changed)
		player_role_changed()


var input_highlight: bool = false:
	get: return input_highlight
	set(value):
		input_highlight = value
		if _highlight: _highlight.visible = value


func player_role_changed():
	match player_data.role:
		PlayerData.Role.TANK:
			match player_data.group:
				PlayerData.Group.GROUP_ONE:
					self.name = "player_T1"
					self.icon.texture = icon_job_t1
				PlayerData.Group.GROUP_TWO:
					self.name = "player_T2"
					self.icon.texture = icon_job_t2
		PlayerData.Role.HEALER:
			match player_data.group:
				PlayerData.Group.GROUP_ONE:
					self.name = "player_H1"
					self.icon.texture = icon_job_h1
				PlayerData.Group.GROUP_TWO:
					self.name = "player_H2"
					self.icon.texture = icon_job_h2
		PlayerData.Role.MELEE:
			match player_data.group:
				PlayerData.Group.GROUP_ONE:
					self.name = "player_M1"
					self.icon.texture = icon_job_m1
				PlayerData.Group.GROUP_TWO:
					self.name = "player_M2"
					self.icon.texture = icon_job_m2
		PlayerData.Role.RANGED:
			match player_data.group:
				PlayerData.Group.GROUP_ONE:
					self.name = "player_R1"
					self.icon.texture = icon_job_r1
				PlayerData.Group.GROUP_TWO:
					self.name = "player_R2"
					self.icon.texture = icon_job_r2
		_:
			self.icon.texture = icon_job_unknown
