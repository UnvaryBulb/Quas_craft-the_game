extends Area2D

@export var water_damp: float = 6.0   # Насколько вязкая вода (чем больше, тем медленнее тонет)
@export var water_gravity: float = 0.2 # Гравитация под водой

func _ready():
	# Подключаем сигналы входа и выхода из воды
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	# Проверяем, что это физическое тело (хлеб, сахар, нож)
	if body is RigidBody2D:
		# Делаем его "мокрым" и плавучим
		body.linear_damp = water_damp
		body.gravity_scale = water_gravity
		
		# Если у тебя есть скрипт на хлебе, можно вызвать специальную функцию
		if body.has_method("get_wet"):
			body.get_wet()

func _on_body_exited(body: Node2D):
	# Если игрок вытащил хлеб из банки ложкой/рукой - он высыхает
	if body is RigidBody2D:
		body.linear_damp = 1.0 # Стандартное сопротивление воздуха
		body.gravity_scale = 1.0 # Возвращаем нормальную гравитацию
		
		if body.has_method("get_dry"):
			body.get_dry()
