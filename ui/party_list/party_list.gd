extends Node

@export var _list: VBoxContainer
@export var _row_type: PackedScene

func _ready() -> void:
	_load_party_list()
	
func _load_party_list() -> void:
	if not _list:
		return

	# Empty the list.
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	
	var player_data: Array[PlayerData] = UserSettings.get_player_data()
	for data in player_data:
		var new_row: PartyListRow = _row_type.instantiate()
		new_row.player_data = data
		
		_list.add_child(new_row)
