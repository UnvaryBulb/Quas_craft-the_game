extends Area2D

# Подключаем сигнал в редакторе или через код
func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	# Проверяем, что это хлеб (добавь хлеб в группу "bread")
	if body.is_in_group("bread"):
		# Передаем управление хлебу
		body.try_cut(self.get_parent()) 
