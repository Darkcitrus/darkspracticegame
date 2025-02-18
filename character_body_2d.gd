extends CharacterBody2D 

# Current state variables
var can_dodge: bool = true
var dodging: bool = false
var attacking: bool = false
var dodge_recovering: bool = false
var attack_power = 5
var thrust_distance = 50

# Movement variables
var run_speed = 250
var dodge_speed: int = 1000
var direction: Vector2
var attack_direction: Vector2
var move_input = Vector2()
var dodges = 2
const MAX_DODGES = 2
const DODGE_COOLDOWN_TIME = 1.0
const DODGE_RECOVERY_TIME = 2.0

# Reference variables
@onready var dodge_timer = $DodgeTimer
@onready var dodge_recovery = $DodgeRecovery
@onready var dodge_cooldown = $DodgeCooldown
@onready var dodge_label = $Label
@onready var hitbox = $hitbox
@onready var sword_sprite = $hitbox/Sprite2D
@onready var attackcd = $hitbox/attackcd
@onready var projectiles = $Projectiles

# var fire_ball: PackedScene = preload("res://scenes/fire_ball.tscn")

func _physics_process(delta) :
	attack_direction = (get_global_mouse_position() - global_position).normalized()
	handle_movement()
	thrust_attack(delta)
	move_and_slide()
	point_hitbox_to_mouse()
	dodge_label.text = str(dodges)

var attack_cooldown = 0.3  # attack cooldown in seconds
var last_attack_time = 0

func thrust_attack(_delta):
	# Check if the left mouse button is pressed and the character is not already attacking
	if Input.is_action_pressed('left_click') and not attacking:
		# Get the current time in seconds
		var current_time = Time.get_ticks_msec() / 1000.0
		# Check if the cooldown period has passed since the last attack
		if current_time - last_attack_time >= attack_cooldown:
			# Update the last attack time to the current time
			last_attack_time = current_time
			# Set attacking flag to true
			attacking = true
			
			# Create a tween for thrust animation
			var tween = create_tween()
			# Set the tween transition type to exponential
			tween.set_trans(Tween.TRANS_EXPO)
			tween.set_ease(Tween.EASE_OUT)
			
			# Calculate positions relative to player
			var start_offset = 150  # Normal distance from player
			var thrust_offset = 300  # Extended thrust distance
			
			# Forward thrust
			tween.tween_method(
				func(progress: float):
					var current_offset = lerp(start_offset, thrust_offset, progress)
					hitbox.position = attack_direction * current_offset,
				0.0, 1.0, 0.15
			)
			
			# Return to starting position
			tween.tween_method(
				func(progress: float):
					var current_offset = lerp(thrust_offset, start_offset, progress)
					hitbox.position = attack_direction * current_offset,
				0.0, 1.0, 0.25
			)
			
			tween.tween_callback(func(): attacking = false)
			attackcd.start()
		
	if Input.is_action_pressed('right_click') and not attacking:
		perform_sweep_attack()
		
	#if Input.is_action_just_pressed('right_click'):
	#	var new_fire_ball = fire_ball.instantiate()
	#	new_fire_ball.direction = attack_direction
	#	projectiles.add_child(new_fire_ball)
		
		pass


var swinging_left: bool = true  # Track the current direction of the swing
var swinging: bool = false  # Track if the sword is currently swinging
var start_angle: float  # Store the start angle for the swing
var end_angle: float    # Store the end angle for the swing

func perform_sweep_attack():
	if Time.get_ticks_msec() / 1000.0 - last_attack_time >= attack_cooldown:
		last_attack_time = Time.get_ticks_msec() / 1000.0
		attacking = true
		swinging = true  # Set swinging to true when the swing starts
		
		# Calculate the direction to the mouse position
		var mouse_position = get_global_mouse_position()
		var direction_to_mouse = (mouse_position - global_position).normalized()
		var swing_base_angle = direction_to_mouse.angle()  # Get the current angle towards the mouse
		
		# Calculate the start and end angles for the half-circle sweep
		start_angle = swing_base_angle - PI / 4 if swinging_left else swing_base_angle + PI / 4  # Alternate direction 
		end_angle = swing_base_angle + PI / 4 if swinging_left else swing_base_angle - PI / 4    # Alternate direction
		
		# Toggle the direction for the next swing
		swinging_left = !swinging_left
		
		# Create a tween for smooth animation
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_EXPO)
		tween.set_ease(Tween.EASE_IN_OUT)
		
		# Set up the sweep animation
		tween.tween_method(func(progress: float):
			var current_angle = lerp_angle(start_angle, end_angle, progress)
			var sweep_direction = Vector2(cos(current_angle), sin(current_angle))
			hitbox.global_position = global_position + sweep_direction * 50
			sword_sprite.rotation = current_angle + PI / 2  # Use the calculated angle
			
		, 0.0, 1.0, 0.5)  # 0.5 seconds duration
		
		tween.tween_callback(func():
			attacking = false
			swinging = false  # Reset swinging when the animation is done
		)
		
		attackcd.start()

func point_hitbox_to_mouse():
	if not attacking:
		sword_sprite.rotation = attack_direction.angle() + PI/2
		hitbox.global_position = global_position + attack_direction * 50

# This function handles the player's movement input.
# It checks for the direction keys and applies movement accordingly.
func handle_movement():
	# Check if the player is not currently dodging
	if not dodging:
		# Get the movement input from the direction keys
		move_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# Determine the movement speed based on whether the player is dodging or not
	var SPEED = run_speed if not dodging else dodge_speed
	# Calculate the movement direction by multiplying the input vector with the speed
	var movedirection = move_input * SPEED
	# Apply the movement to the player's velocity
	velocity = movedirection
	# Check if the player can dodge and if the dodge button is pressed
	if can_dodge:
		if Input.is_action_just_pressed("ui_select") and not dodging and dodges > 0:
			# Handle the dodge movement
			handle_dodge()

# This function handles the player's dodge movement.
# It reduces the number of available dodges, starts the dodge recovery timer, and sets the dodging flag to true.
func handle_dodge():
	dodges -= 1 
	print("dashes:"+str(dodges))
	dodge_recovery.start()
	if dodge_timer.timeout:
		dodging = true
		dodge_timer.start()

# timeout section
func _on_dodge_timer_timeout():
	can_dodge = false
	dodging = false
	dodge_cooldown.start()
	if dodges < MAX_DODGES:
		dodge_recovering = true
		dodge_recovery.start()

func _on_dodge_recovery_timeout():
	if dodges < MAX_DODGES:
		dodges += 1
		print("+"+str(dodges))
	dodge_recovery.start()

func _on_dodge_cooldown_timeout():
	can_dodge = true

func _on_attackcd_timeout():
	attacking = false
	print("Player attacked with power: ", attack_power)
	pass

func sweep_attack():
	var mouse_pos = get_global_mouse_position()
	var angle = position.direction_to(mouse_pos).angle()
	
	# Get a reference to the sword Sprite2D
	var sword = $hitbox/Sprite2D
	
	# Rotate the sword towards the mouse position
	sword.rotation = angle + PI/2  # PI/2 is added because the sword is initially rotated by 90 degrees
	
	# Implement a sweeping motion (example: 45 degrees sweep)
	var sweep_angle = PI/4
	
	# Animate the rotation
	var tween = create_tween()
	tween.tween_property(sword, "rotation", angle + PI/2 + sweep_angle, 0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sword, "rotation", angle + PI/2 - sweep_angle, 0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_delay(0.1)
	tween.tween_property(sword, "rotation", angle + PI/2, 0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_delay(0.2)
