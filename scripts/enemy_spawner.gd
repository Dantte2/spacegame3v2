extends Node2D

# --- Enemy groups ---
@export var enemy1_group: Array[PackedScene] = []
@export var stationary_enemies: Array[PackedScene] = []
@export var moving_enemies: Array[PackedScene] = []

# --- Portal settings ---
@export var portal_animation: String = "spawn"
@export var spawn_delay: float = 0.5
@export var portal_despawn: float = 0.5
@export var fly_out_distance: float = 80
@export var fly_out_direction: Vector2 = Vector2(-1, 0)
@export var fly_out_duration: float = 0.3
@export var spawn_interval_min: float = 0.2
@export var spawn_interval_max: float = 1.0

# --- Nodes ---
@onready var template_portal: AnimatedSprite2D = $Portal
@onready var spawn_shape: CollisionShape2D = $SpawnArea/CollisionShape2D
@onready var camera: Camera2D = get_viewport().get_camera_2d()

func _ready():
	randomize()
	template_portal.visible = false

	spawn_group(enemy1_group)
	spawn_group(stationary_enemies)
	spawn_group(moving_enemies)

# ----------------------------------------------------

# --- Called for each group ---
func spawn_group(group: Array) -> void:
	for enemy_scene in group:
		if enemy_scene:
			spawn_enemy_with_random_delay(enemy_scene)  

# --- Async function to handle random delay and spawn ---
func spawn_enemy_with_random_delay(enemy_scene: PackedScene) -> void:
	var delay = randf_range(spawn_interval_min, spawn_interval_max)
	await get_tree().create_timer(delay).timeout
	await spawn_enemy_with_portal(enemy_scene)


# ----------------------------------------------------

func update_spawn_area_to_right_half():
	if camera == null:
		return

	var viewport_size = get_viewport_rect().size
	var half_width = viewport_size.x / 2.0
	var full_height = viewport_size.y

	# RectangleShape2D uses extents (half-size)
	var rect: RectangleShape2D = spawn_shape.shape
	rect.extents = Vector2(half_width / 2.0, full_height / 2.0)

	# Set the global_position so LEFT EDGE is at camera center
	var left_edge = camera.global_position.x
	var center_x = left_edge + rect.extents.x
	var center_y = camera.global_position.y
	spawn_shape.global_position = Vector2(center_x, center_y)


# ----------------------------------------------------

func get_random_spawn_position() -> Vector2:
	var rect := spawn_shape.shape as RectangleShape2D
	var extents: Vector2 = rect.extents

	var x := randf_range(-extents.x, extents.x)
	var y := randf_range(-extents.y, extents.y)

	return spawn_shape.global_position + Vector2(x, y)


# ----------------------------------------------------

func spawn_enemy_with_portal(enemy_scene: PackedScene) -> void:
	update_spawn_area_to_right_half()

	# Container for portal + enemy
	var container = Node2D.new()
	add_child(container)
	container.global_position = get_random_spawn_position()

	# Duplicate portal
	var portal = template_portal.duplicate() as AnimatedSprite2D
	container.add_child(portal)
	portal.position = Vector2.ZERO
	portal.visible = true

	# Start fully transparent for fade-in
	portal.modulate.a = 0.0
	portal.animation = portal_animation
	portal.play()

	# Fade-in portal
	var fade_in_tween = portal.create_tween()
	fade_in_tween.tween_property(portal, "modulate:a", 1.0, 0.3)
	fade_in_tween.set_trans(Tween.TRANS_SINE)
	fade_in_tween.set_ease(Tween.EASE_IN)
	await fade_in_tween.finished

	# Wait a short moment so portal is fully visible before spawning enemy
	await get_tree().create_timer(spawn_delay).timeout

	# Spawn enemy at portal
	var enemy = enemy_scene.instantiate()
	enemy.global_position = portal.global_position
	get_tree().current_scene.add_child(enemy)

	# Fly-out effect (GLOBAL position)
	if fly_out_distance > 0:
		var target_pos = enemy.global_position + fly_out_direction.normalized() * fly_out_distance
		var fly_tween = enemy.create_tween()
		fly_tween.tween_property(enemy, "global_position", target_pos, fly_out_duration)
		fly_tween.set_trans(Tween.TRANS_SINE)
		fly_tween.set_ease(Tween.EASE_OUT)
		await fly_tween.finished

	# Fade-out portal
	var fade_out_tween = portal.create_tween()
	fade_out_tween.tween_property(portal, "modulate:a", 0.0, portal_despawn)
	fade_out_tween.set_trans(Tween.TRANS_SINE)
	fade_out_tween.set_ease(Tween.EASE_OUT)
	await fade_out_tween.finished

	# Remove portal container
	container.queue_free()
