class_name KvassJar
extends Node2D
## банка с водой: считает, что в неё упало, и варит меф, пока ложка ходит по кругу

signal ingredients_changed(bread: int, sugar: int)
signal progress_changed(value: float)
signal finished(title: String, score: float)

## идеальный рецепт. от него зависит качество кваса
@export var ideal_bread: int = 6
@export var ideal_sugar: int = 3
## сколько полных кругов ложкой нужно для готового кваса
@export var laps_needed: float = 5.0
## ближе к центру банки круги не считаются
@export var stir_min_radius: float = 14.0
@export var water_color: Color = Color(0.0, 0.691, 0.909, 0.6)
@export var kvass_color: Color = Color(0.51, 0.31, 0.04, 0.8)

const MIN_STEP := 0.004
const MIN_SWEEP := 1.2

var bread_pieces: int = 0
var sugar_cubes: int = 0
var progress: float = 0.0
var is_done: bool = false
var stir_intensity: float = 0.0

var _prev_angle := 0.0
var _has_prev := false
var _dir := 0.0
var _run := 0.0
var _run_counted := false

@onready var _liquid: ColorRect = $ColorRect
@onready var _bubbles: GPUParticles2D = $GPUParticles2D
@onready var _water_shape: CollisionShape2D = $WaterZone/wattercol


func _ready() -> void:
	add_to_group("jar_managers")
	_liquid.color = water_color
	_bubbles.emitting = false


func _process(delta: float) -> void:
	var target := water_color.lerp(kvass_color, progress)
	_liquid.color = _liquid.color.lerp(target, 1.0 - exp(-6.0 * delta))
	stir_intensity = maxf(stir_intensity - delta * 1.5, 0.0)
	var want_bubbles := stir_intensity > 0.05
	if _bubbles.emitting != want_bubbles:
		_bubbles.emitting = want_bubbles
	_bubbles.speed_scale = 1.0 + stir_intensity * 1.5


## вызывается зоной воды, когда в банку попало что-то
func absorb(item: Ingredient) -> void:
	if is_done or item.consumed:
		return
	var kind := item.get_kind()
	if kind == &"bread":
		bread_pieces += 1
	elif kind == &"sugar":
		sugar_cubes += 1
	else:
		return
	item.dissolve()
	stir_intensity = maxf(stir_intensity, 0.6)  # пузырьки
	ingredients_changed.emit(bread_pieces, sugar_cubes)


func is_point_in_water(world_point: Vector2) -> bool:
	return _water_rect().has_point(world_point)


## ложка сообщает положение кончика. считаем, на какой угол он обошёл центр банки.
func feed_stir(tip_world: Vector2) -> void:
	if is_done:
		return
	if not is_point_in_water(tip_world):
		stop_stir()
		return
	var offset := tip_world - _water_shape.global_position
	if offset.length() < stir_min_radius:
		return
	var angle := offset.angle()
	if _has_prev:
		_add_sweep(angle_difference(_prev_angle, angle))
	_prev_angle = angle
	_has_prev = true


func stop_stir() -> void:
	_has_prev = false
	_dir = 0.0
	_run = 0.0
	_run_counted = false


func quality_score() -> float:
	var b := 1.0 - minf(absf(float(bread_pieces - ideal_bread)) / float(maxi(ideal_bread, 1)), 1.0)
	var s := 1.0 - minf(absf(float(sugar_cubes - ideal_sugar)) / float(maxi(ideal_sugar, 1)), 1.0)
	return b * 0.5 + s * 0.5


func quality_title(score: float) -> String:
	if score >= 0.8:
		return "ИДЕАЛЬНЫЙ КВАС!"
	if score >= 0.6:
		return "Хороший квас"
	if score >= 0.35:
		return "Слабый квас"
	return "Мутная брага"


func _add_sweep(delta_angle: float) -> void:
	var step := absf(delta_angle)
	if step < MIN_STEP:
		return
	stir_intensity = minf(stir_intensity + step * 2.0, 1.0)
	var dir := signf(delta_angle)
	if dir != _dir:
		_dir = dir
		_run = 0.0
		_run_counted = false
	_run += step
	var counted := 0.0
	if _run >= MIN_SWEEP:
		counted = step if _run_counted else _run
		_run_counted = true
	if counted > 0.0 and bread_pieces > 0 and sugar_cubes > 0:
		_set_progress(progress + counted / (TAU * laps_needed))


func _set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	progress_changed.emit(progress)
	if progress >= 1.0:
		_finish()


func _finish() -> void:
	is_done = true
	stop_stir()
	var score := quality_score()
	finished.emit(quality_title(score), score)


func _water_rect() -> Rect2:
	var size := (_water_shape.shape as RectangleShape2D).size
	return Rect2(_water_shape.global_position - size * 0.5, size)
