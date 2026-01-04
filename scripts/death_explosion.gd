extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var lifetime: float = 0.5  # fallback in seconds

# Keep track of time for shader
var shader_time := 0.0

func _ready():
    if sprite:
        # Randomize animation speed
        sprite.speed_scale = randf_range(0.8, 1.2)
        
        # Randomize rotation
        rotation = randf_range(0, TAU)
        
        # Randomize scale
        var random_scale = randf_range(0.8, 1.3)
        scale = Vector2.ONE * random_scale
        
        # Small position jitter
        position += Vector2(randf_range(-4, 4), randf_range(-4, 4))

        # Play animation
        sprite.play()

        # Calculate animation length
        var anim_length = lifetime
        var frames = sprite.sprite_frames
        if frames and frames.has_animation(sprite.animation):
            var frame_count = frames.get_frame_count(sprite.animation)
            var fps = frames.get_animation_speed(sprite.animation)
            if fps > 0:
                anim_length = frame_count / fps / sprite.speed_scale

        await get_tree().create_timer(anim_length).timeout

    queue_free()

func _process(delta):
    shader_time += delta  # increment time each frame
    if sprite.material and sprite.material.shader:
        sprite.material.set_shader_parameter("time", shader_time)
