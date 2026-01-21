extends Node2D

@export var bullet_scene: PackedScene
@export var cone_bullet_count: int = 7
@export var cone_angle_deg: float = 40.0
@export var cone_fire_delay: float = 2.5
@export var cone_bullet_color: Color = Color(0.823, 0.585, 1.0, 1.0)

@onready var coneshotspawn: Node2D = $ConeShotSpawn

func _ready() -> void:
	if not coneshotspawn:
		push_error("ConeShot: ConeShotSpawn node not found!")
		return
	if not bullet_scene:
		push_error("ConeShot: bullet_scene not set!")
		return
	start_cone_loop()

func start_cone_loop() -> void:
	call_deferred("_cone_loop")

func _cone_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(cone_fire_delay).timeout
		if not is_inside_tree():
			break
		fire_cone()

func fire_cone() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0 or not bullet_scene or not coneshotspawn:
		return

	var player = players[0]
	var base_dir = (player.global_position - coneshotspawn.global_position).normalized()
	var half_angle = deg_to_rad(cone_angle_deg * 0.5)

	for i in range(cone_bullet_count):
		var t = 0.0 if cone_bullet_count == 1 else float(i) / float(cone_bullet_count - 1)
		var angle = lerp(-half_angle, half_angle, t)
		var dir = base_dir.rotated(angle)

		var bullet = bullet_scene.instantiate()
		bullet.global_position = coneshotspawn.global_position
		bullet.velocity = dir
		bullet.bullet_color = cone_bullet_color
		get_tree().current_scene.add_child(bullet)
