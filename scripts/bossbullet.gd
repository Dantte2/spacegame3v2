extends Area2D

@export var speed: float = 1600.0
@export var damage_to_shield: int = 1
@export var damage_to_health: int = 1
@export var lifetime: float = 3.0

var velocity: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	collision_layer = 2  # bullet
	collision_mask = 1   # collides with player only

	# Connect signals for collision like the working bullet
	area_entered.connect(Callable(self, "_on_area_entered"))
	body_entered.connect(Callable(self, "_on_body_entered"))

	# Destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	position += velocity * delta

func _on_area_entered(area):
	_handle_hit(area)

func _on_body_entered(body):
	_handle_hit(body)

func _handle_hit(target):
	var player = target
	while player:
		if player.has_method("take_damage"):
			break
		player = player.get_parent()

	if not player:
		return

	if "shield" in player and player.shield > 0 and player.has_method("apply_shield_damage"):
		player.apply_shield_damage(damage_to_shield, global_position)
	else:
		player.take_damage(damage_to_health)

	queue_free()
