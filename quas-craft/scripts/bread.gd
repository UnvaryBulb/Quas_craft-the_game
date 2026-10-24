class_name Bread
extends Draggable
## буханка. нож вызывает cut(). буханка укорачивается справа и выбрасывает кусок хлеба

signal sliced(slice: Draggable)

## через сколько секунд после предпоследнего разреза остаток режется сам
@export var auto_cut_delay: float = 0.3
@export var slice_scene: PackedScene
## сколько кусков получится из буханки (каждый разрез отрезает 1/max_cuts длины)
@export var max_cuts: int = 8
## пауза между разрезами, чтобы один взмах не резал всё к хуям
@export var cut_cooldown: float = 0.35
## где появится кусок относительно нового торца буханки
@export var slice_spawn_offset := Vector2(18.0, -10.0)

var cuts_made: int = 0

var _cooldown: float = 0.0
var _shape: RectangleShape2D
var _full_length: float = 0.0
var _sprite_len: float = 0.0
var _col_x0: float = 0.0
var _sprite_x0: float = 0.0
var _sprite_scale_x0: float = 1.0

@onready var _col: CollisionShape2D = $CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	add_to_group("bread")
	# форма - общий ресурс сцены: копируем, иначе укорочение одной буханки
	# менялось бы у всех (и "запоминалось" между перезапусками уровня)
	_shape = (_col.shape as RectangleShape2D).duplicate()
	_col.shape = _shape
	_full_length = _shape.size.x
	_col_x0 = _col.position.x
	_sprite_x0 = _sprite.position.x
	_sprite_scale_x0 = _sprite.scale.x
	if _sprite.texture != null:
		_sprite_len = _sprite.texture.get_width() * absf(_sprite_scale_x0)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)


func cut(blade_velocity: Vector2) -> void:
	if _cooldown > 0.0 or consumed or cuts_made >= max_cuts:
		return
	cuts_made += 1
	_cooldown = cut_cooldown

	if cuts_made >= max_cuts:
		# последний кусок: буханка целиком превращается в него
		consumed = true
		_spawn_slice(Vector2(_col.position.x, -30.0), blade_velocity)
		queue_free()
		return

	_set_length_ratio(float(max_cuts - cuts_made) / float(max_cuts))
	var edge_x := _col.position.x + _shape.size.x * 0.5
	_spawn_slice(Vector2(edge_x, 0.0) + slice_spawn_offset, blade_velocity)

	# остался один кусок размером с обычный ломтик: режем его сами
	if cuts_made == max_cuts - 1:
		cuts_made = max_cuts
		_auto_cut_last(blade_velocity)


## левый торец остаётся на месте, укорачивается правый (откуда отрезаем).
func _set_length_ratio(ratio: float) -> void:
	_shape.size = Vector2(_full_length * ratio, _shape.size.y)
	_col.position.x = _col_x0 - _full_length * (1.0 - ratio) * 0.5
	_sprite.scale.x = _sprite_scale_x0 * ratio
	_sprite.position.x = _sprite_x0 - _sprite_len * (1.0 - ratio) * 0.5
	sleeping = false


func _spawn_slice(local_pos: Vector2, blade_velocity: Vector2) -> void:
	if slice_scene == null:
		push_warning("Bread: не назначена slice_scene")
		return
	var slice := slice_scene.instantiate() as Draggable
	var parent := get_parent()
	parent.add_child(slice)
	# рисуем кусок под банкой, как кубики сахара: ставим его в дереве перед банкой
	var jar := get_tree().get_first_node_in_group("jar_managers")
	if jar != null and jar.get_parent() == parent:
		parent.move_child(slice, jar.get_index())
	slice.global_position = to_global(local_pos)
	slice.home_position = slice.global_position
	# кусок выскакивает вправо-вверх. скорость ножа добавляем с ограничением, чтобы не улетал
	slice.linear_velocity = Vector2(randf_range(60.0, 130.0), randf_range(-220.0, -120.0)) \
		+ blade_velocity.limit_length(300.0) * 0.15
	slice.angular_velocity = randf_range(-4.0, 4.0)
	sliced.emit(slice)

func _auto_cut_last(blade_velocity: Vector2) -> void:
	consumed = true  # пока ждём, буханку уже нельзя взять
	release()
	await get_tree().create_timer(auto_cut_delay).timeout
	if not is_inside_tree():
		return
	_spawn_slice(Vector2(_col.position.x, -30.0), blade_velocity)
	queue_free()
