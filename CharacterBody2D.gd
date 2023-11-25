extends CharacterBody2D


const SPEED = 450.0
const JUMP_VELOCITY = -300.0
var JUMPS = 2
var VELOCITY = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


ffunc _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and JUMPS > 0 and not Input.is_action_pressed("ui_down"):
		velocity.y = JUMP_VELOCITY * 2
		move_toward(velocity.y, 0, 1000)
		#velocity.y = JUMP_VELOCITY
		JUMPS -= 1
	if is_on_floor():
		JUMPS = 2
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction and not is_on_floor():
		velocity.x = direction * SPEED * 0.9
		velocity.x = move_toward(velocity.x, 0, 25)
	if direction and is_on_floor():
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, 25)
	set_motion_mode( 0 )
	move_and_slide()
