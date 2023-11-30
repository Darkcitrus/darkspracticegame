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

# Refference variables
@onready var dodge_timer = $DodgeTimer
@onready var dodge_recovery = $DodgeRecovery
@onready var dodge_cooldown = $DodgeCooldown
@onready var dodge_label = $Label
@onready var hitbox = $hitbox
@onready var sword_sprite = $hitbox/Sprite2D
@onready var attackcd = $hitbox/attackcd

func _physics_process(delta) :
	attack_direction = (get_global_mouse_position() - global_position).normalized()
	handle_movement()
	handle_attacks(delta)
	move_and_slide()
	point_hitbox_to_mouse()
	dodge_label.text = str(dodges)

func handle_attacks(delta):
	if Input.is_action_just_pressed('left_click') and not attacking:
		attacking = true
		var attack_vector: Vector2 = hitbox.global_position + attack_direction * thrust_distance
		
		# option 1 using tweens you can also change the speed
		var tween = create_tween()
		tween.tween_property(hitbox, "global_position", attack_vector, 0.3)
		await tween.finished
		attacking = false
		
		# option 2 and 3 are nearly the same. only difference is the method called
		# option 2 using lerp()
		hitbox.global_position = lerp(hitbox.global_position, attack_vector, 1) 
		# option 3 using move_toward()
		hitbox.global_position = hitbox.global_position.move_toward(attack_vector, 100)
		
		attackcd.start()
		print("Player attacked with power: ", attack_power)
	#if Input.is_action_just_pressed('right_click'):

func point_hitbox_to_mouse():
	if not attacking:
		sword_sprite.rotation = attack_direction.angle() + PI/2
		hitbox.global_position = global_position + attack_direction * 50

func handle_movement():
	
	if not dodging:
		move_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var SPEED = run_speed if not dodging else dodge_speed
	var movedirection = move_input * SPEED
	velocity = movedirection
	if can_dodge:
		if Input.is_action_just_pressed("ui_select") and not dodging and dodges > 0:
			handle_dodge()

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
	pass
