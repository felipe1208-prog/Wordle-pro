extends VBoxContainer
class_name VirtualKeyboard

signal letter_pressed(letter: String)
signal enter_pressed()
signal backspace_pressed()

var key_buttons: Dictionary = {}

# Distribución clásica QWERTY en español
const ROW_1 = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
const ROW_2 = ["A", "S", "D", "F", "G", "H", "J", "K", "L", "Ñ"]
const ROW_3 = ["ENTER", "Z", "X", "C", "V", "B", "N", "M", "⌫"]

# Colores para las teclas
const COLOR_DEFAULT = Color("4b5563")  # Gris neutro
const COLOR_ABSENT  = Color("1f2937")  # Gris oscuro (descartada)
const COLOR_PRESENT = Color("d97706")  # Amarillo (posición incorrecta)
const COLOR_CORRECT = Color("15803d")  # Verde (acierto exacto)

func _ready() -> void:
	build_keyboard()

func build_keyboard() -> void:
	# Limpiar hijos previos si los hubiera
	for child in get_children():
		child.queue_free()
	key_buttons.clear()

	create_row(ROW_1)
	create_row(ROW_2)
	create_row(ROW_3)

func create_row(keys: Array) -> void:
	var h_box = HBoxContainer.new()
	h_box.alignment = BoxContainer.ALIGNMENT_CENTER
	h_box.add_theme_constant_override("separation", 6)
	add_child(h_box)

	for key in keys:
		var btn = Button.new()
		btn.text = key
		btn.focus_mode = Control.FOCUS_NONE # Evita bordes molestos al hacer clic
		
		# Tamaño de tecla
		if key == "ENTER" or key == "⌫":
			btn.custom_minimum_size = Vector2(85, 65)
			btn.add_theme_font_size_override("font_size", 18)
		else:
			btn.custom_minimum_size = Vector2(58, 65)
			btn.add_theme_font_size_override("font_size", 24)

		# Color inicial neutro
		set_button_color(btn, COLOR_DEFAULT)

		# Conectar clic
		btn.pressed.connect(_on_key_pressed.bind(key))
		h_box.add_child(btn)

		if key != "ENTER" and key != "⌫":
			key_buttons[key] = btn

func _on_key_pressed(key: String) -> void:
	if key == "ENTER":
		enter_pressed.emit()
	elif key == "⌫":
		backspace_pressed.emit()
	else:
		letter_pressed.emit(key)

# Actualiza el color de la tecla respetando la jerarquía de Wordle (Verde > Amarillo > Gris)
func update_key_status(letter: String, status: String) -> void:
	letter = letter.to_upper()
	if not key_buttons.has(letter):
		return

	var btn: Button = key_buttons[letter]
	var current_state = btn.get_meta("status", "none")

	# Si ya estaba en verde, nunca baja de nivel
	if current_state == "correct":
		return
	# Si ya estaba en amarillo, solo sube a verde
	if current_state == "wrong_position" and status != "correct":
		return

	btn.set_meta("status", status)

	match status:
		"correct":
			set_button_color(btn, COLOR_CORRECT)
		"wrong_position":
			set_button_color(btn, COLOR_PRESENT)
		"incorrect":
			set_button_color(btn, COLOR_ABSENT)

func set_button_color(btn: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

# Limpia los colores de todas las teclas para reiniciar partida
func reset_keyboard() -> void:
	for letter in key_buttons:
		var btn: Button = key_buttons[letter]
		btn.set_meta("status", "none")
		set_button_color(btn, COLOR_DEFAULT)
