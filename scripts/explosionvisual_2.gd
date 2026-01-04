extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var lifetime: float = 0.5  # fallback in seconds

func _ready():
    if sprite:
        sprite.play()  # start the default animation

        var anim_length = lifetime
        var frames = sprite.sprite_frames
        if frames and frames.has_animation(sprite.animation):
            var frame_count = frames.get_frame_count(sprite.animation)
            var fps = frames.get_animation_speed(sprite.animation)
            if fps > 0:
                anim_length = frame_count / fps

        await get_tree().create_timer(anim_length).timeout

    queue_free()
