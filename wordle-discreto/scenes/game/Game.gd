extends Control

@onready var board: Board = $Board
@onready var message_label: Label = $MessageLabel
@onready var keyboard: VirtualKeyboard = $Keyboard

var secret_words: Array = []
var valid_dictionary: Dictionary = {}

var secret_word: String = ""
var current_guess: String = ""
var current_row: int = 0
var max_attempts: int = 6
var game_over: bool = false

func _ready() -> void:
	load_all_words()
	setup_keyboard()
	start_new_game()

func setup_keyboard() -> void:
	if keyboard:
		keyboard.letter_pressed.connect(add_letter)
		keyboard.enter_pressed.connect(submit_guess)
		keyboard.backspace_pressed.connect(delete_letter)

func load_all_words() -> void:
	secret_words = load_json_array("res://data/palabras_secretas.json")
	if secret_words.is_empty():
		secret_words = load_json_array("res://data/palabras.json")
	if secret_words.is_empty():
		secret_words = ["GRAFO", "ARBOL", "NODOS", "CICLO", "ORDEN"]

	var dict_array = load_json_array("res://data/diccionario.json")
	if dict_array.is_empty():
		dict_array = secret_words.duplicate()

	valid_dictionary.clear()
	for word in dict_array:
		valid_dictionary[word.to_upper()] = true
	for word in secret_words:
		valid_dictionary[word.to_upper()] = true

func load_json_array(path: String) -> Array:
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(json_text)
		if parsed is Array:
			return parsed
	return []

func start_new_game() -> void:
	board.reset_board()
	if keyboard:
		keyboard.reset_keyboard()
	current_row = 0
	current_guess = ""
	game_over = false
	show_message("")
	
	randomize()
	secret_word = secret_words.pick_random().to_upper()
	print("--- NUEVA PARTIDA ---")
	print("Palabra secreta: ", secret_word)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var keycode = event.keycode
		
		if game_over:
			if keycode == KEY_R:
				start_new_game()
			return

		if keycode >= KEY_A and keycode <= KEY_Z:
			var letter = OS.get_keycode_string(keycode).to_upper()
			add_letter(letter)
		elif keycode == KEY_BACKSPACE:
			delete_letter()
		elif keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
			submit_guess()

func add_letter(letter: String) -> void:
	if game_over:
		return
	if current_guess.length() < 5:
		current_guess += letter
		board.update_row_text(current_row, current_guess)
		show_message("")

func delete_letter() -> void:
	if game_over:
		return
	if current_guess.length() > 0:
		current_guess = current_guess.substr(0, current_guess.length() - 1)
		board.update_row_text(current_row, current_guess)
		show_message("")

func submit_guess() -> void:
	if game_over:
		return

	if current_guess.length() < 5:
		show_message("Faltan letras")
		return

	if not valid_dictionary.has(current_guess):
		show_message("Palabra no válida")
		return

	var result = evaluate_guess(current_guess, secret_word)
	board.set_row_result(current_row, result)

	# Actualizar los colores de las teclas del teclado virtual
	if keyboard:
		for i in range(5):
			keyboard.update_key_status(current_guess[i], result[i])

	if current_guess == secret_word:
		show_message("¡Ganaste! Presiona 'R' para jugar de nuevo")
		game_over = true
		return

	current_row += 1
	current_guess = ""

	if current_row >= max_attempts:
		show_message("Era: " + secret_word + " | Presiona 'R' para reiniciar")
		game_over = true

func show_message(text: String) -> void:
	if message_label:
		message_label.text = text

func evaluate_guess(guess: String, target: String) -> Array:
	var results = ["incorrect", "incorrect", "incorrect", "incorrect", "incorrect"]
	var target_pool = {}

	for char in target:
		target_pool[char] = target_pool.get(char, 0) + 1

	for i in range(5):
		if guess[i] == target[i]:
			results[i] = "correct"
			target_pool[guess[i]] -= 1

	for i in range(5):
		if results[i] != "correct":
			var char = guess[i]
			if target_pool.get(char, 0) > 0:
				results[i] = "wrong_position"
				target_pool[char] -= 1

	return results
