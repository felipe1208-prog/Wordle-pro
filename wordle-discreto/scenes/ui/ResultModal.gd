extends Control
class_name ResultModal

signal play_again_requested
signal main_menu_requested

# Nodos construidos por código
var overlay: ColorRect
var panel_card: PanelContainer
var title_label: Label
var secret_word_label: Label
var loot_label: Label
var level_label: Label
var progress_bar: ProgressBar
var streak_label: Label
var btn_play_again: Button
var btn_main_menu: Button

func _ready() -> void:
	visible = false
	_build_ui()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 1. Fondo semitransparente oscuro
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.75)
	add_child(overlay)

	# 2. Tarjeta central contenedora
	panel_card = PanelContainer.new()
	panel_card.custom_minimum_size = Vector2(360, 420)
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("1e1e20")
	card_style.set_corner_radius_all(10)
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.border_color = Color("3a3a3c")
	panel_card.add_theme_stylebox_override("panel", card_style)
	
	panel_card.set_anchors_preset(Control.PRESET_CENTER)
	panel_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel_card)

	# 3. Contenedor de contenido
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	panel_card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	# Título
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title_label)

	# Palabra secreta
	secret_word_label = Label.new()
	secret_word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	secret_word_label.add_theme_font_size_override("font_size", 16)
	secret_word_label.add_theme_color_override("font_color", Color("9ca3af"))
	vbox.add_child(secret_word_label)

	# Botín
	loot_label = Label.new()
	loot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loot_label.add_theme_font_size_override("font_size", 17)
	vbox.add_child(loot_label)

	# Racha
	streak_label = Label.new()
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak_label.add_theme_font_size_override("font_size", 14)
	streak_label.add_theme_color_override("font_color", Color("d1d5db"))
	vbox.add_child(streak_label)

	# Separador
	var sep = HSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color("3a3a3c")
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Nivel
	level_label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(level_label)

	# Barra de progreso
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 22)
	progress_bar.max_value = 5.0
	progress_bar.show_percentage = false

	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = Color("121213")
	pb_bg.set_corner_radius_all(6)

	var pb_fg = StyleBoxFlat.new()
	pb_fg.bg_color = Color("eab308")
	pb_fg.set_corner_radius_all(6)

	progress_bar.add_theme_stylebox_override("background", pb_bg)
	progress_bar.add_theme_stylebox_override("fill", pb_fg)
	vbox.add_child(progress_bar)

	# Espaciador
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Botones
	btn_play_again = Button.new()
	btn_play_again.text = "JUGAR DE NUEVO"
	btn_play_again.custom_minimum_size = Vector2(0, 42)
	_style_button(btn_play_again, Color("538d4e"))
	btn_play_again.pressed.connect(func(): play_again_requested.emit())
	vbox.add_child(btn_play_again)

	btn_main_menu = Button.new()
	btn_main_menu.text = "MENÚ PRINCIPAL"
	btn_main_menu.custom_minimum_size = Vector2(0, 38)
	_style_button(btn_main_menu, Color("3a3a3c"))
	btn_main_menu.pressed.connect(func(): main_menu_requested.emit())
	vbox.add_child(btn_main_menu)

func _style_button(btn: Button, bg_color: Color) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.set_corner_radius_all(6)

	var hover = StyleBoxFlat.new()
	hover.bg_color = bg_color.lightened(0.12)
	hover.set_corner_radius_all(6)

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = bg_color.darkened(0.15)
	pressed.set_corner_radius_all(6)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color.WHITE)

func show_modal(won: bool, secret: String, coins_earned: int, stars_earned: int, prev_stars: int, prev_level: int) -> void:
	visible = true
	modulate.a = 0.0
	panel_card.scale = Vector2(0.85, 0.85)

	if won:
		title_label.text = "¡VICTORIA!"
		title_label.add_theme_color_override("font_color", Color("538d4e"))
		secret_word_label.text = "Palabra: " + secret
		loot_label.text = "🪙 +" + str(coins_earned) + "  |  ⭐ +" + str(stars_earned)
	else:
		title_label.text = "FIN DEL JUEGO"
		title_label.add_theme_color_override("font_color", Color("ef4444"))
		secret_word_label.text = "La palabra era: " + secret
		loot_label.text = "🪙 +0  |  ⭐ +0"

	streak_label.text = "🔥 Racha actual: " + str(PlayerData.current_streak) + " (Máx: " + str(PlayerData.max_streak) + ")"

	var current_level = PlayerData.get_level()
	var current_stars = PlayerData.get_stars_in_current_level()

	level_label.text = "Nivel " + str(prev_level) + " (" + str(prev_stars) + "/5 ⭐)"
	progress_bar.value = float(prev_stars)

	panel_card.pivot_offset = panel_card.size / 2.0
	var appear_tween = create_tween().set_parallel(true)
	appear_tween.tween_property(self, "modulate:a", 1.0, 0.25)
	appear_tween.tween_property(panel_card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var bar_tween = create_tween()
	bar_tween.tween_interval(0.35)

	if current_level > prev_level:
		bar_tween.tween_property(progress_bar, "value", 5.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		bar_tween.tween_callback(func():
			level_label.text = "⭐ ¡SUBISTE A NIVEL " + str(current_level) + "! ⭐"
			level_label.add_theme_color_override("font_color", Color("eab308"))
			progress_bar.value = 0.0
		)
		bar_tween.tween_property(progress_bar, "value", float(current_stars), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		bar_tween.tween_callback(func():
			level_label.text = "Nivel " + str(current_level) + " (" + str(current_stars) + "/5 ⭐)"
		)
	else:
		bar_tween.tween_property(progress_bar, "value", float(current_stars), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		bar_tween.tween_callback(func():
			level_label.text = "Nivel " + str(current_level) + " (" + str(current_stars) + "/5 ⭐)"
		)

func hide_modal() -> void:
	visible = false
