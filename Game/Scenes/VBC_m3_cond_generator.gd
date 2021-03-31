extends VBoxContainer

# ПСЕВДОНИМЫ УЗЛОВ
onready var container_cell_types = $SC_types/HBC_types
onready var cell_type_base = preload("res://Game/Scenes/Field.tscn")
onready var effects_mgr = preload("res://Game/Managers/Effects_mgr.gd").new()

# ПЕРЕМЕННЫЕ
# выбранный тип ячейки
var curr_cell_type = null

# СИГНАЛЫ
# отправляем сигнал о смене выбранного типа
signal send_sel_cell_type_changed(type)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_types_dict(dict:Dictionary):
	# в наличии узлы для типов и контейнера
	if container_cell_types:
		# из реализации передают словарь с парами тип-текстура
		for key in dict.keys():
			# текстура установлена
			if dict[key]:
				# чтобы не привязываться к дополнительной сцене и не таскать её с собой - дублируем узел
				var next_cell_type = cell_type_base.instance()
				# добавим калбек для отслеживания клика на ячейке
				next_cell_type.cb_click =  funcref(self, "on_controlClicked")
				next_cell_type.cell_type = key
				next_cell_type.texture = dict[key]
				container_cell_types.add_child(next_cell_type)
	else:
		print("Error(VBC_m3_cond_generator). container_cell_types or cell_type_node is null")

func on_controlClicked(sender):
	if sender.cell_type == curr_cell_type:
		curr_cell_type = null
		effects_mgr.remove_effect(sender, "Border")
	else:
		curr_cell_type = sender.cell_type
		effects_mgr.set_unique_effect(sender, "Border")
	emit_signal("send_sel_cell_type_changed", curr_cell_type)
