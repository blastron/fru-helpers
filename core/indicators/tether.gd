class_name Tether extends Line2D


signal task_completed(token: Token)

var _token_a: Token
var _token_b: Token

var _fade_percent: float = 0:
	get: return _fade_percent
	set(value):
		_fade_percent = value
		width = thickness * _fade_percent
		

const _fade_rate: float = 6

const thickness: float = 4

var _destroying: bool = false

func _init(token_a: Token, token_b: Token, color: Color, instant: bool) -> void:
	_token_a = token_a
	_token_b = token_b
	
	default_color = color
	
	_fade_percent = 1 if instant else 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Add initial points.
	add_point(Vector2(0,0))
	add_point(Vector2(0,0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	set_point_position(0, _token_a.position if _token_a != null else Vector2(0,0))
	set_point_position(1, _token_b.position if _token_b != null else Vector2(0,0))
	
	if _destroying:
		_fade_percent -= delta * _fade_rate
		if _fade_percent <= 0:
			task_completed.emit(self)
			queue_free()
	elif _fade_percent < 1:
		_fade_percent = min(1, _fade_percent + delta * _fade_rate)
		if _fade_percent == 1:
			task_completed.emit(self)
		

# Sets this tether to be destroyed. If instant, immediately calls queue_free. Otherwise, fades out, then frees.
func destroy(instant: bool) -> void:
	if instant:
		queue_free()
	else:
		_destroying = true
