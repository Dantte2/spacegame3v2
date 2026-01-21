extends Node2D

@export var duration: float = 0.5 # How long the telegraph is visible

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
    # Just wait for the duration, then remove the telegraph
    await get_tree().create_timer(duration).timeout
    queue_free()
