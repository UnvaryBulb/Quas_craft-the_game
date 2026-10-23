extends HSlider
## Ползунок громкости музыки (шина "Music"). Хранение и применение — в AudioSettings.


func _ready() -> void:
	set_value_no_signal(AudioSettings.music_volume)
	value_changed.connect(AudioSettings.set_music_volume)
	drag_ended.connect(func(_changed: bool) -> void: AudioSettings.save())


func _exit_tree() -> void:
	AudioSettings.save()
