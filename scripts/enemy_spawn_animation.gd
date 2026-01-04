extends Node2D

@export var spawn_delay: float = 0.5
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var enemy_node: Node = null  # reference to the enemy

func _ready():
	anim_sprite.play()
	spawn_enemy_after_delay()

func spawn_enemy_after_delay():
	await get_tree().create_timer(spawn_delay).timeout
	if enemy_node:
		enemy_node.visible = true
		enemy_node.set_process(true)
		enemy_node.set_physics_process(true)
	queue_free()  # remove spawn animation
