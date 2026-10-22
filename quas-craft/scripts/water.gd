extends Area2D

@export var water_damp: float = 6.0
@export var water_gravity: float = 0.2

var jar_manager: Node2D = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Ищем менеджер банки (родитель или сосед)
	jar_manager = get_parent()

func _on_body_entered(body: Node2D):
	if body is RigidBody2D:
		body.linear_damp = water_damp
		body.gravity_scale = water_gravity
		
		# Определяем тип ингредиента
		if body.has_method("get_ingredient_type") and not body.get_meta("added_to_jar", false):
			var type = body.get_ingredient_type()
			if jar_manager:
				jar_manager.add_ingredient(type)
			# Помечаем, что уже добавили
			body.set_meta("added_to_jar", true)
			print("Добавлен ингредиент: ", type)


func _on_body_exited(body: Node2D):
	if body is RigidBody2D:
		body.linear_damp = 1.0
		body.gravity_scale = 1.0
