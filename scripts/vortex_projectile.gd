extends Node2D

@export var speed := 600.0
@export var explode_delay := 0.5
@export var vortex_scene: PackedScene  # assign in inspector

var velocity := Vector2.ZERO
var triggered := false

func _ready():
    velocity = Vector2.RIGHT.rotated(rotation)
    $Timer.stop()
    
    # Connect signals (Godot 4)
    $Area2D.body_entered.connect(_on_body_entered)
    $Timer.timeout.connect(_on_Timer_timeout)

func _process(delta):
    position += velocity * speed * delta

func _on_body_entered(body):
    if body.is_in_group("enemy") and not triggered:
        triggered = true
        $Timer.start(explode_delay)

func _on_Timer_timeout():
    explode()

func explode():
    if vortex_scene:
        var vortex = vortex_scene.instantiate()
        vortex.global_position = global_position
        get_tree().current_scene.add_child(vortex)
    queue_free()
