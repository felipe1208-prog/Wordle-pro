extends Control

@onready var board: Board = $Board
@onready var message_label: Label = $MessageLabel
@onready var keyboard: VirtualKeyboard = $Keyboard

# Referencias a los botones de comodines
@onready var reveal_letter_button: Button = $HintsContainer/RevealLetterButton if has_node("HintsContainer/RevealLetterButton") else null
@onready var remove_keys_button: Button = $HintsContainer/RemoveKeysButton if has_node("HintsContainer/RemoveKeysButton") else null

var result_modal: ResultModal = null
var secret_words: Array = []
var valid_dictionary: Dictionary = {}

var secret_word: String = ""
var current_guess: String = ""
var current_row: int = 0
var max_attempts: int = 6
var game_over: bool = false
var is_animating: bool = false

# Elementos del Modo Tensión
var tension_overlay: ColorRect = null
var tension_tween: Tween = null
var is_tension_active: bool = false
var board_initial_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_process(false)
	if board:
		board_initial_position = board.position
	_setup_tension_overlay()
	_init_result_modal()
	
	# Conectar señales globales
	if PlayerData.has_signal("theme_updated"):
		PlayerData.theme_updated.connect(_on_theme_updated)
	if PlayerData.has_signal("economy_updated"):
		PlayerData.economy_updated.connect(_on_economy_updated)
	_apply_current_theme()

	# Conectar botones de comodines
	_setup_hint_buttons()

	load_all_words()
	setup_keyboard()
	start_new_game()

func _init_result_modal() -> void:
	if has_node("ResultModal"):
		result_modal = $ResultModal as ResultModal
	else:
		var modal_scene = load("res://scenes/ui/ResultModal.tscn")
		if modal_scene:
			result_modal = modal_scene.instantiate() as ResultModal
			add_child(result_modal)

	if result_modal:
		result_modal.z_index = 100
		result_modal.play_again_requested.connect(_on_play_again)
		result_modal.main_menu_requested.connect(_on_main_menu)

func _setup_hint_buttons() -> void:
	if reveal_letter_button == null or remove_keys_button == null:
		var buttons = find_children("*", "Button", true)
		for btn in buttons:
			if "Reveal" in btn.name or "revelar" in btn.text.to_lower():
				reveal_letter_button = btn
			elif "Remove" in btn.name or "descartar" in btn.text.to_lower():
				remove_keys_button = btn

	if reveal_letter_button and not reveal_letter_button.pressed.is_connected(_on_reveal_letter_pressed):
		reveal_letter_button.pressed.connect(_on_reveal_letter_pressed)
	if remove_keys_button and not remove_keys_button.pressed.is_connected(_on_remove_keys_pressed):
		remove_keys_button.pressed.connect(_on_remove_keys_pressed)

	_update_hint_buttons_state()

func _update_hint_buttons_state() -> void:
	var current_coins = PlayerData.coins
	if reveal_letter_button:
		reveal_letter_button.disabled = game_over or is_animating or (current_coins < PlayerData.HINT_REVEAL_LETTER_COST)
	if remove_keys_button:
		remove_keys_button.disabled = game_over or is_animating or (current_coins < PlayerData.HINT_REMOVE_KEYS_COST)

func _on_economy_updated(_new_coins: int, _new_stars: int) -> void:
	_update_hint_buttons_state()

# --- LÓGICA DE COMODÍN 1: REVELAR LETRA ---
func _on_reveal_letter_pressed() -> void:
	if game_over or is_animating:
		return

	var unrevealed_indices: Array = []
	for i in range(5):
		var current_char = current_guess[i] if i < current_guess.length() else ""
		if current_char != secret_word[i]:
			unrevealed_indices.append(i)

	if unrevealed_indices.is_empty():
		show_message("Ya tienes todas las letras correctas en fila")
		return

	if PlayerData.use_hint_reveal_letter():
		unrevealed_indices.shuffle()
		var target_idx: int = unrevealed_indices[0]
		var revealed_char: String = secret_word[target_idx]

		var new_guess_arr: Array = []
		for i in range(5):
			if i == target_idx:
				new_guess_arr.append(revealed_char)
			elif i < current_guess.length():
				new_guess_arr.append(current_guess[i])
			else:
				new_guess_arr.append(" ")

		current_guess = "".join(new_guess_arr).strip_edges()
		board.update_row_text(current_row, current_guess)
		show_message("💡 Letra revelada: '" + revealed_char + "'")
		_update_hint_buttons_state()

# --- LÓGICA DE COMODÍN 2: ELIMINAR TECLAS ERRÓNEAS (SOLUCIÓN DIRECTA E INMEDIATA) ---
func _on_remove_keys_pressed() -> void:
	if game_over or is_animating or keyboard == null:
		return

	# Lista de letras candidatas que NO forman parte de la palabra secreta
	var alphabet: String = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ"
	var discard_candidates: Array = []

	for i in range(alphabet.length()):
		var letter = alphabet[i]
		if not secret_word.contains(letter):
			discard_candidates.append(letter)

	if discard_candidates.is_empty():
		show_message("No hay más letras erróneas por descartar")
		return

	if PlayerData.use_hint_remove_keys():
		discard_candidates.shuffle()
		var char_to_discard: String = discard_candidates[0]
		
		# Forzamos directamente la actualización del estado de la tecla en el teclado virtual
		keyboard.update_key_status(char_to_discard, "incorrect")
		show_message("❌ Tecla descartada: '" + char_to_discard + "'")
		_update_hint_buttons_state()

