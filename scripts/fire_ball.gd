extends Area2D

#references
@onready var fire_ball_vanish: Timer = $FireBallVanish


var direction: Vector2
const SPEED: int = 1000


#process
func _ready():
	print("FIREBALL")
	fire_ball_vanish.start()
	position = direction * 50

func _process(delta):
	position += direction * SPEED * delta
	pass


#signals
func _on_body_entered(body):
	if body.name != "TopDowner":
		queue_free()

#timers
func _on_fire_ball_vanish_timeout():
	queue_free()



