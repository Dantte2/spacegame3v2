extends ParallaxBackground

@export var speed: Vector2 = Vector2(150, 0)

func _process(delta: float) -> void:
    scroll_offset -= speed * delta
