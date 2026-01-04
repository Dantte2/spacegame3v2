extends Node2D

func _process(delta):
    # correct path to Sprite2D
    var sprite = $Sprite2D
    if sprite and sprite.material:
        var ratio = sprite.material.get_shader_parameter("ratio")
        ratio += delta * 0.2
        sprite.material.set_shader_parameter("ratio", ratio)
