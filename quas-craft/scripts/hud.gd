class_name Hud
extends CanvasLayer
## интерфейс: счётчики ингредиентов, прогресс брожения, итог. строится кодом

signal restart_requested
signal menu_requested

var _jar: KvassJar
var _counts: Label
var _bar: ProgressBar
var _status: Label
var _result: PanelContainer
var _result_title: Label
var _result_info: Label
var _hint: Label


func _ready() -> void:
	layer = 10
	_build()


func setup(jar: KvassJar) -> void:
	_jar = jar
	if _jar == null:
		return
	_jar.ingredients_changed.connect(func(_b: int, _s: int) -> void: _refresh())
	_jar.progress_changed.connect(func(_v: float) -> void: _refresh())
	_jar.finished.connect(_on_finished)
	_refresh()


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	# Оставляем легкую тень/обводку текста для максимальной читаемости
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 4)
	return label


func _create_rounded_panel_style(bg_color: Color, corner_radius: int, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	if border_width > 0:
		style.border_color = border_color
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
	return style


func _build() -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	add_child(margin)

	# плашка для верхнего HUD
	var main_panel := PanelContainer.new()
	main_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	main_panel.add_theme_stylebox_override("panel", _create_rounded_panel_style(
		Color(0.1, 0.08, 0.06, 0.75), # цвет фона
		12,                            # радиус скругления углов
		Color(1, 1, 1, 0.15),          # цвет обводки
		1                              # толщина обводки в пикселях
	))
	margin.add_child(main_panel)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	main_panel.add_child(box)

	_counts = _make_label(20)
	box.add_child(_counts)

	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.step = 0.001
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(280, 14)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# прогресс кваса
	var pb_bg := _create_rounded_panel_style(Color(0.05, 0.04, 0.03, 0.9), 6)
	var pb_fill := _create_rounded_panel_style(Color(0.443, 0.616, 0.012, 1.0), 6) # Медово-квасный цвет заполнения
	_bar.add_theme_stylebox_override("background", pb_bg)
	_bar.add_theme_stylebox_override("fill", pb_fill)
	box.add_child(_bar)

	_status = _make_label(16)
	box.add_child(_status)
	
	
	var hint_margin := MarginContainer.new()
	hint_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_margin.add_theme_constant_override("margin_left", 18)
	hint_margin.add_theme_constant_override("margin_bottom", 18)
	hint_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	add_child(hint_margin)

	var hint_panel := PanelContainer.new()
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_panel.add_theme_stylebox_override("panel", _create_rounded_panel_style(
		Color(0.1, 0.08, 0.06, 0.75), 10, Color(1, 1, 1, 0.15), 1
	))
	hint_margin.add_child(hint_panel)

	_hint = _make_label(14)
	_hint.text = "Совет: следите за пропорциями!"
	hint_panel.add_child(_hint)

	# окно результата
	var wrap := MarginContainer.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_theme_constant_override("margin_top", 90)
	add_child(wrap)
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(column)

	_result = PanelContainer.new()
	_result.visible = false
	_result.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# окно победы/поражения
	_result.add_theme_stylebox_override("panel", _create_rounded_panel_style(
		Color(0.15, 0.11, 0.08, 0.95), 16, Color(1, 0.8, 0.4, 0.4), 2
	))
	column.add_child(_result)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	_result.add_child(inner)

	_result_title = Label.new()
	_result_title.add_theme_font_size_override("font_size", 30)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(_result_title)

	_result_info = Label.new()
	_result_info.add_theme_font_size_override("font_size", 16)
	_result_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(_result_info)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	inner.add_child(buttons)

	var again := Button.new()
	again.text = "Сварить ещё раз"
	again.pressed.connect(func() -> void: restart_requested.emit())
	buttons.add_child(again)

	var to_menu := Button.new()
	to_menu.text = "В меню"
	to_menu.pressed.connect(func() -> void: menu_requested.emit())
	buttons.add_child(to_menu)


func _refresh() -> void:
	if _jar == null:
		return
	_counts.text = "Хлеб: %d / %d     Сахар: %d / %d" % [
		_jar.bread_pieces, _jar.ideal_bread, _jar.sugar_cubes, _jar.ideal_sugar]
	_bar.value = _jar.progress
	if _jar.is_done:
		_status.text = "Квас готов!"
	elif _jar.bread_pieces == 0 or _jar.sugar_cubes == 0:
		_status.text = "Брось в банку хлеб и сахар"
	elif _jar.progress <= 0.0:
		_status.text = "Размешивай ложкой по кругу"
	else:
		_status.text = "Бродит… %d%%" % int(_jar.progress * 100.0)


func _on_finished(title: String, _score: float) -> void:
	_result_title.text = title
	_result_info.text = "Хлеба: %d · Сахара: %d" % [_jar.bread_pieces, _jar.sugar_cubes]
	_result.visible = true
	_refresh()
