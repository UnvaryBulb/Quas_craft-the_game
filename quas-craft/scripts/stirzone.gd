extends Area2D

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	print("🔍 SpoonDetector готов! Ждёт пересечений...")

func _on_area_entered(area: Area2D):
	print("⚡ SpoonDetector пересёкся с Area2D: ", area.name, " | Группы: ", area.get_groups())
	if area.is_in_group("water_zone"):
		print("✅ Это вода! Вызываем _on_water_zone_entered")
		get_parent()._on_water_zone_entered()

func _on_area_exited(area: Area2D):
	print("⚡ SpoonDetector вышел из Area2D: ", area.name)
	if area.is_in_group("water_zone"):
		print("❌ Выход из воды! Вызываем _on_water_zone_exited")
		get_parent()._on_water_zone_exited()
