# Globals for accessing user settings.

extends Node


# The global list of player data.
var player_data: Array[PlayerData] = []


# Debugging override.
func _should_reset_save() -> bool: return false


# Attempts to load saved user settings from storage, applying default settings as necessary if saved data is
#   available. Returns true if all data was successfully retrieved and we are ready to go, or false if we need input
#   from the user to validate the data.
# This should only return false on first run or if major changes to settings have been made.
func try_load_settings() -> bool:
	if _should_reset_save():
		print("Ignoring save data and resetting defaults.")
		_populate_default_settings()
		return false
	
	if not FileAccess.file_exists("user://settings.save"):
		# No settings information was found. Fill defaults, then report that the user needs to confirm choices.
		print("No settings file was found on disk. Populating defaults.")
		_populate_default_settings()
		return false
	
	# Read the entire settings save file to a string.
	var settings_file: FileAccess = FileAccess.open("user://settings.save", FileAccess.READ)
	var settings_string: String = settings_file.get_as_text()
	
	# Parse the settings file into JSON.
	var json_reader: JSON = JSON.new()
	var json_error: int = json_reader.parse(settings_string)
	if json_error != OK or typeof(json_reader.get_data()) != TYPE_DICTIONARY:
		print("Error reading settings data from disk. Resetting to defaults.")
		_populate_default_settings()
		return false
	
	var save_data: Dictionary = json_reader.get_data()
	var save_version: int = save_data["version"]
	print("Found settings for version %d." % save_version)
	
	_load_player_data(save_version, save_data["players"])
	
	return true


func write_settings() -> void:
	var save_data: Dictionary
	save_data["version"] = 0
	save_data["players"] = _save_player_data()

	# Save the dictionary as a JSON string.
	var settings_file: FileAccess = FileAccess.open("user://settings.save", FileAccess.WRITE)
	settings_file.store_line(JSON.stringify(save_data))

	
func _populate_default_settings() -> void:
	_populate_initial_player_data()


# Populates the player data list.
func _populate_initial_player_data() -> void:
	player_data.clear()

	# Fill an average full party with a standard composition.
	player_data.append(PlayerData.new(PlayerData.Job.PLD, PlayerData.Group.GROUP_ONE))
	player_data.append(PlayerData.new(PlayerData.Job.WAR, PlayerData.Group.GROUP_TWO))
	player_data.append(PlayerData.new(PlayerData.Job.AST, PlayerData.Group.GROUP_ONE))
	player_data.append(PlayerData.new(PlayerData.Job.SGE, PlayerData.Group.GROUP_TWO))
	player_data.append(PlayerData.new(PlayerData.Job.MNK, PlayerData.Group.GROUP_ONE))
	player_data.append(PlayerData.new(PlayerData.Job.RPR, PlayerData.Group.GROUP_TWO))
	player_data.append(PlayerData.new(PlayerData.Job.BRD, PlayerData.Group.GROUP_ONE))
	player_data.append(PlayerData.new(PlayerData.Job.BLM, PlayerData.Group.GROUP_TWO))
	
	# Set the first player in the list as the player-controlled option.
	player_data[0].user_controlled = true


func _load_player_data(version: int, player_save: Dictionary) -> void:
	player_data.clear()
	
	var encoded_players: Array = player_save["players"]
	for encoded_player in encoded_players:
		var decoded_job: int = encoded_player["job"]
		var decoded_group: int = encoded_player["group"]
		
		var new_data: PlayerData = PlayerData.new(decoded_job, decoded_group)
		new_data.user_controlled = encoded_player["controlled"]
		
		player_data.append(new_data)


func _save_player_data() -> Dictionary:
	var player_save: Dictionary = {}
	
	var encoded_players: Array[Dictionary] = []
	for player in player_data:
		var encoded_player: Dictionary = {}
		
		encoded_player["job"] = player.job
		encoded_player["group"] = player.group
		encoded_player["controlled"] = player.user_controlled
		
		encoded_players.append(encoded_player)
		
	player_save["players"] = encoded_players
	
	return player_save
