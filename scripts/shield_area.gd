extends Area2D

@onready var shield_sprite: Sprite2D = $ShieldSprite

func _ready():
    monitoring = true
    connect("area_entered", Callable(self, "_on_area_entered"))
    print("Shield ready, Layer:", collision_layer, "Mask:", collision_mask)

func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group("enemy_bullet"):
        print("Shield hit! Projectile:", area.name)
        
        # Map bullet position to shader UV
        var local_pos = shield_sprite.to_local(area.global_position)
        
        # Convert to 0-1 UV space (assuming CENTER pivot)
        var uv = local_pos / shield_sprite.texture.get_size() + Vector2(0.5, 0.5)
        
        # Trigger shader hit effect
        if shield_sprite.material:
            shield_sprite.material.set("shader_parameter/hit_uv", uv)
            shield_sprite.material.set("shader_parameter/hit_strength", 1.0)
            shield_sprite.material.set("shader_parameter/hit_radius", 0.1) # optional radius
        
        # Notify Player to apply shield damage
        var player = get_parent()
        if player.has_method("apply_shield_damage"):
            player.apply_shield_damage(10, area.global_position)
        
        # Remove bullet
        area.queue_free()
