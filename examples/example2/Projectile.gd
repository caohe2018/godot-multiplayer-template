extends CharacterBody2D

var direction
const SPEED = 300

func _ready():
	# wait for a bit then kill the projectile
	if is_multiplayer_authority():
		await get_tree().create_timer(3).timeout
		$Sync.remove()

func _physics_process(delta):
	var collision = move_and_collide(direction * delta * SPEED)
	if is_multiplayer_authority() and collision and collision.get_collider().is_in_group("enemy"):
		collision.get_collider().queue_free()
