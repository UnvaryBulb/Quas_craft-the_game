extends Node2D
## корешок игровой сцены

const MENU_SCENE := "res://scenes/menu.tscn"


func _ready() -> void:
	add_child(DragController.new())

	var hud := Hud.new()
	add_child(hud)
	hud.setup(get_tree().get_first_node_in_group("jar_managers") as KvassJar)
	hud.restart_requested.connect(restart)
	hud.menu_requested.connect(back_to_menu)

	var music := get_node_or_null("MusicPlayer") as AudioStreamPlayer
	if music != null and music.stream is AudioStreamOggVorbis:
		(music.stream as AudioStreamOggVorbis).loop = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back_to_menu()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		restart()


func restart() -> void:
	get_tree().reload_current_scene()


func back_to_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
