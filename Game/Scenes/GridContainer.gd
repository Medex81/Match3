extends GridContainer

# Сцены ячеек
onready var field = preload("res://Game/Scenes/Field.tscn")

onready var blue_gem_tex_res = preload("res://Game/Assets/stone_blue.png")
onready var green_gem_tex_res = preload("res://Game/Assets/stone_green.png")
onready var yellow_gem_tex_res = preload("res://Game/Assets/stone_yellow.png")
onready var red_gem_tex_res = preload("res://Game/Assets/stone_pink.png")

onready var hole_tex_res = preload("res://Game/Assets/scene.png")

onready var m4_tex_res = preload("res://Game/Assets/blitz.png")
onready var m5_tex_res = preload("res://Game/Assets/blitz_cross.png")
onready var m6_tex_res = preload("res://Game/Assets/bomb.png")
onready var m7_tex_res = preload("res://Game/Assets/total_bomb.png")

onready var gui = $"../../HBoxHUD"

# Логика сцены
onready var scene_core = preload("res://Game/Logic/M3_core.gd").new()
onready var effects_mgr = preload("res://Game/Managers/Effects_mgr.gd").new()
# размер ячейки в пикселах
var n_field_size = 50
var a_cells = []
var sel_type = null
var cell_types_dict = null

func set_sel_type(type):
	sel_type = type

func check_matches():
	if a_cells.empty() == false:
		scene_core.find_all_matches()

# матч ячеек
func match_proc(match_idxs):
	for matched in match_idxs:
		for ind in matched:
			if a_cells[ind].has_node("Node2D"):
				var cell = a_cells[ind].get_node("Node2D")
				a_cells[ind].remove_child(cell)
				cell.queue_free()

func swap_proc(from_ind, to_ind):
	var from = a_cells[from_ind].get_node("Node2D")
	var to = a_cells[to_ind].get_node("Node2D")
	# матч с пустой ячейкой
	if from != null && to == null:
		a_cells[from_ind].remove_child(from)
		a_cells[to_ind].add_child(from)
	# обмен ячеек
	elif from != null && to != null:
		a_cells[from_ind].remove_child(from)
		a_cells[to_ind].remove_child(to)
		a_cells[from_ind].add_child(to)
		a_cells[to_ind].add_child(from)
		
# создать ячейку
func create_proc(ind, type):
	if a_cells[ind].has_node("Node2D") == false:
		var new_cell = field.instance()
		new_cell.texture = cell_types_dict[type]
		if new_cell.texture:
			a_cells[ind].add_child(new_cell)
			# добавим калбек для отслеживания клика на ячейке
			new_cell.cb_click =  funcref(self, "on_controlClicked")
	else:
		print("Error create_proc(cell in ind not empty) -> ind " + str(ind) + ",type " + str(type))

# показать подсказку
func hint_proc(from_ind, to_ind):
	if a_cells[from_ind].has_node("Node2D/Sprite_select"):
		a_cells[from_ind].get_node("Node2D/Sprite_select").visible = true
	if a_cells[to_ind].has_node("Node2D/Sprite_select") :
		a_cells[to_ind].get_node("Node2D/Sprite_select").visible = true

func set_points(points:int):
	gui.set_points_change(points)
	
func set_timeout(time:String):
	gui.set_session_timer(time)

func _ready():
	add_child(scene_core)
	cell_types_dict = {
		scene_core.e_fields_types.EFT_RED: red_gem_tex_res, 
		scene_core.e_fields_types.EFT_GREEN: green_gem_tex_res, 
		scene_core.e_fields_types.EFT_BLUE: blue_gem_tex_res, 
		scene_core.e_fields_types.EFT_YELLOW: yellow_gem_tex_res,
		scene_core.e_fields_types.EFT_HOLE: hole_tex_res,
		scene_core.e_fields_types.EFT_ROCK: null, 
		scene_core.e_fields_types.EFT_SAND: null,
		scene_core.e_fields_types.EFT_M4: m4_tex_res, 
		scene_core.e_fields_types.EFT_M5: m5_tex_res, 
		scene_core.e_fields_types.EFT_M6: m6_tex_res, 
		scene_core.e_fields_types.EFT_M7: m7_tex_res
	}
	
	# калбеки для логики сцены
	scene_core.pf_match_clb = funcref(self, "match_proc")
	scene_core.pf_swap_clb = funcref(self, "swap_proc")
	scene_core.pf_create_clb = funcref(self, "create_proc")
	scene_core.pf_hint_clb =  funcref(self, "hint_proc")
	scene_core.pf_set_points_clb =  funcref(self, "set_points")
	scene_core.pf_set_timeout_clb =  funcref(self, "set_timeout")
	scene_core.init()
	scene_core.get_auto_start_positions()
	if scene_core.n_cols != null:
		columns = scene_core.n_cols
		for type in scene_core.fields_model:
			var control = Control.new()
			control.rect_min_size = Vector2(n_field_size, n_field_size)
			a_cells.append(control)
			add_child(control)
			create_proc(a_cells.size() - 1, type)
	# проверим наличие матчей после старта
	check_matches()
	
func get_unique_cells():
	var ret = []
	for type in scene_core.e_fields_types.values():
		if cell_types_dict.has(type):
			var new_cell = field.instance()
			new_cell.texture = cell_types_dict[type]
			if new_cell.texture:
				new_cell.cell_type = type
				ret.append(new_cell)
	return ret

# был клик по ячейке
func on_controlClicked(sender):
	# первая ячейка
	var index = a_cells.find(sender.get_parent())
	if index > -1:
		if sel_type:
			scene_core.set_cell(index, sel_type)
			return
		for item in a_cells: 
			# ячейка с которой обмениваем
			if item.get_global_rect().has_point(get_global_mouse_position()):
				var second_index = a_cells.find(item)
				if scene_core.is_type_static(index) || scene_core.is_type_static(second_index):
					return 
				print("Swap cells  -> %d - %d" % [index, second_index])
				effects_mgr.set_unique_effect(a_cells[second_index].get_node("Node2D"), "Border")
				# проверяем, что ячейки смежные
				if index != second_index && scene_core.is_near(index, second_index):
					scene_core.check_swap_cells(index, second_index)
				break
