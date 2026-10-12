extends HBoxContainer
class_name EconomyUI

@onready var coins_label: Label = $CoinsLabel
@onready var stars_label: Label = $StarsLabel

func _ready() -> void:
	# Conectar con la señal global del Singleton PlayerData
	if PlayerData.has_signal("economy_updated"):
		PlayerData.economy_updated.connect(_on_economy_updated)
	
	# Actualizar valores iniciales al arrancar
	update_values(PlayerData.coins, PlayerData.stars)

func _on_economy_updated(new_coins: int, new_stars: int) -> void:
	update_values(new_coins, new_stars)

func update_values(coins: int, stars: int) -> void:
	if coins_label:
		coins_label.text = "🪙 Monedas: " + str(coins)
	if stars_label:
		stars_label.text = " ⭐ Estrellas: " + str(stars)
