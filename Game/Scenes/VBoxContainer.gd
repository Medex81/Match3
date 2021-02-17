extends VBoxContainer

var sel_type = null
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var grid = $"../../../TextureRect_m3_back/GridContainer"
onready var effects_mgr = preload("res://Game/Managers/Effects_mgr.gd").new()


# Called when the node enters the scene tree for the first time.
func _ready():
	if grid:
		var cells = grid.get_unique_cells()
		for cell in cells:
			# добавим калбек для отслеживания клика на ячейке
			cell.cb_click =  funcref(self, "on_controlClicked")
			add_child(cell)

func on_controlClicked(sender):
	if sender.cell_type == sel_type:
		sel_type = null
		effects_mgr.remove_effect(sender, "Border")
	else:
		sel_type = sender.cell_type
		effects_mgr.set_unique_effect(sender, "Border")
	if grid:
		grid.set_sel_type(sel_type)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
