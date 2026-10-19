extends Control

@onready var play_button: Button = $MenuContainer/PlayButton if has_node("MenuContainer/PlayButton") else null
@onready var stats_button: Button = $MenuContainer/StatsButton if has_node("MenuContainer/StatsButton") else null
@onready var shop_button: Button = $MenuContainer/ShopButton if has_node("MenuContainer/ShopButton") else null
@onready var exit_button: Button = $MenuContainer/ExitButton if has_node("MenuContainer/ExitButton") else null

func _ready() -> void:
	if play_button == null:
		var buttons = find_children("*", "Button", true)
		if buttons.size() >= 1: play_button = buttons[0]
		if buttons.size() >= 2: stats_button = buttons[1]
		if buttons.size() >= 3: shop_button = buttons[2]
		if buttons.size() >= 4: exit_button = buttons[3]

	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if stats_button:
		stats_button.pressed.connect(_on_stats_pressed)
	if shop_button:
		shop_button.pressed.connect(_on_shop_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func _on_stats_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/StatsMenu.tscn")

func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/ShopMenu.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
