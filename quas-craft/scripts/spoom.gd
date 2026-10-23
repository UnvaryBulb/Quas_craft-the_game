extends Draggable
## Ложка. Пока её держат, сообщает банке положение кончика (узел Tip) — банка считает круги.

var _jar: KvassJar

@onready var _tip: Marker2D = $Tip


func _ready() -> void:
	super()
	released.connect(_on_released)


func _physics_process(_delta: float) -> void:
	if not is_held:
		return
	if _jar == null:
		_jar = get_tree().get_first_node_in_group("jar_managers") as KvassJar
		if _jar == null:
			return
	_jar.feed_stir(_tip.global_position)


func _on_released() -> void:
	if _jar != null:
		_jar.stop_stir()
