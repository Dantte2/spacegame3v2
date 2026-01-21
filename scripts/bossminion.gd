extends CharacterBody2D

# ====================
# EXPORTS
# ====================
@export var base_speed: float = 100.0
@export var max_speed: float = 600.0
@export var acceleration: float = 150.0
@export var turn_speed: float = 2.0

@export var damage_to_health: int = 1
@export var damage_to_shield: int = 1

@export var drop_distance_min: float = 40.0
@export var drop_distance_max: float = 100.0
@export var drop_time: float = 0.25

@export var max_health: int = 50     
@export var death_animation_scene: PackedScene   

# ====================
# INTERNAL
# ====================
var current_speed: float
var dropped := false
var drop_start_pos: Vector2
var drop_timer := 0.0
var drop_distance: float
var health: int

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# ====================
# READY
# ====================
func _ready() -> void:
	current_speed = base_speed
	drop_start_pos = global_position
	drop_timer = 0.0
	dropped = false
	health = max_health

	# Randomize drop distance per mine
	drop_distance = randf_range(drop_distance_min, drop_distance_max)

	if sprite:
		sprite.play()

	collision_layer = 2
	collision_mask = 1

# ====================
# PHYSICS PROCESS
# ====================
func _physics_process(delta: float) -> void:
	var target = _get_closest_player()

	# --- Drop phase ---
	if not dropped:
		_drop_phase(delta)
		if target and sprite:
			sprite.rotation = (target.global_position - global_position).angle()
		return

	# --- Homing phase ---
	if not target:
		return

	var dir = (target.global_position - global_position).normalized()

	if velocity.length() > 0:
		var angle_diff = velocity.angle_to(dir)
		var turn = clamp(angle_diff, -turn_speed * delta, turn_speed * delta)
		velocity = velocity.rotated(turn)
	else:
		velocity = dir

	current_speed = min(current_speed + acceleration * delta, max_speed)
	velocity = velocity.normalized() * current_speed

	var collision = move_and_collide(velocity * delta)
	if collision:
		_handle_hit(collision.get_collider())

	if sprite and target:
		sprite.rotation = lerp_angle(sprite.rotation, (target.global_position - global_position).angle(), 0.2)

# ====================
# DROP PHASE
# ====================
func _drop_phase(delta: float) -> void:
	drop_timer += delta
	var t = min(drop_timer / drop_time, 1.0)

	# Random horizontal offset (set once per mine)
	if not has_meta("drop_offset"):
		var offset_x = randf_range(-40.0, 40.0)
		set_meta("drop_offset", offset_x)

	var offset_x = get_meta("drop_offset")

	# Apply drop with horizontal offset
	global_position.x = drop_start_pos.x + offset_x * t
	global_position.y = drop_start_pos.y + drop_distance * t

	if t >= 1.0:
		dropped = true

# ====================
# DAMAGE HANDLING
# ====================
func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		_die()

# ====================
# DEATH / EXPLOSION
# ====================
func _die() -> void:
	# Spawn death animation if assigned
	if death_animation_scene:
		var anim = death_animation_scene.instantiate()
		anim.global_position = global_position
		get_tree().get_root().call_deferred("add_child", anim)

	# Remove the mine
	queue_free()

# ====================
# HELPER: Closest player
# ====================
func _get_closest_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return null

	var closest: Node2D = null
	var min_dist = INF
	for p in players:
		if not p is Node2D:
			continue
		var d = global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			closest = p
	return closest

# ====================
# COLLISION HANDLING
# ====================
func _handle_hit(target: Node) -> void:
	if not target:
		return

	var obj = target
	while obj and not obj.has_method("take_damage"):
		obj = obj.get_parent()
	if not obj:
		_die()
		return

	# If it hits player or other damageable object, apply damage to them
	if "shield" in obj and obj.shield > 0:
		if obj.has_method("apply_shield_damage"):
			obj.apply_shield_damage(damage_to_shield, global_position)
	else:
		obj.take_damage(damage_to_health)

	# Destroy the mine after collision (and play animation)
	_die()
