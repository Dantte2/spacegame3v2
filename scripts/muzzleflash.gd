extends Node2D

@export var duration := 0.1   # how long flash exists

func _ready():
	# Increase brightness before playing animation
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.modulate = Color(2.523, 1.822, 0.0, 1.0)  # brighten flash
		$AnimatedSprite2D.play("balls")   # play your animation

	# remove after short time
	await get_tree().create_timer(duration).timeout
	queue_free()
