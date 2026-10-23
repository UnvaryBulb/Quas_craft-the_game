class_name DragController
extends Node2D
## единая (россия) точка управления мышью - берёт только 1 предмет под курсором

const PICK_RADIUS := 12.0
const PICK_MASK := 6

var held: Draggable = null

var _press_pending := false
var _pick_shape := CircleShape2D.new()


func _ready() -> void:
	_pick_shape.radius = PICK_RADIUS


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pending = true
		else:
			_press_pending = false
			_drop()


func _physics_process(_delta: float) -> void:
	if held != null and (not is_instance_valid(held) or held.consumed):
		held = null
	if held != null and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_drop()
	if _press_pending:
		_press_pending = false
		if held == null:
			_try_grab(get_global_mouse_position())


func _exit_tree() -> void:
	_drop()


func _drop() -> void:
	if held != null and is_instance_valid(held):
		held.release()
	held = null


func _try_grab(point: Vector2) -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _pick_shape
	query.transform = Transform2D(0.0, point)
	query.collision_mask = PICK_MASK
	var hits := get_world_2d().direct_space_state.intersect_shape(query, 16)
	var best: Draggable = null
	var best_score := -INF
	for hit in hits:
		var item := hit["collider"] as Draggable
		if item == null or item.consumed or item.is_held:
			continue
		var score := item.pick_priority * 10000.0 - item.global_position.distance_to(point)
		if score > best_score:
			best_score = score
			best = item
	if best != null:
		held = best
		best.grab(point)
