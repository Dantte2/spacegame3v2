extends Sprite2D

@export var fade_speed: float = 3.0

func _process(delta):
    if material:
        var current_strength = material.get("shader_parameter/hit_strength")
        if current_strength > 0:
            material.set("shader_parameter/hit_strength", max(current_strength - fade_speed * delta, 0))

# Call this from your shield area when a projectile hits
func trigger_hit(uv_position: Vector2, strength: float = 1.0, radius: float = 0.15):
    if material:
        material.set("shader_parameter/hit_uv", uv_position)
        material.set("shader_parameter/hit_strength", strength)
        material.set("shader_parameter/hit_radius", radius)
