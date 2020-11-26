extends GridContainer

onready var field_red = preload("res://Game/Scenes/FieldRed.tscn")
onready var field_blue = preload("res://Game/Scenes/FieldBlue.tscn")
onready var field_yellow = preload("res://Game/Scenes/FieldYellow.tscn")
onready var field_green = preload("res://Game/Scenes/FieldGreen.tscn")
onready var scene_core = preload("res://Game/Logic/M3_core.gd").new()

var n_field_size = 50
var a_cells = []

func check_matches():
	if a_cells.empty() == false:
		scene_core.find_all_matches()

func match_proc(match_idxs):
	for matched in match_idxs:
		for ind in matched:
			if a_cells[ind].has_node("Node2D") == true:
				a_cells[ind].get_node("Node2D").queue_free()
				
func swap_proc(from_ind, to_ind):
	var from = a_cells[from_ind].get_node("Node2D")
	var to = a_cells[to_ind].get_node("Node2D")
	if from != null && to == null :
		a_cells[from_ind].remove_child(from)
		a_cells[to_ind].add_child(from)
	else:
		print("Error swap_proc(to - not empty) -> from_ind " + from_ind + ", to_ind " + to_ind)
	
func create_proc(ind, type):
	if a_cells[ind].has_node("Node2D") == false:
		match type:
			scene_core.e_fields_types.EFT_BLUE:
				a_cells[ind].add_child(field_blue.instance())
			scene_core.e_fields_types.EFT_GREEN:
				a_cells[ind].add_child(field_green.instance())
			scene_core.e_fields_types.EFT_RED:
				a_cells[ind].add_child(field_red.instance())
			scene_core.e_fields_types.EFT_YELLOW:
				a_cells[ind].add_child(field_yellow.instance())
	else:
		print("Error create_proc(cell in ind not empty) -> ind " + ind + ",type " + type)

func _ready():
	add_child(scene_core)
	scene_core.pf_match_clb = funcref(self, "match_proc")
	scene_core.pf_swap_clb = funcref(self, "swap_proc")
	scene_core.pf_create_clb = funcref(self, "create_proc")
	scene_core.init()
	if scene_core.n_cols != null:
		columns = scene_core.n_cols
		for ind in scene_core.fields_model:
			var container = Container.new()
			container.rect_min_size = Vector2(n_field_size, n_field_size)
			a_cells.append(container)
			add_child(container)
			match ind:
				scene_core.e_fields_types.EFT_BLUE:
					container.add_child(field_blue.instance())
				scene_core.e_fields_types.EFT_GREEN:
					container.add_child(field_green.instance())
				scene_core.e_fields_types.EFT_RED:
					container.add_child(field_red.instance())
				scene_core.e_fields_types.EFT_YELLOW:
					container.add_child(field_yellow.instance())
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_redraw_button_up():
	for ind in range(scene_core.fields_model.size()):
		a_cells[ind].get_node("Node2D").queue_free()
		match scene_core.fields_model[ind]:
			scene_core.e_fields_types.EFT_BLUE:
				a_cells[ind].add_child(field_blue.instance())
			scene_core.e_fields_types.EFT_GREEN:
				a_cells[ind].add_child(field_green.instance())
			scene_core.e_fields_types.EFT_RED:
				a_cells[ind].add_child(field_red.instance())
			scene_core.e_fields_types.EFT_YELLOW:
				a_cells[ind].add_child(field_yellow.instance())
