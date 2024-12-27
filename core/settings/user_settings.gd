# Globals for accessing user settings.

extends Node

func get_player_data() -> Array[PlayerData]:
	if _player_data.is_empty():
		_populate_player_data()
	
	return _player_data

var _player_data: Array[PlayerData] = []

# Populates the player data list.
func _populate_player_data() -> void:
	_player_data.clear()

	_player_data.append(PlayerData.new(PlayerData.Job.PLD, PlayerData.Group.GROUP_ONE))
	_player_data.append(PlayerData.new(PlayerData.Job.WAR, PlayerData.Group.GROUP_TWO))
	_player_data.append(PlayerData.new(PlayerData.Job.AST, PlayerData.Group.GROUP_ONE))
	_player_data.append(PlayerData.new(PlayerData.Job.SGE, PlayerData.Group.GROUP_TWO))
	_player_data.append(PlayerData.new(PlayerData.Job.MNK, PlayerData.Group.GROUP_ONE))
	_player_data.append(PlayerData.new(PlayerData.Job.RPR, PlayerData.Group.GROUP_TWO))
	_player_data.append(PlayerData.new(PlayerData.Job.BRD, PlayerData.Group.GROUP_ONE))
	_player_data.append(PlayerData.new(PlayerData.Job.BLM, PlayerData.Group.GROUP_TWO))
	
	# TEMP
	_player_data[randi_range(0, 7)].user_controlled = true
	