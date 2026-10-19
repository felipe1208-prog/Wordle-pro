extends Node

signal economy_updated(new_coins: int, new_stars: int)
signal level_up(new_level: int)
signal stats_updated
signal theme_updated(theme_id: String)

const SAVE_PATH: String = "user://save_data.json"
const STARS_PER_LEVEL: int = 5

# Costos de los Comodines / Pistas
const HINT_REVEAL_LETTER_COST: int = 50
const HINT_REMOVE_KEYS_COST: int = 30

# Variables de economía y progresión
var coins: int = 0
var stars: int = 0 # Estrellas totales acumuladas (experiencia)

# Variables de estadísticas
var games_played: int = 0
var games_won: int = 0
var current_streak: int = 0
var max_streak: int = 0

# Variables de cosméticos y temas
var unlocked_themes: Array = ["classic"]
var current_theme: String = "classic"

# Catálogo de temas con requisitos de nivel y monedas
const THEMES_CATALOG: Dictionary = {
	"classic": {
		"name": "Clásico Wordle",
		"required_level": 1,
		"cost_coins": 0,
		"bg_color": "#121213",
		"tile_empty": "#3a3a3c",
		"tile_correct": "#538d4e",
		"tile_wrong_pos": "#b59f3b"
	},
	"midnight_blue": {
		"name": "Azul Medianoche",
		"required_level": 2,
		"cost_coins": 150,
		"bg_color": "#0f172a",
		"tile_empty": "#1e293b",
		"tile_correct": "#2563eb",
		"tile_wrong_pos": "#b59f3b"
	},
	"emerald_forest": {
		"name": "Bosque Esmeralda",
		"required_level": 3,
		"cost_coins": 250,
		"bg_color": "#064e3b",
		"tile_empty": "#065f46",
		"tile_correct": "#10b981",
		"tile_wrong_pos": "#b59f3b"
	}
}

func _ready() -> void:
	load_data()

# --- CÁLCULO DE NIVELES ---
func get_level() -> int:
	return int(stars / STARS_PER_LEVEL) + 1

func get_stars_in_current_level() -> int:
	return stars % STARS_PER_LEVEL

func get_stars_needed_for_next_level() -> int:
	return STARS_PER_LEVEL

# --- RECOMPENSAS ---
func add_reward_for_win(attempts_used: int) -> void:
	var prev_level = get_level()
	var coins_earned = 0
	var stars_earned = 0

	match attempts_used:
		1: coins_earned = 100
		2: coins_earned = 80
		3: coins_earned = 60
		4: coins_earned = 40
		5: coins_earned = 20
		6: coins_earned = 10

	if attempts_used <= 2:
		stars_earned = 2
	else:
		stars_earned = 1

	coins += coins_earned
	stars += stars_earned
	
	games_played += 1
	games_won += 1
	current_streak += 1
	if current_streak > max_streak:
		max_streak = current_streak

	var new_level = get_level()

	print("--- VICTORIA REGISTRADA ---")
	print("Monedas ganadas: +", coins_earned, " (Total: ", coins, ")")
	print("Estrellas ganadas: +", stars_earned, " (Total acumulado: ", stars, ")")
	print("Nivel actual: ", new_level, " (Progreso: ", get_stars_in_current_level(), "/", STARS_PER_LEVEL, ")")
	print("Racha actual: ", current_streak, " | Racha Máxima: ", max_streak)

	economy_updated.emit(coins, stars)
	stats_updated.emit()

	if new_level > prev_level:
		print("⭐ ¡SUBISTE DE NIVEL! Ahora eres Nivel ", new_level, " ⭐")
		level_up.emit(new_level)

	save_data()

func register_loss() -> void:
	games_played += 1
	current_streak = 0

	print("--- DERROTA REGISTRADA ---")
	print("Partidas jugadas: ", games_played, " | Racha cortada a 0")

	stats_updated.emit()
	save_data()

# --- COMODINES / PISTAS ---
func use_hint_reveal_letter() -> bool:
	if coins >= HINT_REVEAL_LETTER_COST:
		coins -= HINT_REVEAL_LETTER_COST
		print("Comodín utilizado: Revelar Letra (-", HINT_REVEAL_LETTER_COST, " monedas)")
		economy_updated.emit(coins, stars)
		save_data()
		return true
	print("Monedas insuficientes para revelar letra. Requiere: ", HINT_REVEAL_LETTER_COST)
	return false

func use_hint_remove_keys() -> bool:
	if coins >= HINT_REMOVE_KEYS_COST:
		coins -= HINT_REMOVE_KEYS_COST
		print("Comodín utilizado: Eliminar Teclas Erróneas (-", HINT_REMOVE_KEYS_COST, " monedas)")
		economy_updated.emit(coins, stars)
		save_data()
		return true
	print("Monedas insuficientes para eliminar teclas. Requiere: ", HINT_REMOVE_KEYS_COST)
	return false

# --- TIENDA Y PERSONALIZACIÓN ---
func buy_theme(theme_id: String) -> bool:
	if not THEMES_CATALOG.has(theme_id):
		return false
	
	if unlocked_themes.has(theme_id):
		equip_theme(theme_id)
		return true

	var item = THEMES_CATALOG[theme_id]
	var req_level: int = item["required_level"]
	var req_coins: int = item["cost_coins"]

	if get_level() < req_level:
		print("Nivel insuficiente. Requiere nivel: ", req_level)
		return false

	if coins < req_coins:
		print("Monedas insuficientes. Requiere: ", req_coins)
		return false

	coins -= req_coins
	unlocked_themes.append(theme_id)
	current_theme = theme_id

	print("Tema comprado y equipado: ", item["name"])
	economy_updated.emit(coins, stars)
	theme_updated.emit(current_theme)
	save_data()
	return true

func equip_theme(theme_id: String) -> bool:
	if not THEMES_CATALOG.has(theme_id):
		return false

	if unlocked_themes.has(theme_id):
		current_theme = theme_id
		print("Tema equipado: ", THEMES_CATALOG[theme_id]["name"])
		theme_updated.emit(current_theme)
		save_data()
		return true

	return false

# --- GUARDADO Y PERSISTENCIA ---
func save_data() -> void:
	var data_to_save: Dictionary = {
		"coins": coins,
		"stars": stars,
		"games_played": games_played,
		"games_won": games_won,
		"current_streak": current_streak,
		"max_streak": max_streak,
		"unlocked_themes": unlocked_themes,
		"current_theme": current_theme
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data_to_save, "\t")
		file.store_string(json_string)
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var parsed = JSON.parse_string(content)
		if parsed is Dictionary:
			coins = parsed.get("coins", 0)
			stars = parsed.get("stars", 0)
			games_played = parsed.get("games_played", 0)
			games_won = parsed.get("games_won", 0)
			current_streak = parsed.get("current_streak", 0)
			max_streak = parsed.get("max_streak", 0)
			unlocked_themes = parsed.get("unlocked_themes", ["classic"])
			current_theme = parsed.get("current_theme", "classic")
			
			print("--- PROGRESO CARGADO ---")
			print("Nivel: ", get_level(), " | Estrellas: ", stars, " | Monedas: ", coins)
			economy_updated.emit(coins, stars)
			stats_updated.emit()
			theme_updated.emit(current_theme)
