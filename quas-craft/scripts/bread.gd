extends RigidBody2D

# --- НАСТРОЙКИ ВЕСА И УПРУГОСТИ (Настраивай в Инспекторе!) ---
@export var pull_strength: float = 60.0   # Сила "магнита". Чем МЕНЬШЕ, тем ТЯЖЕЛЕЕ объект.
@export var air_resistance: float = 4.0   # Трение в воздухе. Гасит раскачивание.
@export var max_speed: float = 1200.0     # Максимальная скорость (чтобы физика не ломалась)
@export var slice_scene: PackedScene
@export var min_cut_speed: float = 150.0
@export var max_cuts: int = 8
@export var final_slice_scene: PackedScene
var is_grabbed: bool = false
var grab_offset: Vector2 = Vector2.ZERO   # Точка, за которую мы схватили объект
var is_being_cut: bool = false
var cut_cooldown: float = 0.0
var cut_count: int = 0
func _ready():
	add_to_group("bread")
	# Подключаем сигнал клика по самому объекту
	# ВАЖНО: У RigidBody2D должен быть CollisionShape2D, иначе клик не сработает!
	self.input_event.connect(_on_input_event)
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			# ЛКМ отпущена где угодно на экране
			if is_grabbed:
				stop_grab()
# Функция обработки клика мыши по объекту
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_grab(event.position) # event.position - это глобальные координаты клика
func try_cut(knife: RigidBody2D):
	if cut_cooldown > 0:
		return
	if knife.linear_velocity.length() < min_cut_speed:
		return
	cut_count += 1
	_execute_cut(knife)
	
func _execute_cut(knife: RigidBody2D):
	cut_cooldown = 0.5
	if cut_count >= max_cuts:
		_spawn_final_slice(knife)
		queue_free()  # Удаляем текущий хлеб
		return
	
	# Обычный разрез - спавним кусочек
	if slice_scene:
		var slice = slice_scene.instantiate()
		get_parent().add_child(slice)
		slice.global_position = global_position + Vector2(40, -20)
		slice.linear_velocity = knife.linear_velocity * 0.8
		slice.angular_velocity = randf_range(-5, 5)
	
	var tween = create_tween()
	var sprite = get_node("Sprite2D") 
	if sprite:
		tween.tween_property(sprite, "scale", sprite.scale * 0.87, 0.2)
	var col_shape = get_node("CollisionShape2D")
	if col_shape and col_shape.shape is RectangleShape2D:
		tween.tween_property(col_shape.shape, "size", col_shape.shape.size * 0.87, 0.2)
	
	apply_impulse(Vector2(-20, -10))
	print("Хлеб разрезан!")
func _spawn_final_slice(knife: RigidBody2D):
	# Спавним финальный кусочек
	if final_slice_scene:
		var final_slice = final_slice_scene.instantiate()
		get_parent().add_child(final_slice)
		final_slice.global_position = global_position
		final_slice.linear_velocity = knife.linear_velocity * 0.5
		final_slice.angular_velocity = randf_range(-3, 3)
		print("Хлеб превратился в финальный кусочек!")
	else:
		print("ОШИБКА: Не назначена финальная сцена кусочка!")
# Начинаем брать объект
func start_grab(global_click_pos: Vector2):
	is_grabbed = true
	sleeping = false # Будим объект, если он "уснул"
	
	# Вычисляем точку захвата в ЛОКАЛЬНЫХ координатах объекта.
	# Это то самое "место, за которое мы беремся"!
	grab_offset = to_local(global_click_pos)
	
	# Чуть снижаем гравитацию, чтобы таскать было удобнее, но вес оставался
	gravity_scale = 0.3 

# Отпускаем объект
func stop_grab():
	is_grabbed = false
	gravity_scale = 1.0 # Возвращаем нормальный вес

func _physics_process(delta):
	if cut_cooldown > 0:
		cut_cooldown -= delta
	if is_grabbed:
		var global_grab_offset = grab_offset.rotated(rotation)
		# Куда мы хотим притянуть объект (позиция мыши минус смещение захвата)
		var target_pos = get_global_mouse_position() - global_grab_offset
		
		# Вектор направления от центра объекта к цели
		var pull_vector = target_pos - global_position
		# МАГИЯ ФИЗИКИ:
		# apply_force(сила, точка_приложения). 
		# Мы прикладываем силу не к центру, а к точке захвата (grab_offset).
		# Из-за этого объект будет естественно вращаться и болтаться!
		apply_force(pull_vector * pull_strength, global_grab_offset)
		
		# Искусственное трение, чтобы объект не летал как бешеный
		linear_velocity *= (1.0 - air_resistance * delta)
		angular_velocity *= (1.0 - air_resistance * delta)
		
		# Ограничиваем скорость, иначе при резком рывке мыши физика сойдет с ума
		linear_velocity = linear_velocity.limit_length(max_speed)
