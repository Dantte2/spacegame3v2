extends Area2D

# -----------------------------
# Explosion stats
# -----------------------------
@export var lifetime: float = 0.5
@export var damage_to_shield: int = 100
@export var damage_to_health: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Track which targets have already been hit
var hit_targets := []

func _ready():
    if sprite:
        sprite.play("pink")
        sprite.rotation = randf_range(0, TAU)  # random rotation


    # Collision layers (same as bullet)
    collision_layer = 2
    collision_mask = 1

    # Connect signals to catch bodies/areas entering the explosion
    connect("area_entered", Callable(self, "_on_area_entered"))
    connect("body_entered", Callable(self, "_on_body_entered"))

    # Optional: destroy itself after lifetime
    await get_tree().create_timer(lifetime).timeout
    queue_free()


func _physics_process(_delta):
    # Check for any targets already overlapping each frame
    for target in get_overlapping_bodies() + get_overlapping_areas():
        if target not in hit_targets:
            _handle_hit(target)
            hit_targets.append(target)


func _on_area_entered(area):
    if area not in hit_targets:
        _handle_hit(area)
        hit_targets.append(area)

func _on_body_entered(body):
    if body not in hit_targets:
        _handle_hit(body)
        hit_targets.append(body)


func _handle_hit(target):
    # Walk up parent chain until we find player with take_damage
    var player = target
    while player and not player.has_method("take_damage"):
        player = player.get_parent()
    if not player:
        return

    # Apply shield or health damage exactly like bullet
    if player.shield > 0 and player.has_method("apply_shield_damage"):
        player.apply_shield_damage(damage_to_shield, global_position)
    else:
        player.take_damage(damage_to_health)
