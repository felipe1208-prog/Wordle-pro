extends Control

@onready var coins_label: Label = $CoinsLabel
@onready var items_container: VBoxContainer = $ItemsContainer
@onready var back_button: Button = $BackButton

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	# Conectar señales del singleton PlayerData para actualización en tiempo real
	if PlayerData.has_signal("economy_updated"):
		PlayerData.economy_updated.connect(_on_economy_updated)
	if PlayerData.has_signal("theme_updated"):
		PlayerData.theme_updated.connect(_on_theme_updated)

	update_coins_display()
	populate_shop_items()

func update_coins_display() -> void:
	if coins_label:
		coins_label.text = "🪙 Monedas: " + str(PlayerData.coins)

func _on_economy_updated(new_coins: int, _new_stars: int) -> void:
	if coins_label:
		coins_label.text = "🪙 Monedas: " + str(new_coins)
	populate_shop_items()

func _on_theme_updated(_theme_id: String) -> void:
	populate_shop_items()

func populate_shop_items() -> void:
	# Limpiar elementos previos para evitar duplicados al refrescar
	for child in items_container.get_children():
		child.queue_free()

	for theme_id in PlayerData.THEMES_CATALOG.keys():
		var theme_data = PlayerData.THEMES_CATALOG[theme_id]
		
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 90)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		margin.add_theme_constant_override("margin_left", 15)
		margin.add_theme_constant_override("margin_right", 15)
		panel.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 15)
		margin.add_child(hbox)
		
		# Información del tema (Nombre y Requisitos)
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var name_label = Label.new()
		name_label.text = theme_data["name"]
		name_label.add_theme_font_size_override("font_size", 18)
		info_vbox.add_child(name_label)
		
		var details_label = Label.new()
		var req_lvl = theme_data["required_level"]
		var cost = theme_data["cost_coins"]
		details_label.text = "Nivel mín: " + str(req_lvl) + " | Costo: 🪙 " + str(cost)
		details_label.add_theme_font_size_override("font_size", 13)
		details_label.add_theme_color_override("font_color", Color("9ca3af"))
		info_vbox.add_child(details_label)
		
		hbox.add_child(info_vbox)
		
		# Botón de acción dinámico (Comprar / Equipar / Equipado)
		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(120, 45)
		action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		var is_unlocked = PlayerData.unlocked_themes.has(theme_id)
		var is_equipped = (PlayerData.current_theme == theme_id)
		
		if is_equipped:
			action_btn.text = "EQUIPADO"
			action_btn.disabled = true
		elif is_unlocked:
			action_btn.text = "EQUIPAR"
			action_btn.pressed.connect(func(): PlayerData.equip_theme(theme_id))
		else:
			action_btn.text = "COMPRAR"
			action_btn.pressed.connect(func(): PlayerData.buy_theme(theme_id))
			
		hbox.add_child(action_btn)
		items_container.add_child(panel)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
