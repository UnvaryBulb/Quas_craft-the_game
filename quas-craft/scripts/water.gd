extends Area2D

@export var water_gravity: float = 160.0
@export var water_linear_damp: float = 3.5
@export var water_angular_damp: float = 3.0

var _jar: KvassJar


func _ready() -> void:
	_jar = get_parent() as KvassJar
	gravity_space_override = Area2D.SPACE_OVERRIDE_REPLACE
	gravity_direction = Vector2.DOWN
	gravity = water_gravity
	linear_damp_space_override = Area2D.SPACE_OVERRIDE_COMBINE
	linear_damp = water_linear_damp
	angular_damp_space_override = Area2D.SPACE_OVERRIDE_COMBINE
	angular_damp = water_angular_damp
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _jar != null and body is Ingredient:
		_jar.absorb(body as Ingredient)
