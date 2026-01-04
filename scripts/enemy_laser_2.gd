extends Area2D

# -----------------------------
# Bullet settings
# -----------------------------
@export var speed: float = 900.0
@export var damage_to_shield: int = 200
@export var damage_to_health: int = 1

@export var lifetime: float = 4.0
@export var min_flight_distance: float = 1100
@export var random_explode_chance: float = 0.05  # chance per frame after min distance
@export var flakboom_scene: PackedScene

# -----------------------------
# Movement
# -----------------------------
var velocity: Vector2 = Vector2.ZERO
var start_position: Vector2
var timer := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var trail: GPUParticles2D = $Trail

func _ready():
    start_position = global_position

    if sprite:
        sprite.play()
        fade_out_visuals()

    collision_layer = 2
    collision_mask = 1

    connect("area_entered", Callable(self, "_on_area_entered"))
    connect("body_entered", Callable(self, "_on_body_entered"))

# ============================================================
# Fade visuals over time
# ============================================================
func fade_out_visuals():
    await get_tree().create_timer(0.7).timeout

    if sprite:
        sprite.visible = false

    if trail:
        trail.emitting = false

# ============================================================
# Physics / movement
# ============================================================
func _physics_process(delta):
    position += velocity * delta
    timer += delta

    # Random explosion after min flight distance
    if global_position.distance_to(start_position) >= min_flight_distance:
        if randf() < random_explode_chance:
            explode()
            return

    # Lifetime end
    if timer >= lifetime:
        explode()

# ============================================================
# Collisions
# ============================================================
func _on_area_entered(area):
    _handle_hit(area)
    explode()

func _on_body_entered(body):
    _handle_hit(body)
    explode()

# ============================================================
# DAMAGE
# ============================================================
func _handle_hit(target):
    var player = target
    while player and not player.has_method("take_damage"):
        player = player.get_parent()

    if not player:
        return

    if player.shield > 0:
        player.apply_shield_damage(damage_to_shield, global_position)
    else:
        player.take_damage(damage_to_health)

# ============================================================
# EXPLOSION
# ============================================================
func explode():
    if flakboom_scene:
        var boom = flakboom_scene.instantiate()
        # Small random offset so explosions aren't perfectly stacked
        var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
        boom.global_position = global_position + offset
        get_tree().current_scene.call_deferred("add_child", boom)

    queue_free()
