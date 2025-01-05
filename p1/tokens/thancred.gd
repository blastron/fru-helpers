@tool
class_name Thancred extends EnemyToken


@export var _fire_aura: Sprite2D
@export var _lightning_aura: Sprite2D


const _aura_animate_time: float = 0.2


enum Aura { NONE, FIRE, LIGHTNING }
var aura: Aura = Aura.NONE:
	get: return aura
	set(value):
		aura = value
		
		if aura != Aura.NONE:
			_fire_aura.visible = aura == Aura.FIRE
			_fire_aura.self_modulate.a = 0
			
			_lightning_aura.visible = aura == Aura.LIGHTNING
			_lightning_aura.self_modulate.a = 0


func _ready() -> void:
	super()
	
	_fire_aura.visible = aura == Aura.FIRE
	_lightning_aura.visible = aura == Aura.LIGHTNING


func _process(delta: float) -> void:
	super(delta)
	
	if Engine.is_editor_hint():
		return
	
	if aura == Aura.NONE:
		_fire_aura.self_modulate.a = max(0, _fire_aura.self_modulate.a - delta / _aura_animate_time)
		_lightning_aura.self_modulate.a = max(0, _lightning_aura.self_modulate.a - delta / _aura_animate_time)
	else:
		_fire_aura.self_modulate.a = min(1, _fire_aura.self_modulate.a + delta / _aura_animate_time)
		_lightning_aura.self_modulate.a = min(1, _lightning_aura.self_modulate.a + delta / _aura_animate_time)
