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

# Animación escalonada de volteo letra por letra
func animate_reveal(states: Array, on_letter_revealed: Callable = Callable()) -> void:
	var last_tween: Tween = null
	var step_delay: float = 0.2

	for i in range(mini(boxes.size(), states.size())):
		var delay = i * step_delay
		var tween = boxes[i].animate_flip(states[i], delay)
		last_tween = tween

		if on_letter_revealed.is_valid():
			var box_idx = i
			var status = states[i]
			# Llamar al callback cuando la tarjeta llega al centro del giro
			get_tree().create_timer(delay + 0.15).timeout.connect(func():
				on_letter_revealed.call(box_idx, status)
			)

	if last_tween:
		await last_tween.finished
	else:
		await get_tree().process_frame

# Limpia todas las casillas de la fila
func clear() -> void:
	for box in boxes:
		box.clear()
