extends RigidBody2D

@export var pull_strength: float = 50.0
@export var air_resistance: float = 4.0
@export var max_speed: float = 1200.0

var is_grabbed: bool = false
var grab_offset: Vector2 = Vector2.ZERO
var jar_manager: Node2D = null
var is_inside_water: bool = false  # Флаг: ложка в воде?

func _ready():
	self.input_event.connect(_on_input_event)
	_find_jar_manager()

func _find_jar_manager():
	var jars = get_tree().get_nodes_in_group("jar_managers")
	if jars.size() > 0:
		jar_manager = jars[0]
		print("Ложка нашла JarManager!")
	else:
		print("ВНИМАНИЕ: Ложка не нашла JarManager!")

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if is_grabbed:
				stop_grab()

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_grab(event.position)

func start_grab(global_click_pos: Vector2):
	is_grabbed = true
	sleeping = false
	grab_offset = to_local(global_click_pos)
	gravity_scale = 0.3

func stop_grab():
	is_grabbed = false
	gravity_scale = 1.0
	# Когда отпускаем ложку — точно прекращаем размешивание
	if jar_manager:
		jar_manager.stop_stirring()

func _physics_process(delta):
	if is_grabbed:
		var global_grab_offset = grab_offset.rotated(rotation)
		var target_pos = get_global_mouse_position() - global_grab_offset
		var pull_vector = target_pos - global_position
		
		pull_vector = pull_vector.limit_length(200.0)
		
		apply_force(pull_vector * pull_strength, global_grab_offset)
		linear_velocity *= (1.0 - air_resistance * delta)
		angular_velocity *= (1.0 - air_resistance * delta)
		linear_velocity = linear_velocity.limit_length(max_speed)
		
		# Проверяем размешивание ТОЛЬКО если ложка в воде
		_check_stirring()
	else:
		# Если ложку отпустили — не размешиваем
		if jar_manager:
			jar_manager.stop_stirring()

func _check_stirring():
	if jar_manager == null:
		return
	
	# ГЛАВНОЕ: размешиваем только если ложка ВНУТРИ воды
	if not is_inside_water:
		return
	
	# Проверяем скорость движения ложки
	var speed = linear_velocity.length()
	if speed > 50:
		jar_manager.start_stirring()
	else:
		jar_manager.stop_stirring()

# Вызывается, когда ложка входит в зону воды
func _on_water_zone_entered():
	is_inside_water = true
	print("Ложка вошла в воду!")

# Вызывается, когда ложка выходит из зоны воды
func _on_water_zone_exited():
	is_inside_water = false
	if jar_manager:
		jar_manager.stop_stirring()
	print("Ложка вышла из воды!")
