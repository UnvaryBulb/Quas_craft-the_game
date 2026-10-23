class_name Draggable
extends RigidBody2D
## Базовый класс для всего, что можно взять мышкой
## Сам захват делает DragController (drag_controller.gd). Здесь только физика "булавки":
## точка захвата плавно едет за курсором, а остальное тело болтается по законам физики.

signal grabbed
signal released

@export_group("Drag")
@export var pick_priority: int = 0
@export var follow_speed: float = 14.0
@export var max_accel: float = 6000.0
@export var max_speed: float = 1200.0
## гашение вращения в руке (1/сек), чтобы предмет не крутил сальтухи
@export var held_angular_damp: float = 3.0
@export var max_throw_speed: float = 700.0

@export_group("Upright")
## 0 - болтается свободно. 1 - жёстко супер пупер держит угол rest_angle_deg (для ножа и ложки)
@export_range(0.0, 1.0) var upright_strength: float = 0.0
@export var rest_angle_deg: float = 0.0

## предмет растворился в банке
var consumed: bool = false
var is_held: bool = false
## сюда предмет вернётся, если улетит к хуям
var home_position: Vector2

var _grab_local := Vector2.ZERO
var _can_sleep_before := true


func _ready() -> void:
	home_position = global_position
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE


func grab(world_point: Vector2) -> void:
	if is_held or consumed:
		return
	is_held = true
	_grab_local = global_transform.affine_inverse() * world_point
	_can_sleep_before = can_sleep
	can_sleep = false
	sleeping = false
	grabbed.emit()


func release() -> void:
	if not is_held:
		return
	is_held = false
	can_sleep = _can_sleep_before
	sleeping = false
	linear_velocity = linear_velocity.limit_length(max_throw_speed)
	released.emit()


## предмет брошен в банку. отпускаем, растворяем и удаляем нахуй
func dissolve(duration: float = 0.9) -> void:
	if consumed:
		return
	consumed = true
	call_deferred("_dissolve_now", duration)


func _dissolve_now(duration: float) -> void:
	release()
	collision_layer = 0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _is_lost(state.transform.origin):
		state.transform = Transform2D(0.0, home_position)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		return
	if is_held and not consumed:
		_apply_drag(state)
	if state.linear_velocity.length_squared() > max_speed * max_speed:
		state.linear_velocity = state.linear_velocity.limit_length(max_speed)



func _apply_drag(state: PhysicsDirectBodyState2D) -> void:
	var dt := state.step
	var xf := state.transform
	var r := xf.basis_xform(_grab_local)
	var err := get_global_mouse_position() - (xf.origin + r)
	var w := state.angular_velocity
	var v_point := state.linear_velocity + Vector2(-w * r.y, w * r.x)
	var dv := (err * follow_speed).limit_length(max_speed) - v_point

	var inv_m := state.inverse_mass
	var inv_i := state.inverse_inertia
	var k11 := inv_m + inv_i * r.y * r.y
	var k12 := -inv_i * r.x * r.y
	var k22 := inv_m + inv_i * r.x * r.x
	var det := k11 * k22 - k12 * k12
	if absf(det) > 0.000001:
		var impulse := Vector2(k22 * dv.x - k12 * dv.y, k11 * dv.y - k12 * dv.x) / det
		impulse = impulse.limit_length(max_accel * dt / inv_m)
		state.apply_impulse(impulse, r)

	state.angular_velocity *= maxf(0.0, 1.0 - held_angular_damp * dt)

	if upright_strength > 0.0:
		var ang_err := wrapf(deg_to_rad(rest_angle_deg) - xf.get_rotation(), -PI, PI)
		var w_want := clampf(ang_err * 14.0, -12.0, 12.0)
		state.angular_velocity = lerpf(state.angular_velocity, w_want, upright_strength)


func _is_lost(p: Vector2) -> bool:
	var view := get_viewport_rect().grow(250.0)
	return p.x < view.position.x or p.x > view.end.x or p.y > view.end.y or p.y < -2500.0
