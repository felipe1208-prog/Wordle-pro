extends Control

@onready var board: Board = $Board

var word_list: Array = []
var secret_word: String = ""
var current_guess: String = ""
var current_row: int = 0
var max_attempts: int = 6
var game_over: bool = false

func _ready() -> void:
	load_words()
	start_new_game()

# Carga la lista de palabras desde el archivo JSON
func load_words() -> void:
	var path = "res://data/palabras.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(json_text)
		if parsed is Array:
			word_list = parsed
	
	# Respaldo por si el JSON estuviera vacío o no existiera
	if word_list.is_empty():
		word_list = ["GRAFO", "ARBOL", "NODOS", "CICLO", "ORDEN"]

# Inicializa una partida
func start_new_game() -> void:
	board.reset_board()
	current_row = 0
	current_guess = ""
	game_over = false
	
	# Elegir palabra secreta al azar
	randomize()
	secret_word = word_list.pick_random().to_upper()
	print("Palabra secreta seleccionada: ", secret_word)

# Captura de teclas físicas (PC)
func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		return

	if event is InputEventKey and event.is_pressed():
		var keycode = event.keycode
		
		# Letras de la A a la Z
		if keycode >= KEY_A and keycode <= KEY_Z:
			var letter = OS.get_keycode_string(keycode).to_upper()
			add_letter(letter)
		# Borrar
		elif keycode == KEY_BACKSPACE:
			delete_letter()
		# Enviar intento
		elif keycode == KEY_ENTER:
			submit_guess()

func add_letter(letter: String) -> void:
	if current_guess.length() < 5:
		current_guess += letter
		board.update_row_text(current_row, current_guess)

func delete_letter() -> void:
	if current_guess.length() > 0:
		current_guess = current_guess.substr(0, current_guess.length() - 1)
		board.update_row_text(current_row, current_guess)

func submit_guess() -> void:
	if current_guess.length() < 5:
		print("La palabra debe tener 5 letras")
		return

	# Evaluar aciertos
	var result = evaluate_guess(current_guess, secret_word)
	board.set_row_result(current_row, result)

	# Verificar victoria
	if current_guess == secret_word:
		print("¡Ganaste!")
		game_over = true
		return

	current_row += 1
	current_guess = ""

	# Verificar derrota
	if current_row >= max_attempts:
		print("Fin de los intentos. La palabra era: ", secret_word)
		game_over = true

# Algoritmo estricto de Wordle (maneja letras duplicadas correctamente)
func evaluate_guess(guess: String, target: String) -> Array:
	var results = ["incorrect", "incorrect", "incorrect", "incorrect", "incorrect"]
	var target_pool = {}

	# Contar frecuencia de cada letra en la palabra secreta
	for char in target:
		target_pool[char] = target_pool.get(char, 0) + 1

	# Paso 1: Marcar aciertos exactos (VERDE)
	for i in range(5):
		if guess[i] == target[i]:
			results[i] = "correct"
			target_pool[guess[i]] -= 1

	# Paso 2: Marcar aciertos desordenados (AMARILLO)
	for i in range(5):
		if results[i] != "correct":
			var char = guess[i]
			if target_pool.get(char, 0) > 0:
				results[i] = "wrong_position"
				target_pool[char] -= 1

	return results
