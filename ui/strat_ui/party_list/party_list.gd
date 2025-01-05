class_name PartyList extends Node


@export var _list: VBoxContainer
@export var _row_type: PackedScene


func set_player_data(player_data: Array[PlayerData]) -> void:
	if not _list:
		return

	# Empty the list.
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	
	# Create new rows for each player in the list.
	for data in player_data:
		var new_row: PartyListRow = _row_type.instantiate()
		new_row.player_data = data
		
		_list.add_child(new_row)
