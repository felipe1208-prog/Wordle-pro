extends Control

@onready var played_label: Label = $StatsContainer/PlayedLabel
@onready var won_label: Label = $StatsContainer/WonLabel
@onready var win_rate_label: Label = $StatsContainer/WinRateLabel
@onready var current_streak_label: Label = $StatsContainer/CurrentStreakLabel
@onready var max_streak_label: Label = $StatsContainer/MaxStreakLabel
@onready var back_button: Button = $BackButton

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	update_stats_display()

func update_stats_display() -> void:
	var played: int = PlayerData.games_played
	var won: int = PlayerData.games_won
	var current_stk: int = PlayerData.current_streak
	var max_stk: int = PlayerData.max_streak
	
	var win_rate: int = 0
	if played > 0:
		win_rate = int((float(won) / float(played)) * 100.0)

	if played_label:
		played_label.text = "Partidas jugadas: " + str(played)
	if won_label:
		won_label.text = "Victorias: " + str(won)
	if win_rate_label:
		win_rate_label.text = "% de victorias: " + str(win_rate) + "%"
	if current_streak_label:
		current_streak_label.text = "Racha actual: " + str(current_stk)
	if max_streak_label:
		max_streak_label.text = "Mejor racha: " + str(max_stk)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
