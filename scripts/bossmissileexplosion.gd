extends Area2D

# ====================
# EXPORTS
# ====================
@export var damage_to_shield: int = 1
@export var damage_to_health: int = 1

# AnimatedSprite2D for visual
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    # Play animation and delete self when finished
    if anim_sprite:
        anim_sprite.animation = "default"
        anim_sprite.play()
        anim_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))

    # Detect bodies immediately
    connect("body_entered", Callable(self, "_on_body_entered"))
    connect("area_entered", Callable(self, "_on_area_entered"))

func _on_animation_finished() -> void:
    queue_free()

func _on_body_entered(body: Node) -> void:
    _apply_damage(body)

func _on_area_entered(area: Node) -> void:
    _apply_damage(area)

func _apply_damage(target: Node) -> void:
    # Walk up the parent chain to find a node with damage methods
    var obj: Node = target
    while obj and not obj.has_method("take_damage") and not obj.has_method("apply_shield_damage"):
        obj = obj.get_parent()
    if not obj:
        return

    # Apply shield damage first if possible
    if "shield" in obj and obj.shield > 0 and obj.has_method("apply_shield_damage"):
        obj.apply_shield_damage(damage_to_shield, global_position)
    # Otherwise apply health damage
    elif obj.has_method("take_damage"):
        obj.take_damage(damage_to_health)
