extends Area2D

# Damage amount of this explosion (if needed)
@export var damage: int = 10

# AnimatedSprite reference
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    # Play the default animation
    if anim_sprite:
        anim_sprite.animation = "default"
        anim_sprite.play()
        # Connect finished signal to delete itself
        anim_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))

    # Optionally, detect bodies for damage immediately
    connect("body_entered", Callable(self, "_on_body_entered"))

func _on_animation_finished() -> void:
    queue_free()

func _on_body_entered(body: Node) -> void:
    # Apply damage if the body has a health function
    if body.has_method("take_damage"):
        body.take_damage(damage)
