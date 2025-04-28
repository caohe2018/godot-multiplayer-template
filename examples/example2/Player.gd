extends CharacterBody2D

signal health_changed(percentage)
var health = 1.0
const speed = 200

func _ready():
	add_to_group("players")
	assert(health_changed.connect(get_parent().update_health) == OK)

func _network_ready(is_source):
	if is_source:
		position = Vector2(randf_range(0, get_viewport_rect().size.x), randf_range(0, get_viewport_rect().size.y))

func take_damage():
	if is_multiplayer_authority():
		health -= 0.04
		health_changed.emit(health)

func _process(delta):
	if Input.is_action_pressed("ui_up"):
		position += Vector2(0, -speed * delta)
	if Input.is_action_pressed("ui_down"):
		position += Vector2(0, speed * delta)
	if Input.is_action_pressed("ui_left"):
		position += Vector2(-speed * delta, 0)
	if Input.is_action_pressed("ui_right"):
		position += Vector2(speed * delta, 0)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var direction = (get_viewport().get_mouse_position() - position).normalized()
		spawn_projectile(position, direction)

func spawn_projectile(spawn_position, direction):
	var ProjectileClass = preload("res://examples/example2/Projectile.tscn")
	var projectile = ProjectileClass.instantiate()
	# Make sure the projectile doesn't spawn on top of us
	projectile.position = spawn_position + direction * 30
	projectile.direction = direction
	projectile.set_multiplayer_authority(1)
	get_parent().add_child(projectile)
