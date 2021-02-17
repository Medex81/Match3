extends HBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var time = $HBoxTop/TimeContainer
onready var points = $HBoxTop/PointsContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
	
func set_points_change(new_value:int):
	if points:
		points.set_points_change(new_value)
	
func set_session_timer(value:String):
	if time:
		time.set_session_timer(value)
