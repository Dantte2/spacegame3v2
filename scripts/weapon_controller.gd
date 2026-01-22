extends Node2D

# =========================================================
#                       EXPORTS
# =========================================================
@export var bullet_scene: PackedScene
@export var missile_scene: PackedScene
@export var super_scene: PackedScene

@export var tracer_scene: PackedScene
@export var muzzleflash_scene: PackedScene

@export var gunpoint: Node2D
@export var missile_point: Node2D

@export var bullet_speed: float = 2000.0
@export var missile_speed: float = 2000.0

@export var fire_rate: float = 0.05
@export var missile_cooldown: float = 1.0
@export var super_cooldown: float = 1.0

@export var bullet_spread_deg: float = 2.0

# =========================================================
#                       TIMERS
# =========================================================
var shoot_timer: Timer
var missile_timer: Timer
var super_timer: Timer

# =========================================================
#                       READY
# =========================================================
func _ready() -> void:
	shoot_timer = _make_timer(fire_rate)
	missile_timer = _make_timer(missile_cooldown)
	super_timer = _make_timer(super_cooldown)

# =========================================================
#                       PUBLIC API
# =========================================================
func try_shoot() -> void:
	if shoot_timer.is_stopped():
		shoot_bullet()
		shoot_timer.start()

func try_missile() -> void:
	if missile_timer.is_stopped():
		shoot_missile()
		missile_timer.start()

func try_super() -> void:
	if super_timer.is_stopped():
		spawn_super()
		super_timer.start()

# =========================================================
#                       BULLET
# =========================================================
func shoot_bullet() -> void:
	if bullet_scene == null or gunpoint == null:
		return

	var bullet = bullet_scene.instantiate()

	var spread = deg_to_rad(bullet_spread_deg)
	var random_rot = randf_range(-spread, spread)

	var forward_offset = Vector2(20, 0).rotated(gunpoint.global_rotation)
	bullet.global_position = gunpoint.global_position + forward_offset
	bullet.global_rotation = gunpoint.global_rotation + random_rot

	if "velocity" in bullet:
		bullet.velocity = Vector2(bullet_speed, 0).rotated(bullet.global_rotation)

	bullet.z_as_relative = false
	bullet.z_index = 100
	get_tree().current_scene.add_child(bullet)

	_spawn_tracer(bullet)
	_spawn_muzzle_flash()

# =========================================================
#                       MISSILE (FIXED)
# =========================================================
func shoot_missile() -> void:
	if missile_scene == null or missile_point == null:
		return

	var directions = [1, 1.2, -1, -1.2, 1.3, -1.3]
	directions.shuffle()

	# Snapshot valid enemies ONCE
	var enemies: Array[Node2D] = []
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and e is Node2D:
			enemies.append(e)

	for dir in directions:
		var missile = missile_scene.instantiate()

		var vertical_offset = randi_range(10, 40) * dir
		missile.global_position = missile_point.global_position + Vector2(0, vertical_offset)
		missile.global_rotation = missile_point.global_rotation

		if "velocity" in missile:
			missile.velocity = Vector2(missile_speed, 0).rotated(missile.global_rotation)

		if "direction_multiplier" in missile:
			missile.direction_multiplier = dir

		# ADD FIRST (important)
		get_tree().current_scene.add_child(missile)

		# Assign target SAFELY after entering tree
		if enemies.size() > 0 and missile.has_method("set_target"):
			var target = enemies.pick_random()
			if is_instance_valid(target):
				missile.call_deferred("set_target", target)

		if missile.has_node("Exhaust"):
			missile.get_node("Exhaust").play("exhaust")

		await get_tree().create_timer(0.1).timeout

# =========================================================
#                       SUPER
# =========================================================
func spawn_super() -> void:
	if super_scene == null or missile_point == null:
		return

	var super_attack = super_scene.instantiate()
	super_attack.global_position = missile_point.global_position
	get_tree().current_scene.add_child(super_attack)

# =========================================================
#                       HELPERS
# =========================================================
func _make_timer(time: float) -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = time
	add_child(t)
	return t

func _spawn_tracer(bullet: Node2D) -> void:
	if tracer_scene == null:
		return

	var tracer = tracer_scene.instantiate()
	tracer.global_position = bullet.global_position
	tracer.global_rotation = bullet.global_rotation
	tracer.z_as_relative = false
	tracer.z_index = 110
	get_tree().current_scene.add_child(tracer)

func _spawn_muzzle_flash() -> void:
	if muzzleflash_scene == null or gunpoint == null:
		return

	var flash = muzzleflash_scene.instantiate()
	gunpoint.add_child(flash)
	flash.position = Vector2.ZERO
	flash.z_as_relative = false
	flash.z_index = 120
