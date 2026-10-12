extends Node

# Variables globales persistentes
var coins: int = 0
var stars: int = 0
var games_won: int = 0

signal economy_updated(new_coins: int, new_stars: int)

func add_reward_for_win(attempts_used: int) -> void:
	# A menor cantidad de intentos usados, mayor recompensa de monedas y estrellas
	var coins_earned = 50 + ((6 - attempts_used) * 10) # Ej: Ganar en el intento 1 da 100 monedas
	var stars_earned = max(1, 4 - (attempts_used / 2)) # De 1 a 3 estrellas
	
	coins += coins_earned
	stars += stars_earned
	games_won += 1
	
	economy_updated.emit(coins, stars)
	print("Recompensa otorgada: +", coins_earned, " monedas | +", stars_earned, " estrellas.")
	print("Total actual: Monedas = ", coins, " | Estrellas = ", stars)

func reset_progress() -> void:
	coins = 0
	stars = 0
	games_won = 0
	economy_updated.emit(coins, stars)
