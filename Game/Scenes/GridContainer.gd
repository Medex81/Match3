extends GridContainer

onready var field_red = preload("res://Game/Scenes/FieldRed.tscn")
onready var field_blue = preload("res://Game/Scenes/FieldBlue.tscn")
onready var field_yellow = preload("res://Game/Scenes/FieldYellow.tscn")
onready var field_green = preload("res://Game/Scenes/FieldGreen.tscn")

var n_field_size = 50
var n_cols = 10
var a_cells = []
onready var a_fields_types = [field_red, field_blue, field_yellow, field_green]

func _ready():
	randomize()
	#n_cols = rect_size.x / n_field_size
	columns = n_cols
	for ind in n_cols * n_cols:
		var container = Container.new()
		container.rect_min_size = Vector2(n_field_size, n_field_size)
		a_cells.append(container)
		add_child(container)
		container.add_child(a_fields_types[randi() % a_fields_types.size()].instance())

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
