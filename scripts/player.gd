extends CharacterBody2D

# =========================================================
#                       MOVEMENT
# =========================================================
@export var speed: float = 1000.0
@export var auto_speed: float = 1000.0

# =========================================================
#                       REFERENCES
# =========================================================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var exhaust: AnimatedSprite2D = $Exhaust
@onready var gunpoint: Node2D = $GunPoint
@onready var missile_point: Node2D = $MissilePoint
@onready var weapons: Node = $WeaponController

# =========================================================
#                       SHIELD SYSTEM
# =========================================================
@export var max_shield: float = 100000.0
var shield: float = max_shield
var shieldbar: TextureProgressBar
@onready var shield_sprite: Sprite2D = $ShieldArea/ShieldSprite

# =========================================================
#                       HEALTH SYSTEM
# =========================================================
@export var max_health: int = 100
var health: int = max_health
var healthbar: TextureProgressBar

# =========================================================
#                       READY
# =========================================================
func _ready() -> void:
	call_deferred("_init_ui")

func _init_ui() -> void:
	var current_scene = get_tree().current_scene
	if current_scene == null:
		push_error("❌ Current scene is null!")
		return

	# Shield bar
	shieldbar = current_scene.get_node_or_null("UI/ShieldBar")
	if shieldbar:
		shieldbar.max_value = max_shield
		shieldbar.value = shield
	else:
		push_error("❌ ShieldBar not found!")

	# Health bar
	healthbar = current_scene.get_node_or_null("UI/HealthBar")
	if healthbar:
		healthbar.max_value = max_health
		healthbar.value = health
	else:
		push_error("❌ HealthBar not found!")

# =========================================================
#                       PHYSICS + INPUT (with smooth lerp)
# =========================================================
func _physics_process(_delta: float) -> void:
	var input_vector := Vector2.ZERO

	# --- Movement input ---
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1

	# Normalize and scale to speed if there’s input
	var target_velocity: Vector2 = Vector2.ZERO
	if input_vector.length() > 0:
		target_velocity = input_vector.normalized() * speed

	# --- Smoothly interpolate velocity with lerp ---
	# The 0.15 parameter controls smoothness (lower = floatier, higher = snappier)
	velocity = velocity.lerp(target_velocity, 0.15)
	move_and_slide()

	# --- Update visuals and handle weapons ---
	_update_visuals()
	_handle_weapon_input()


# =========================================================
#                       VISUALS
# =========================================================
func _update_visuals() -> void:
	# Sprite animation
	if velocity.y < 0:
		sprite.animation = "up"
	elif velocity.y > 0:
		sprite.animation = "down"
	else:
		sprite.animation = "normal"
	sprite.play()

	# Exhaust shader effects
	var speed_ratio: float = clamp(velocity.length() / speed, 0.0, 1.0)
	exhaust.animation = "move" if speed_ratio > 0 else "normal"
	exhaust.material.set("shader_parameter/glow_strength", lerp(1.0, 2.5, speed_ratio))
	exhaust.material.set("shader_parameter/pulse_amount", speed_ratio * 0.5)
	exhaust.material.set("shader_parameter/time", Time.get_ticks_msec() / 1000.0)
	exhaust.material.set("shader_parameter/heat_intensity", lerp(0.02, 0.08, speed_ratio))
	exhaust.scale.x = lerp(1.0, 1.8, speed_ratio)
	exhaust.scale.y = lerp(1.0, 0.8, speed_ratio)

	# Gun / missile offset
	var offset := 0
	if velocity.y < 0:
		offset = -3
	elif velocity.y > 0:
		offset = 4
	gunpoint.position.y = offset
	missile_point.position.y = offset

# =========================================================
#                       WEAPON INPUT
# =========================================================
func _handle_weapon_input() -> void:
	if weapons == null:
		return

	if Input.is_action_pressed("shoot"):
		weapons.try_shoot()

	if Input.is_action_pressed("fire_missile"):
		weapons.try_missile()

	if Input.is_action_pressed("fire_super"):
		weapons.try_super()

# =========================================================
#                       SHIELD LOGIC
# =========================================================
func apply_shield_damage(amount: float, hit_pos: Vector2) -> void:
	if shield > 0:
		shield -= amount
		shield = max(shield, 0)
		_update_shieldbar()
		_show_shield_hit(hit_pos)

		if shield <= 0:
			_break_shield()
	else:
		take_damage(amount)

func _update_shieldbar() -> void:
	if shieldbar:
		shieldbar.value = shield

func _show_shield_hit(hit_global_pos: Vector2) -> void:
	if not shield_sprite or not shield_sprite.material:
		return

	var mat: ShaderMaterial = shield_sprite.material
	var local = shield_sprite.to_local(hit_global_pos)
	var uv = (local / shield_sprite.texture.get_size()) + Vector2(0.5, 0.5)

	mat.set_shader_parameter("hit_uv", uv)
	mat.set_shader_parameter("hit_strength", 1.0)
	_animate_shield_hit(mat)

func _animate_shield_hit(mat: ShaderMaterial) -> void:
	var duration := 0.2
	var timer := 0.0
	while timer < duration:
		await get_tree().process_frame
		timer += get_process_delta_time()
		mat.set_shader_parameter("hit_strength", 1.0 - (timer / duration))
	mat.set_shader_parameter("hit_strength", 0.0)

func _break_shield() -> void:
	$ShieldArea.set_deferred("collision_layer", 0)
	$ShieldArea.set_deferred("collision_mask", 0)
	$ShieldArea.set_deferred("monitoring", true)

	if shield_sprite and shield_sprite.material:
		shield_sprite.show()
		var mat: ShaderMaterial = shield_sprite.material
		mat.set_shader_parameter("break_strength", 0.0)
		var tween = create_tween()
		tween.tween_property(mat, "shader_parameter/break_strength", 1.0, 0.5)
		tween.tween_callback(shield_sprite.hide)

# =========================================================
#                       HEALTH LOGIC
# =========================================================
func take_damage(amount: int) -> void:
	health -= amount
	health = max(health, 0)
	_update_healthbar()
	if health <= 0:
		die()

func _update_healthbar() -> void:
	if healthbar:
		healthbar.value = health

func die() -> void:
	queue_free()
