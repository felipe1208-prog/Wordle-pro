extends Node

signal economy_updated(new_coins: int, new_stars: int)
signal stats_updated

const SAVE_PATH: String = "user://save_data.json"

# Variables de economía
var coins: int = 0
var stars: int = 0

# Variables de estadísticas
var games_played: int = 0
var games_won: int = 0
var current_streak: int = 0
var max_streak: int = 0

func _ready() -> void:
	# Cargar datos guardados automáticamente al iniciar el juego
	load_data()

func add_reward_for_win(attempts_used: int) -> void:
	var coins_earned = 0
	var stars_earned = 0
	
	match attempts_used:
		1:
			coins_earned = 100
			stars_earned = 5
		2:
			coins_earned = 80
			stars_earned = 4
		3:
			coins_earned = 60
			stars_earned = 3
		4:
			coins_earned = 40
			stars_earned = 2
		5:
			coins_earned = 20
			stars_earned = 1
		6:
			coins_earned = 10
			stars_earned = 1

	coins += coins_earned
	stars += stars_earned
	
	games_played += 1
	games_won += 1
	current_streak += 1
	if current_streak > max_streak:
		max_streak = current_streak

	print("--- VICTORIA REGISTRADA ---")
	print("Monedas totales: ", coins, " | Estrellas: ", stars)
	print("Jugadas: ", games_played, " | Ganadas: ", games_won, " | Racha actual: ", current_streak, " | Racha Máx: ", max_streak)

	economy_updated.emit(coins, stars)
	stats_updated.emit()
	
	# Guardar en disco tras ganar
	save_data()

func register_loss() -> void:
	games_played += 1
	current_streak = 0

	print("--- DERROTA REGISTRADA ---")
	print("Jugadas: ", games_played, " | Ganadas: ", games_won, " | Racha cortada a 0")

	stats_updated.emit()
	
	# Guardar en disco tras perder
	save_data()

func save_data() -> void:
	var data_to_save: Dictionary = {
		"coins": coins,
		"stars": stars,
		"games_played": games_played,
		"games_won": games_won,
		"current_streak": current_streak,
		"max_streak": max_streak
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data_to_save, "\t")
		file.store_string(json_string)
		file.close()
		print("Datos guardados exitosamente en: ", SAVE_PATH)
	else:
		print("Error al intentar guardar datos en el archivo.")

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No se encontró archivo previo de guardado. Se inicia partida nueva.")
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
			
			print("--- DATOS CARGADOS DESDE DISCO ---")
			print("Monedas: ", coins, " | Estrellas: ", stars)
			print("Jugadas: ", games_played, " | Ganadas: ", games_won, " | Racha Máx: ", max_streak)
			
			economy_updated.emit(coins, stars)
			stats_updated.emit()
		else:
			print("El archivo de guardado no tiene formato válido.")

func reset_progress() -> void:
	coins = 0
	stars = 0
	games_played = 0
	games_won = 0
	current_streak = 0
	max_streak = 0
	save_data()
	economy_updated.emit(coins, stars)
	stats_updated.emit()
