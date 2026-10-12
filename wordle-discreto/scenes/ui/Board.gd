extends VBoxContainer
class_name Board

var rows: Array[Row] = []

func _ready() -> void:
	rows.clear()
	for child in get_children():
		if child is Row:
			rows.append(child)

func update_row_text(row_index: int, word: String) -> void:
	if row_index >= 0 and row_index < rows.size():
		rows[row_index].set_text(word)

func set_row_result(row_index: int, states: Array) -> void:
	if row_index >= 0 and row_index < rows.size():
		rows[row_index].set_states(states)

func animate_row_reveal(row_index: int, states: Array, callback: Callable = Callable()) -> void:
	if row_index >= 0 and row_index < rows.size():
		await rows[row_index].animate_reveal(states, callback)

func reset_board() -> void:
	for row in rows:
		row.clear()
