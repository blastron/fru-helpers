class_name SexApocLocatorGroup extends Node2D


@export var flare_locator: Locator


@export_group("Locators - Eruptions")
@export var eruption_in_center: Locator
@export var eruption_in_cw: Locator
@export var eruption_in_ccw: Locator
@export var eruption_out_cw: Locator
@export var eruption_out_ccw: Locator

var eruption_locators: Array[Locator]:
	get: return [eruption_in_center, eruption_out_cw, eruption_out_ccw]


@export_group("Locators - Second Stack")
@export var second_stack_in: Locator


@export_group("Locators - Darkest Dance")
@export var tank_bait: Locator
@export var boss_leap: Locator


@export_group("Locators - Knockback")
@export var kb_origin_west: Locator
@export var kb_origin_east: Locator
