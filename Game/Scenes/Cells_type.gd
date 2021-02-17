extends VScrollBar


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var grid = $"../../TextureRect_m3_back/GridContainer"


# Called when the node enters the scene tree for the first time.
func _ready():
	if grid:
		var cells = grid.get_unique_cells()
		#for cell in cells:
			
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
