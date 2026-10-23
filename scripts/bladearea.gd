extends Area2D
## нож. если движется быстро и касается буханки, то режем.

@export var min_cut_speed: float = 280.0

var speed: float = 0.0
var _last_pos := Vector2.ZERO


func _ready() -> void:
	_last_pos = global_position


func _physics_process(delta: float) -> void:
	var velocity := (global_position - _last_pos) / delta
	_last_pos = global_position
	speed = velocity.length()
	if speed < min_cut_speed:
		return
	for body in get_overlapping_bodies():
		if body is Bread:
			body.cut(velocity)
