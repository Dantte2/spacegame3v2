extends Node2D

@export var beam_b_scene: PackedScene
@export var bulletspawn: Node2D

@export var pattern_b_move_speed: float = 900.0
@export var pattern_b_pause: float = 0.25
@export var pattern_b_y_min: float = 100.0
@export var pattern_b_y_max: float = 600.0
@export var pattern_b_repeat: int = 2
@export var pattern_b_cooldown: float = 2.5

# Reference to the boss node (CharacterBody2D) that should move
@export var boss_node: NodePath

func start_pattern() -> void:
	await run_pattern()

func run_pattern() -> void:
	if not boss_node:
		push_error("PatternB: boss_node not assigned!")
		return

	var boss = get_node(boss_node)
	var middle_y = (pattern_b_y_min + pattern_b_y_max) * 0.5

	for i in range(pattern_b_repeat):
		var players = get_tree().get_nodes_in_group("player")
		var target_y = players[0].global_position.y if players.size() > 0 else middle_y

		await move_boss_to_y(boss, target_y)
		await get_tree().create_timer(pattern_b_pause).timeout

		var beam = beam_b_scene.instantiate()
		beam.global_position = bulletspawn.global_position
		get_tree().current_scene.add_child(beam)

		if beam.has_node("AnimationPlayer"):
			await beam.get_node("AnimationPlayer").animation_finished
		else:
			await get_tree().create_timer(2.0).timeout

		if i < pattern_b_repeat - 1:
			await get_tree().create_timer(pattern_b_cooldown).timeout

# Moves the boss CharacterBody2D vertically
# Moves the boss CharacterBody2D vertically smoothly
func move_boss_to_y(boss: Node2D, target_y: float) -> void:
	var start_y = boss.global_position.y
	var distance = abs(target_y - start_y)
	if distance <= 0.0:
		return

	var duration: float = distance / pattern_b_move_speed
	var elapsed: float = 0.0

	while elapsed < duration:
		elapsed += get_process_delta_time()
		var t = min(elapsed / duration, 1.0)
		boss.global_position.y = lerp(start_y, target_y, t)
		await get_tree().process_frame

	boss.global_position.y = target_y
