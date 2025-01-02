extends CanvasLayer

@export var _party_list: VBoxContainer
var _party_list_user_control_group: ButtonGroup

@export var _party_row_type: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_party_list_user_control_group = ButtonGroup.new()
	
	$background.gui_input.connect(self._on_background_input_event)
	self.visibility_changed.connect(self._on_visibility_changed)

func _on_background_input_event(event: InputEvent) -> void:
	if event.is_pressed():
		self.visible = false
		
func _on_visibility_changed() -> void:
	if visible:
		_load_party_list()
	else:
		_save_party_list()
		UserSettings.write_settings()

		
func _load_party_list() -> void:
	if not _party_list:
		return
		
	print("Loading party list data.")
		
	# Empty the party list.
	for child in _party_list.get_children():
		_party_list.remove_child(child)
		child.queue_free()
	_party_list_user_control_group.get_buttons().clear()
	
	var player_data: Array[PlayerData] = UserSettings.player_data
	for data in player_data:
		var new_row: PartySettingRow = _party_row_type.instantiate()
		new_row.role = PlayerData.get_role_for_job(data.job)
		new_row.group = data.group
		new_row.job = data.job
		new_row.user_controlled = data.user_controlled

		new_row.up_pressed.connect(self._party_row_up)
		new_row.down_pressed.connect(self._party_row_down)
		
		_party_list.add_child(new_row)

		_party_list_user_control_group.get_buttons().append(new_row.user_control_checkbox)
		new_row.user_control_checkbox.button_group = _party_list_user_control_group
		
	_party_list.get_child(0).up_disabled = true
	_party_list.get_child(-1).down_disabled = true
	
func _save_party_list() -> void:
	if not _party_list:
		return
		
	print("Saving party list data.")
	
	var player_data: Array[PlayerData] = UserSettings.player_data
	player_data.clear()
	for child in _party_list.get_children():
		var data: PlayerData = PlayerData.new(child.job, child.group)
		data.user_controlled = child.user_controlled
		player_data.append(data)

		
func _party_row_up(row: PartySettingRow):
	var index: int = row.get_index()
	if index > 0:
		_swap_party_rows(index, index - 1)
		
func _party_row_down(row: PartySettingRow):
	var index: int = row.get_index()
	if index < _party_list.get_child_count() - 1:
		_swap_party_rows(index, index + 1)
		
func _swap_party_rows(index_a: int, index_b: int):
	var row_a: PartySettingRow = _party_list.get_child(index_a)
	var row_b: PartySettingRow = _party_list.get_child(index_b)
	
	_party_list.move_child(row_a, index_b)
	row_a.up_disabled = index_b == 0
	row_a.down_disabled = index_b == _party_list.get_child_count() - 1

	_party_list.move_child(row_b, index_a)
	row_b.up_disabled = index_a == 0
	row_b.down_disabled = index_a == _party_list.get_child_count() - 1
