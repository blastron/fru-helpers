class_name MovementOrder extends RefCounted

var player: PlayerToken
var locator: Locator

func _init(in_player: PlayerToken, in_locator: Locator):
	player = in_player
	locator = in_locator