func _process(_delta: float) -> void:
	if is_tension_active and board:
		board.position = board_initial_position + Vector2(
			randf_range(-2.0, 2.0),
			randf_range(-1.5, 1.5)
		)

func _setup_tension_overlay() -> void:
	tension_overlay = ColorRect.new()
	tension_overlay.name = "TensionOverlay"
	tension_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	tension_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tension_overlay.color = Color(0.85, 0.1, 0.1, 0.0)
	add_child(tension_overlay)
	move_child(tension_overlay, 1)

func _on_theme_updated(_theme_id: String) -> void:
	_apply_current_theme()

func _apply_current_theme() -> void:
	var theme_data = PlayerData.THEMES_CATALOG.get(PlayerData.current_theme, PlayerData.THEMES_CATALOG["classic"])
	for child in get_children():
		if child is ColorRect and child.name != "TensionOverlay":
			child.color = Color(theme_data["bg_color"])
			break

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
	if result_modal:
		result_modal.hide_modal()
	_stop_tension_mode()
	board.reset_board()
	if keyboard:
		keyboard.reset_keyboard()
	current_row = 0
	current_guess = ""
	game_over = false
	is_animating = false
	show_message("")
	_update_hint_buttons_state()
	
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

		if is_animating:
			return

		if keycode >= KEY_A and keycode <= KEY_Z:
			var letter = OS.get_keycode_string(keycode).to_upper()
			add_letter(letter)
		elif keycode == KEY_BACKSPACE:
			delete_letter()
		elif keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
			submit_guess()

func add_letter(letter: String) -> void:
	if game_over or is_animating:
		return
	if current_guess.length() < 5:
		current_guess += letter
		board.update_row_text(current_row, current_guess)
		if not is_tension_active:
			show_message("")

func delete_letter() -> void:
	if game_over or is_animating:
		return
	if current_guess.length() > 0:
		current_guess = current_guess.substr(0, current_guess.length() - 1)
		board.update_row_text(current_row, current_guess)
		if not is_tension_active:
			show_message("")

func submit_guess() -> void:
	if game_over or is_animating:
		return

	if current_guess.length() < 5:
		show_message("Faltan letras")
		return

	if not valid_dictionary.has(current_guess):
		show_message("Palabra no válida")
		return

	is_animating = true
	_update_hint_buttons_state()
	var guess_snapshot = current_guess
	var row_snapshot = current_row
	var result = evaluate_guess(guess_snapshot, secret_word)

	await board.animate_row_reveal(row_snapshot, result, func(index: int, status: String):
		if keyboard:
			keyboard.update_key_status(guess_snapshot[index], status)
	)

	is_animating = false

	if guess_snapshot == secret_word:
		_stop_tension_mode()
		game_over = true
		_update_hint_buttons_state()
		var prev_stars = PlayerData.get_stars_in_current_level()
		var prev_level = PlayerData.get_level()

		var coins_earned = 0
		var stars_earned = 2 if (row_snapshot + 1) <= 2 else 1
		match (row_snapshot + 1):
			1: coins_earned = 100
			2: coins_earned = 80
			3: coins_earned = 60
			4: coins_earned = 40
			5: coins_earned = 20
			6: coins_earned = 10

		PlayerData.add_reward_for_win(row_snapshot + 1)

		if result_modal:
			result_modal.show_modal(true, secret_word, coins_earned, stars_earned, prev_stars, prev_level)
		return

	current_row += 1
	current_guess = ""
	_update_hint_buttons_state()

	if current_row == max_attempts - 1 and not game_over:
		_trigger_tension_mode()
	elif current_row >= max_attempts:
		_stop_tension_mode()
		game_over = true
		_update_hint_buttons_state()
		var prev_stars = PlayerData.get_stars_in_current_level()
		var prev_level = PlayerData.get_level()
		PlayerData.register_loss()

		if result_modal:
			result_modal.show_modal(false, secret_word, 0, 0, prev_stars, prev_level)

func _trigger_tension_mode() -> void:
	is_tension_active = true
	set_process(true)
	show_message("⚠️ ¡ÚLTIMO INTENTO! ⚠️")

	if tension_overlay:
		if tension_tween and tension_tween.is_valid():
			tension_tween.kill()
		tension_tween = create_tween().set_loops()
		tension_tween.tween_property(tension_overlay, "color:a", 0.16, 0.6).set_trans(Tween.TRANS_SINE)
		tension_tween.tween_property(tension_overlay, "color:a", 0.03, 0.6).set_trans(Tween.TRANS_SINE)

func _stop_tension_mode() -> void:
	is_tension_active = false
	set_process(false)
	if tension_tween and tension_tween.is_valid():
		tension_tween.kill()
	if tension_overlay:
		var fade_out = create_tween()
		fade_out.tween_property(tension_overlay, "color:a", 0.0, 0.25)
	if board:
		board.position = board_initial_position

func _on_play_again() -> void:
	start_new_game()

func _on_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func show_message(text: String) -> void:
	if message_label:
		message_label.text = text
		if is_tension_active and text.contains("ÚLTIMO"):
			message_label.add_theme_color_override("font_color", Color("ef4444"))
		else:
			message_label.add_theme_color_override("font_color", Color("ffffff"))

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
