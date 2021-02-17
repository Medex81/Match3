extends MarginContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var label = $NinePatchRect/Label
#onready var tween = $Tween


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_points_change(new_value:int):
	label.text = str(new_value)
