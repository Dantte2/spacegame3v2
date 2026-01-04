extends Node2D

@export var follow_target: Node2D

func _process(delta):
    if follow_target and follow_target.is_inside_tree():
        global_position = follow_target.global_position
    else:
        queue_free()
