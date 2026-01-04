extends Area2D

@export var speed: float = 850.0
@export var damage_to_shield: int = 100
@export var damage_to_health: int = 1
var velocity: Vector2 = Vector2.RIGHT

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
    randomize()
    
    # Randomize starting frame
    if sprite:
        var total_frames = sprite.sprite_frames.get_frame_count(sprite.animation)
        sprite.frame = randi() % total_frames
        sprite.play()
        # Tint the sprite red
        sprite.modulate = Color(1, 0.1, 0.1)

    # Collision layers
    collision_layer = 2  # bullet
    collision_mask = 1   # collides with player only

    connect("area_entered", Callable(self, "_on_area_entered"))
    connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta):
    position -= velocity * speed * delta

func _on_area_entered(area):
    _handle_hit(area)

func _on_body_entered(body):
    _handle_hit(body)

func _handle_hit(target):
    # find player script in parent chain
    var player = target
    while player and not player.has_method("take_damage"):
        player = player.get_parent()
    if not player:
        return

    if player.shield > 0:
        player.apply_shield_damage(damage_to_shield, global_position)
    else:
        player.take_damage(damage_to_health)

    queue_free()
