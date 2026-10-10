extends HBoxContainer
class_name Row

var boxes: Array[LetterBox] = []

func _ready() -> void:
	boxes.clear()
	for child in get_children():
		if child is LetterBox:
			boxes.append(child)

# Coloca las letras escritas hasta el momento (ej: "CAS")
func set_text(word: String) -> void:
	for i in range(boxes.size()):
		if i < word.length():
			boxes[i].set_letter(word[i])
		else:
			boxes[i].clear()

# Recibe un arreglo con los estados: ["correct", "wrong_position", "incorrect", ...]
func set_states(states: Array) -> void:
	for i in range(mini(boxes.size(), states.size())):
		boxes[i].set_state(states[i])

# Limpia todas las casillas de la fila
func clear() -> void:
	for box in boxes:
		box.clear()
