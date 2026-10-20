extends RigidBody2D

# --- НАСТРОЙКИ ВЕСА И УПРУГОСТИ (Настраивай в Инспекторе!) ---
@export var pull_strength: float = 70.0   # Сила "магнита". Чем МЕНЬШЕ, тем ТЯЖЕЛЕЕ объект.
@export var air_resistance: float = 4.0   # Трение в воздухе. Гасит раскачивание.
@export var max_speed: float = 1200.0     # Максимальная скорость (чтобы физика не ломалась)

var is_grabbed: bool = false
var grab_offset: Vector2 = Vector2.ZERO   # Точка, за которую мы схватили объект

func _ready():
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
