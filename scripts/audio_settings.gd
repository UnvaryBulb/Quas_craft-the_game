extends Node

const PATH := "user://settings.cfg"

var music_volume: float = 1.0
var sfx_volume: float = 1.0


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		music_volume = float(cfg.get_value("audio", "music_volume", 1.0))
		sfx_volume = float(cfg.get_value("audio", "sfx_volume", 1.0))
	_apply("Music", music_volume)
	_apply("SFX", sfx_volume)


func set_music_volume(value: float) -> void:
	music_volume = value
	_apply("Music", value)


func set_sfx_volume(value: float) -> void:
	sfx_volume = value
	_apply("SFX", value)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.save(PATH)


func _apply(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)
