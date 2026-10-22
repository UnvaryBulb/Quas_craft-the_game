extends RigidBody2D

# --- НАСТРОЙКИ ВЕСА И УПРУГОСТИ (Настраивай в Инспекторе!) ---
@export var pull_strength: float = 100.0   # Сила "магнита". Чем МЕНЬШЕ, тем ТЯЖЕЛЕЕ объект.
@export var air_resistance: float = 20.0   # Трение в воздухе. Гасит раскачивание.
@export var max_speed: float = 1200.0     # Максимальная скорость (чтобы физика не ломалась)

var is_grabbed: bool = false
var grab_offset: Vector2 = Vector2.ZERO

func _ready():
	add_to_group("sugar")  # ВАЖНО: группа "sugar"
	self.input_event.connect(_on_input_event)

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
# В конец файла добавь эту функцию
func get_ingredient_type() -> String:
	if is_in_group("breadslice"):
		return "breadslice"
	elif is_in_group("sugar"):
		return "sugar"
	return ""
