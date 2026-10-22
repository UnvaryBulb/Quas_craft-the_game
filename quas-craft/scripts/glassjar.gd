extends Node2D

var bread_pieces: int = 0
var sugar_cubes: int = 0
var brewing_progress: float = 0.0
var is_stirring: bool = false
var stir_intensity: float = 0.0

@export var max_bread_for_perfect_kvass: int = 6
@export var max_sugar_for_perfect_kvass: int = 3
@export var brewing_speed: float = 0.5

@onready var liquid_color_rect = $ColorRect
@onready var bubbles_particles = $GPUParticles2D
@onready var water_zone = $WaterZone

var water_color: Color = Color(0.7, 0.9, 1.0, 0.6)
var kvass_color: Color = Color(0.8, 0.5, 0.1, 0.8)

func _ready():
	add_to_group("jar_managers")  # Добавляем себя в группу для поиска ложкой
	liquid_color_rect.color = water_color
	_update_bubbles_intensity(0.0)

func _process(delta):
	# Плавное изменение цвета воды
	var target_color = water_color.lerp(kvass_color, brewing_progress)
	liquid_color_rect.color = target_color
	
	# ГЛАВНОЕ: варим только если есть ингредиенты И размешивают
	if is_stirring and brewing_progress < 1.0:
		if _has_enough_ingredients():
			brewing_progress += brewing_speed * delta * (1.0 + stir_intensity)
			brewing_progress = min(brewing_progress, 1.0)
			print("Варка идёт! Прогресс: ", brewing_progress)
		else:
			print("Не хватает ингредиентов! Хлеб: ", bread_pieces, " Сахар: ", sugar_cubes)
	
	# Плавное затухание интенсивности
	if not is_stirring and stir_intensity > 0:
		stir_intensity -= delta * 2.0
		stir_intensity = max(stir_intensity, 0.0)
		_update_bubbles_intensity(stir_intensity)

# Проверка: хватает ли ингредиентов для варки
func _has_enough_ingredients() -> bool:
	# Минимум: 1 хлеб и 1 сахар (можешь изменить под свой баланс)
	return bread_pieces >= 1 and sugar_cubes >= 1

func add_ingredient(type: String):
	if type == "breadslice":
		bread_pieces += 1
	elif type == "sugar":
		sugar_cubes += 1
	
	print("Добавлено: ", type, " | Хлеб: ", bread_pieces, " | Сахар: ", sugar_cubes)
	_update_bubbles_intensity(stir_intensity + 0.3)

func _update_bubbles_intensity(intensity: float):
	var base_amount = 10
	var extra_amount = int(intensity * 30)
	bubbles_particles.amount = base_amount + extra_amount
	bubbles_particles.speed_scale = 1.0 + intensity

func start_stirring():
	is_stirring = true
	stir_intensity = min(stir_intensity + 0.5, 2.0)

func stop_stirring():
	is_stirring = false

func is_kvass_ready() -> bool:
	return brewing_progress >= 0.95 and bread_pieces >= 3

func get_kvass_quality() -> String:
	if brewing_progress < 0.3:
		return "Вода"
	elif brewing_progress < 0.6:
		return "Мутная брага"
	elif brewing_progress < 0.9:
		return "Почти квас"
	else:
		if bread_pieces >= max_bread_for_perfect_kvass and sugar_cubes >= 2:
			return "ИДЕАЛЬНЫЙ КВАС! 🍺"
		elif bread_pieces >= 3:
			return "Хороший квас"
		else:
			return "Слабый квас"
