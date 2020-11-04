extends GridContainer

onready var field_red = preload("res://Game/Scenes/FieldRed.tscn")
onready var field_blue = preload("res://Game/Scenes/FieldBlue.tscn")
onready var field_yellow = preload("res://Game/Scenes/FieldYellow.tscn")
onready var field_green = preload("res://Game/Scenes/FieldGreen.tscn")
onready var scene_core = preload("res://Game/Logic/M3_core.gd").new()

var n_field_size = 50
var a_cells = []

func _ready():	
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
