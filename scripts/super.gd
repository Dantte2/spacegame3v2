extends CharacterBody2D

# --------------------------------------------------
# PROJECTILE SETTINGS
# --------------------------------------------------
@export var lifetime: float = 10.0

# Movement
@export var drop_time: float = 0.25
@export var drop_speed: float = 900.0

@export var initial_speed: float = 200.0
@export var max_speed: float = 2000.0
@export var acceleration: float = 5000.0
@export var turn_speed: float = 10.0

# Combat
@export var damage: int = 500
@export var homing_radius: float = 2000.0
@export var collision_delay: float = 0.0

# Visuals
@export var explosion_scene: PackedScene
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var trail: GPUParticles2D = $AnimatedSprite2D/GPUParticles2D

# --------------------------------------------------
# INTERNAL STATE
# --------------------------------------------------
enum State { DROPPING, HOMING }
var state: State = State.DROPPING
var state_timer := 0.0

var target: Node2D = null
var current_speed := 0.0
var exploded := false

# --------------------------------------------------
# READY
# --------------------------------------------------
func _ready():
	if sprite:
		sprite.play()

	if trail:
		trail.emitting = false

	start_lifetime_timer()

# --------------------------------------------------
# LIFETIME
# --------------------------------------------------
func start_lifetime_timer():
	await get_tree().create_timer(lifetime).timeout
	if is_inside_tree() and not exploded:
		explode()

# --------------------------------------------------
# PHYSICS LOOP
# --------------------------------------------------
func _physics_process(delta):
	state_timer += delta

	match state:

		# ------------------------------------------
		# DROP PHASE (ALWAYS DOWN)
		# ------------------------------------------
		State.DROPPING:
			global_position.y += drop_speed * delta

			if state_timer >= drop_time:
				state = State.HOMING
				state_timer = 0.0
				current_speed = initial_speed

				# Start trail exactly when forward motion begins
				if trail:
					trail.emitting = true

		# ------------------------------------------
		# HOMING + ACCELERATION
		# ------------------------------------------
		State.HOMING:
			update_target()
			update_rotation(delta)
			update_speed(delta)
			move_forward(delta)

# --------------------------------------------------
# TARGETING
# --------------------------------------------------
func update_target():
	if target and target.is_inside_tree():
		return
	target = get_closest_enemy()

func get_closest_enemy() -> Node2D:
	var closest: Node2D = null
	var min_dist := homing_radius

	for e in get_tree().get_nodes_in_group("enemy"):
		if not e.is_inside_tree():
			continue

		var dist = global_position.distance_to(e.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = e

	return closest

# --------------------------------------------------
# MOVEMENT
# --------------------------------------------------
func update_rotation(delta):
	if not target:
		return

	var desired_angle = (target.global_position - global_position).angle()
	rotation = lerp_angle(rotation, desired_angle, turn_speed * delta)

func update_speed(delta):
	current_speed += acceleration * delta
	current_speed = min(current_speed, max_speed)

func move_forward(delta):
	var velocity = Vector2(current_speed, 0).rotated(rotation)
	var collision = move_and_collide(velocity * delta)
	if collision:
		handle_collision(collision)

# --------------------------------------------------
# COLLISION
# --------------------------------------------------
func handle_collision(collision: KinematicCollision2D):
	if exploded:
		return

	exploded = true
	var body = collision.get_collider()

	if collision_delay > 0.0:
		await get_tree().create_timer(collision_delay).timeout

	if body and body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

	explode()

# --------------------------------------------------
# EXPLOSION
# --------------------------------------------------
func explode():
	if not is_inside_tree():
		return

	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)

	queue_free()
