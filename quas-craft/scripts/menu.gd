extends Node2D
@onready var button_focusSFX = $SFXbutton_focus
@onready var button_pressSFX = $SFXbutton_press
func _ready() -> void:
	var music := get_node_or_null("MusicPlayer") as AudioStreamPlayer
	if music != null and music.stream is AudioStreamOggVorbis:
		(music.stream as AudioStreamOggVorbis).loop = true


func _on_play_pressed() -> void:
	
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_pressed() -> void:
	
	get_tree().quit()


func _on_play_mouse_entered() -> void:
	button_focusSFX.play(1.0)


func _on_quit_mouse_entered() -> void:
	button_focusSFX.play(1.0)


func _on_quit_button_down() -> void:
	button_pressSFX.play(1.0)


func _on_play_button_down() -> void:
	button_pressSFX.play(1.0)
