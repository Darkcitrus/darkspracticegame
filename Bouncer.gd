extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_up"):
		set_collision_mask_value(1, 2)
	else:
		set_collision_mask_value(1, 1)
	
