extends HSlider
## Ползунок громкости эффектов (шина "SFX"). Хранение и применение — в AudioSettings.


func _ready() -> void:
	set_value_no_signal(AudioSettings.sfx_volume)
	value_changed.connect(AudioSettings.set_sfx_volume)
	drag_ended.connect(func(_changed: bool) -> void: AudioSettings.save())


func _exit_tree() -> void:
	AudioSettings.save()
