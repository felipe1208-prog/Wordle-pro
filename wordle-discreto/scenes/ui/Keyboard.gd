extends Control
class_name VirtualKeyboard

signal letter_pressed(letter: String)
signal enter_pressed
signal backspace_pressed

# Paleta oficial Wordle (Modo Oscuro)
const KEY_COLOR_DEFAULT: Color = Color("818384")   # Gris neutro de tecla
const KEY_COLOR_CORRECT: Color = Color("538d4e")   # Verde oficial
const KEY_COLOR_WRONG_POS: Color = Color("b59f3b") # Amarillo ocre oficial
const KEY_COLOR_INCORRECT: Color = Color("3a3a3c") # Gris oscuro descartado

var key_buttons: Dictionary = {}
var key_statuses: Dictionary = {}

const ROWS_LAYOUT: Array = [
	["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
	["A", "S", "D", "F", "G", "H", "J", "K", "L", "Ñ"],
	["ENTER", "Z", "X", "C", "V", "B", "N", "M", "⌫"]
]

func _ready() -> void:
	if find_children("*", "Button", true).is_empty():
		_build_keyboard_layout()
	else:
		_collect_existing_buttons()

	reset_keyboard()

func _build_keyboard_layout() -> void:
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(container)

	for row in ROWS_LAYOUT:
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 6)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

		for key_text in row:
			var btn = Button.new()
			btn.text = key_text
			btn.name = "Key_" + key_text
			btn.focus_mode = Control.FOCUS_NONE
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.size_flags_vertical = Control.SIZE_EXPAND_FILL

			if key_text == "ENTER" or key_text == "⌫":
				btn.size_flags_stretch_ratio = 1.5
				btn.add_theme_font_size_override("font_size", 14)
			else:
				btn.size_flags_stretch_ratio = 1.0
				btn.add_theme_font_size_override("font_size", 20)

			_set_key_style(btn, KEY_COLOR_DEFAULT)

			if key_text == "ENTER":
				btn.pressed.connect(func(): enter_pressed.emit())
			elif key_text == "⌫":
				btn.pressed.connect(func(): backspace_pressed.emit())
			else:
				btn.pressed.connect(func(): letter_pressed.emit(key_text))

			key_buttons[key_text] = btn
			hbox.add_child(btn)

		container.add_child(hbox)

func _collect_existing_buttons() -> void:
	var buttons = find_children("*", "Button", true)
	for btn in buttons:
		var btn_text = (btn as Button).text.strip_edges().to_upper()
		key_buttons[btn_text] = btn
		if btn_text == "ENTER":
			btn.pressed.connect(func(): enter_pressed.emit())
		elif btn_text == "BACK" or btn_text == "BORRAR" or btn_text == "⌫":
			btn.pressed.connect(func(): backspace_pressed.emit())
		elif btn_text.length() == 1:
			btn.pressed.connect(func(): letter_pressed.emit(btn_text))

func update_key_status(letter: String, status: String) -> void:
	var key = letter.to_upper()
	if not key_buttons.has(key):
		return

	# Prioridad de colores oficial: Verde > Amarillo > Gris
	var current_status = key_statuses.get(key, "")
	if current_status == "correct":
		return
	if current_status == "wrong_position" and status != "correct":
		return

	key_statuses[key] = status
	var btn: Button = key_buttons[key]
	match status:
		"correct":
			_set_key_style(btn, KEY_COLOR_CORRECT)
		"wrong_position":
			_set_key_style(btn, KEY_COLOR_WRONG_POS)
		"incorrect":
			_set_key_style(btn, KEY_COLOR_INCORRECT)

func reset_keyboard() -> void:
	key_statuses.clear()
	for key in key_buttons.keys():
		var btn: Button = key_buttons[key]
		_set_key_style(btn, KEY_COLOR_DEFAULT)

func _set_key_style(btn: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = color.lightened(0.12)
	hover_style.set_corner_radius_all(5)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = color.darkened(0.15)
	pressed_style.set_corner_radius_all(5)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
