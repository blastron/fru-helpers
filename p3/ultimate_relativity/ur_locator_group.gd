class_name UrLocatorGroup extends Node2D


@export var fire_bait: Locator
@export var cw_line_bait: Locator
@export var ccw_line_bait: Locator
@export var eruption_bait: Locator
@export var center_bait: Locator


@export var final_safety_spot: Locator


func as_array() -> Array[Locator]:
	return [fire_bait, cw_line_bait, ccw_line_bait, eruption_bait, center_bait]