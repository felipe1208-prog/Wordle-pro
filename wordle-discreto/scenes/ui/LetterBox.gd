extends Control
class_name LetterBox

# Paleta oficial Wordle (Modo Oscuro)
const COLOR_EMPTY: Color = Color("3a3a3c")       # Gris oficial de casilla vacía/borde
const COLOR_CORRECT: Color = Color("538d4e")     # Verde oficial de acierto
const COLOR_WRONG_POS: Color = Color("b59f3b")   # Amarillo ocre oficial
const COLOR_INCORRECT: Color = Color("272729")   # Gris oscuro descartado
const COLOR_TEXT: Color = Color("ffffff")

@onready var label: Label = _find_label()

func _ready() -> void:
	reset()

func _find_label() -> Label:
	if has_node("Label"):
		return $Label as Label
	var labels = find_children("*", "Label", true)
	if labels.size() > 0:
		return labels[0] as Label
	return null

func set_letter(new_char: String) -> void:
	var prev_text = label.text if label else ""
	var upper_char = new_char.to_upper()
	if label:
		label.text = upper_char
		label.add_theme_color_override("font_color", COLOR_TEXT)
	
	# Efecto Pop solo al escribir una letra nueva
	if prev_text == "" and upper_char != "":
		animate_pop()

func set_text(new_char: String) -> void:
	set_letter(new_char)

func animate_pop() -> void:
	pivot_offset = size / 2.0
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func animate_flip(status: String, delay: float = 0.0) -> Tween:
	pivot_offset = size / 2.0
	var tween = create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)

	# Primera mitad: comprimir altura hasta ocultarse
	tween.tween_property(self, "scale:y", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Cambio de color en el punto ciego
	tween.tween_callback(func(): set_result(status))
	# Segunda mitad: expandir de regreso a la altura normal
	tween.tween_property(self, "scale:y", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween

func set_result(status: String) -> void:
	match status:
		"correct":
			_apply_background_color(COLOR_CORRECT)
		"wrong_position":
			_apply_background_color(COLOR_WRONG_POS)
		"incorrect":
			_apply_background_color(COLOR_INCORRECT)
		_:
			_apply_background_color(COLOR_EMPTY)

func set_state(status: String) -> void:
	set_result(status)

func set_status(status: String) -> void:
	set_result(status)

func reset() -> void:
	scale = Vector2(1.0, 1.0)
	if label:
		label.text = ""
	_apply_background_color(COLOR_EMPTY)

func clear() -> void:
	reset()

func _apply_background_color(color: Color) -> void:
	if has_node("ColorRect"):
		($ColorRect as ColorRect).color = color
	elif has_node("Panel"):
		var panel = $Panel as Panel
		var style = StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("panel", style)
	else:
		modulate = color
