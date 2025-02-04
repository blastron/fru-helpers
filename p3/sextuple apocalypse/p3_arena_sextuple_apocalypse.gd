class_name P3ArenaSextupleApocalypse extends Arena

@export var _sa_floor: Sprite2D

var sa_mode: bool = false
var sa_percent: float = 0:
	get:
		if _sa_floor and _sa_floor.visible: return _sa_floor.self_modulate.a
		else: return 0
	set(value):
		if _sa_floor:
			if value <= 0:
				_sa_floor.self_modulate.a = 0
				_sa_floor.visible = false
			else:
				_sa_floor.self_modulate.a = min(1, value)
				_sa_floor.visible = true


const sa_fade_duration: float = 1


func _process(delta: float) -> void:
	if _sa_floor:
		if sa_mode and sa_percent < 1:
			sa_percent += delta / sa_fade_duration
		elif sa_mode and sa_percent > 0:
			sa_percent -= delta / sa_fade_duration
