class_name Arena extends CanvasLayer


@export var _root: Node
@export var _player_token_type: PackedScene


signal locator_clicked(locator: Locator)


func _ready() -> void:
	assert(_root)
	assert(_player_token_type)
	
	# Find and register all dynamic elements created in the editor.
	for token: Token in _root.find_children("", "Token"):
		_register_token(token)
	
	for locator: Locator in _root.find_children("", "Locator"):
		_register_locator(locator)


func create_player_tokens(player_data: Array[PlayerData]) -> Array[PlayerToken]:
	var output: Array[PlayerToken]
	for player in player_data:
		var new_token: PlayerToken = _player_token_type.instantiate()
		new_token.player_data = player

		_root.add_child(new_token)
		_register_token(new_token)
		
		output.append(new_token)
		
	return output


##########
## Z-SORTING
##########


enum _Layers {
	INACTIVE_LOCATORS,
	NPC_HITBOXES,
	GROUND_INDICATORS,
	FLOATING_INDICATORS,
	GENERIC_TOKENS,
	NPC_TOKENS,
	PLAYER_TOKENS,
	USER_TOKEN,
	IMPORTANCE_MOD,
	ACTIVE_LOCATORS = 99,
	EXPLAINER = 100
}


static func get_layer_name(layer: _Layers) -> String:
	if layer == _Layers.EXPLAINER: return "EXPLAINER"
	if layer == _Layers.ACTIVE_LOCATORS: return "ACTIVE_LOCATORS"
	
	if layer >= _Layers.IMPORTANCE_MOD:
		return "%s (important)" % _Layers.keys()[layer - _Layers.IMPORTANCE_MOD]
	else: return _Layers.keys()[layer]


##########
## IMPORTANCE AND Z-SORTING
##########


# Registers a token and sets its Z-order.
func _register_token(token: Token) -> void:
	print("ARENA: Registering token %s." % token.name)
	
	if token.get_parent() != _root: token.reparent(_root)
		

	token.importance_changed.connect(self._sort_object)
	_sort_object(token)


# Adjusts the Z-order of the given object to sort tokens into their groups and put important objects on top of them all.
func _sort_object(object: Variant) -> void:
	if object is Token:
		if object is PlayerToken:
			object.z_index = _Layers.PLAYER_TOKENS if not object.player_data.user_controlled else _Layers.USER_TOKEN
			object.z_index += _Layers.IMPORTANCE_MOD if object.is_important else 0
		elif object is EnemyToken:
			object.z_index = _Layers.NPC_TOKENS + (_Layers.IMPORTANCE_MOD if object.is_important else 0)
			object.hitbox.z_index = _Layers.NPC_HITBOXES - object.z_index
		else:
			# This is a generic token. Put the entire token on the non-player layer.
			object.z_index = _Layers.GENERIC_TOKENS + (_Layers.IMPORTANCE_MOD if object.is_important else 0)
	
	elif object is Locator:
		object.z_index = _Layers.ACTIVE_LOCATORS if object.state == Locator.State.ENABLED else _Layers.INACTIVE_LOCATORS
	
	elif object is Indicator:
		object.z_index = _Layers.GROUND_INDICATORS if object.is_static_indicator() else _Layers.FLOATING_INDICATORS
		object.z_index += _Layers.IMPORTANCE_MOD if object.is_important else 0
	
	elif object is Node2D:
		# As a fallback for nodes we don't know anything about, stick them on the generic token layer.
		object.z_index = _Layers.GENERIC_TOKENS
	
	elif object is Control:
		# As a fallback for controls we don't know anything about, stick them on the explainer layer, since they must
		#   be important.
		object.z_index = _Layers.EXPLAINER
	
	print("ARENA: Sorted %s to layer %s." % [object.name, get_layer_name(object.z_index)])


##########
## TOKENS
##########


##########
## LOCATORS
##########


var _locators: Array[Locator]


# Registers a locator and sets its Z-order.
func _register_locator(locator: Locator) -> void:
	print("ARENA: Registering locator %s." % locator.name)

	if locator.get_parent() != _root: locator.reparent(_root)
	_locators.append(locator)	

	locator.on_clicked.connect(self._on_locator_clicked)
	locator.state_changed.connect(self._sort_object)
	_sort_object(locator)


# Gets a list of registered locators.
func get_locators() -> Array[Locator]:
	return _locators.duplicate()


func _on_locator_clicked(locator: Locator) -> void:
	locator_clicked.emit(locator)

	
##########
## INDICATORS
##########


var _indicators: Array[Indicator]


# Registers an indicator and sets its Z-order.
func _register_indicator(indicator: Indicator) -> void:
	print("ARENA: Registering indicator %s." % indicator.name)

	_root.add_child(indicator)
	_indicators.append(indicator)

	indicator.importance_changed.connect(self._sort_object)
	_sort_object(indicator)


func add_beam_indicator(indicator_name: String, length: float, width: float, color: Color) -> Beam:
	var beam: Beam = Beam.new(length, width, color)
	beam.name = indicator_name

	_register_indicator(beam)
	return beam


func add_circle_indicator(indicator_name: String, radius: float, invert: bool, color: Color) -> Circle:
	var circle: Circle = Circle.new(radius, invert, color)
	circle.name = indicator_name

	_register_indicator(circle)
	return circle


func add_cone_indicator(indicator_name: String, radius: float, arc_width: float, color: Color) -> Cone:
	var cone: Cone = Cone.new(radius, arc_width, color)
	cone.name = indicator_name

	_register_indicator(cone)
	return cone


func add_donut_indicator(indicator_name: String, inner_radius: float, outer_radius: float, color: Color) -> Donut:
	var donut: Donut = Donut.new(inner_radius, outer_radius, color)
	donut.name = indicator_name

	_register_indicator(donut)
	return donut


func add_tether_indicator(indicator_name: String, anchor_a: Token, anchor_b: Token, color: Color) -> Tether:
	var tether: Tether = Tether.new(anchor_a, anchor_b, color)
	tether.name = indicator_name
	
	_register_indicator(tether)
	return tether


# Finds the first indicator with the given name.
func get_indicator(indicator_name: String) -> Indicator:
	var found_indicators: Array[Indicator] = get_indicators(indicator_name)
	if found_indicators.is_empty(): return null
	else: return found_indicators[0]


# Finds all indicators with the given name.
func get_indicators(indicator_name: String) -> Array[Indicator]:
	var output: Array[Indicator]
	for child in _indicators:
		if child.name == indicator_name: output.append(child)
	return output


# Removes the indicator from the arena.
func remove_indicator(indicator: Indicator) -> void:
	if not indicator: return
	
	var indicator_index: int = _indicators.find(indicator)
	if indicator_index >= 0:
		_indicators.remove_at(indicator_index)
	
	indicator.queue_free()


##########
## EXPLAINERS
##########


const _explainer_arrow_color: Color = Color(0.98, 0.31, 0.26)
const _explainer_arrow_border_color: Color = Color(0.17, 0.17, 0.17)


var _explainers: Array[Node]


func add_explainer_arrow(points: Array[Vector2]) -> void:
	var arrow: Arrow = Arrow.new(points)
	arrow.color = _explainer_arrow_color
	arrow.border_color = _explainer_arrow_border_color
	arrow.z_index = _Layers.EXPLAINER
	
	_root.add_child(arrow)
	_explainers.append(arrow)


func clear_explainers() -> void:
	for explainer in _explainers:
		_root.remove_child(explainer)
		explainer.queue_free()
	_explainers.clear()
