extends Control
class_name LetterBox

# Referencias a los nodos hijos
@onready var background: ColorRect = $ColorRect
@onready var label: Label = $Label

# Colores estándar del juego
const COLOR_EMPTY = Color("23272f")      # Casilla vacía
const COLOR_FILLED = Color("374151")     # Letra escrita pero no enviada
const COLOR_GRAY = Color("4b5563")       # Letra incorrecta
const COLOR_YELLOW = Color("d97706")     # En posición equivocada
const COLOR_GREEN = Color("15803d")      # Correcta

func _ready() -> void:
	clear()

func set_letter(letter: String) -> void:
	label.text = letter.to_upper()
	if letter == "":
		background.color = COLOR_EMPTY
	else:
		background.color = COLOR_FILLED

func clear() -> void:
	label.text = ""
	background.color = COLOR_EMPTY

# Cambia el estado visual tras evaluar el intento
func set_state(state: String) -> void:
	match state:
		"correct":
			background.color = COLOR_GREEN
		"wrong_position":
			background.color = COLOR_YELLOW
		"incorrect":
			background.color = COLOR_GRAY
		_:
			background.color = COLOR_EMPTY
