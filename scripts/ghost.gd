extends Node2D

@export var fade_time := 0.3
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
    # Start already semi-transparent
    sprite.modulate = Color(1, 1, 1, 0.3)
    
    var tween = create_tween()
    tween.tween_property(sprite, "modulate:a", 0.0, fade_time)
    tween.tween_callback(Callable(self, "queue_free"))
