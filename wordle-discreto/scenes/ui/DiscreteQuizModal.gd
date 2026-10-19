class_name DiscreteQuizModal
extends Control

signal quiz_completed(success: bool, reward_coins: int)

@onready var overlay: ColorRect = $Overlay
@onready var modal_panel: PanelContainer = $Overlay/PanelContainer
@onready var category_label: Label = $Overlay/PanelContainer/VBoxContainer/CategoryLabel
@onready var question_label: Label = $Overlay/PanelContainer/VBoxContainer/QuestionLabel
@onready var options_container: VBoxContainer = $Overlay/PanelContainer/VBoxContainer/OptionsContainer
@onready var explanation_label: Label = $Overlay/PanelContainer/VBoxContainer/ExplanationLabel
@onready var action_button: Button = $Overlay/PanelContainer/VBoxContainer/ActionButton

var current_question: Dictionary = {}
var is_answered: bool = false

func _ready() -> void:
	visible = false
	if action_button:
		action_button.pressed.connect(_on_action_button_pressed)

func show_question(question_data: Dictionary) -> void:
	current_question = question_data
	is_answered = false
	visible = true

	# Configurar textos
	category_label.text = "📚 " + question_data.get("categoria", "Matemáticas Discretas")
	question_label.text = question_data.get("enunciado", "")
	explanation_label.text = ""
	explanation_label.visible = false
	action_button.visible = false

	# Limpiar opciones anteriores
	for child in options_container.get_children():
		child.queue_free()

	# Generar botones de opciones
	var options = question_data.get("opciones", [])
	for option in options:
		var btn = Button.new()
		btn.text = option
		btn.custom_minimum_size = Vector2(0, 45)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(func(): _on_option_selected(option, btn))
		options_container.add_child(btn)

	# Animación de entrada
	if modal_panel:
		modal_panel.scale = Vector2(0.8, 0.8)
		var tween = create_tween()
		tween.tween_property(modal_panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_option_selected(selected_option: String, selected_btn: Button) -> void:
	if is_answered:
		return

	is_answered = true
	var correct_option = current_question.get("respuesta_correcta", "")
	var is_correct = (selected_option == correct_option)

	# Deshabilitar todos los botones de opciones
	for child in options_container.get_children():
		if child is Button:
			child.disabled = true
			if child.text == correct_option:
				child.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2)) # Verde
			elif child == selected_btn and not is_correct:
				child.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2)) # Rojo

	# Mostrar explicación
	explanation_label.visible = true
	var text_explanation = current_question.get("explicacion", "")
	if is_correct:
		explanation_label.text = "¡CORRECTO! 🎉\n" + text_explanation
		explanation_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		action_button.text = "Continuar (+50 🪙)"
	else:
		explanation_label.text = "INCORRECTO ❌\nRespuesta correcta: " + correct_option + "\n" + text_explanation
		explanation_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		action_button.text = "Cerrar"

	action_button.visible = true

func _on_action_button_pressed() -> void:
	var correct_option = current_question.get("respuesta_correcta", "")
	# Revisar cuál fue seleccionada comprobando el texto
	var success = explanation_label.text.begins_with("¡CORRECTO!")
	var reward = 50 if success else 0
	
	visible = false
	quiz_completed.emit(success, reward)