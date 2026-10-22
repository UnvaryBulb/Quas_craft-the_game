extends HSlider

# Ссылаемся на ползунки
@onready var sfx_slider = $"."

# Индексы шин (чтобы не искать их каждый раз)

var sfx_bus_index: int

func _ready():
	# Получаем индексы наших шин

	sfx_bus_index = AudioServer.get_bus_index("SFX")
	# Подключаем сигналы изменения ползунков

	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Загружаем сохраненные настройки (если они есть)
	_load_settings()

# Функция для Музыки
func _on_music_volume_changed(value: float):
	# Ползунок дает значение от 0.0 до 1.0. Godot требует Децибелы (dB).
	# Функция linear_to_db переводит 0.0 в -inf (тишина), а 1.0 в 0 dB (максимум)
	var db = linear_to_db(value)

	_save_settings() # Сохраняем при каждом изменении

# Функция для Эффектов
func _on_sfx_volume_changed(value: float):
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(sfx_bus_index, db)
	_save_settings()

# --- СОХРАНЕНИЕ И ЗАГРУЗКА (Чтобы настройки не сбрасывались) ---

func _save_settings():
	var config = ConfigFile.new()
	# Сохраняем значения ползунков (от 0.0 до 1.0)

	config.set_value("audio", "sfx_volume", sfx_slider.value)
	# Сохраняем файл в пользовательскую папку
	config.save("user://settings.cfg")

func _load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		# Если файл есть, применяем значения
		var music_vol = config.get_value("audio", "music_volume", 1.0)
		var sfx_vol = config.get_value("audio", "sfx_volume", 1.0)
		
		# Обновляем ползунки

		sfx_slider.value = sfx_vol
		
		# Применяем громкость к шинам
		_on_music_volume_changed(music_vol)
		_on_sfx_volume_changed(sfx_vol)
