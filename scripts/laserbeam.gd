extends Area2D

@export var beam_length := 400.0   # Length of the beam
@export var width := 8.0           # Optional, for collisions

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D

func _ready():
    sprite.play("laser")  # or whatever animation

func set_beam(length):
    # Stretch sprite and collision to length
    sprite.scale.x = length / sprite.texture.get_width()
    if collider.shape is RectangleShape2D:
        collider.shape.extents.x = length / 2
