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


func add_tracer(rotation: float, is_arc: bool, clockwise: bool) -> SexApocTracer:
	var tracer: SexApocTracer = SexApocTracer.new()
	_root.add_child(tracer)
	_sort_object(tracer)
	tracer.name = "tracer_" + name
	tracer.rotation = rotation
	tracer.is_arc = is_arc
	tracer.clockwise = clockwise
	return tracer


func cap_tracer_progress(percent: float):
	for child in _root.get_children():
		if child is SexApocTracer:
			child.completion_cap = percent


func uncap_tracer_progress():
	for child in _root.get_children():
		if child is SexApocTracer:
			child.completion_cap = -1
