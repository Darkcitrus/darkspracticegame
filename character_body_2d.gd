extends CharacterBody2D 

# Current state variables
var can_dodge: bool = true
var dodging: bool = false
var dodge_recovering: bool = false
var attack_power = 5
var thrust_distance = 50

# Movement variables
var run_speed = 250
var dodge_speed: int = 1000
var direction: Vector2
var move_input = Vector2()
var dodges = 2
const MAX_DODGES = 2
const DODGE_COOLDOWN_TIME = 1.0
const DODGE_RECOVERY_TIME = 2.0

@onready var dodge_timer = $DodgeTimer
@onready var dodge_recovery = $DodgeRecovery
@onready var dodge_cooldown = $DodgeCooldown
@onready var dodge_label = $Label
@onready var hitbox = $hitbox
@onready var sword_sprite = $hitbox/Sprite2D
@onready var attackcd = $hitbox/attackcd

func _physics_process(_delta) :
	handle_movement()
	handle_attacks()
	move_and_slide()
	point_hitbox_to_mouse()
	dodge_label.text = str(dodges)

func handle_attacks():
	if Input.is_action_just_pressed('left_click'):
		attackcd.start()
		if attackcd.is_stopped():
			hitbox.global_position = global_position + direction * thrust_distance
			hitbox.global_position += (hitbox.global_position - global_position).normalized() * thrust_distance
			sword_sprite.global_position = hitbox.global_position
			print("Player attacked with power: ", attack_power)
	#if Input.is_action_just_pressed('right_click'):
func point_hitbox_to_mouse():
	if attackcd.is_stopped():
		var mouse_pos = get_global_mouse_position()
		var attackdirection = (mouse_pos - global_position).normalized()
		sword_sprite.rotation = attackdirection.angle() + PI/2
		hitbox.global_position = global_position + attackdirection * 50

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
	hitbox.global_position += (hitbox.global_position - global_position).normalized() * thrust_distance
