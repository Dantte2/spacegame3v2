extends Camera2D

@export var scroll_speed: float = 1000.0  # Fixed forward auto-scroll speed

func _process(delta):
    # Always move camera forward
    global_position.x += scroll_speed * delta
