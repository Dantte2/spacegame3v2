extends Node2D

@export var mine_scene: PackedScene
@export var mine_spawns: Array[Node2D]
@export var drop_cooldown: float = 10.5        # seconds between waves
@export var stagger_delay: float = 0.50       # seconds between each mine drop

func _ready() -> void:
	if not mine_scene:
		push_error("MineDropper: mine_scene not set")
		return
	if mine_spawns.is_empty():
		push_error("MineDropper: mine_spawns empty")
		return

	# Start the repeating loop after node enters scene
	call_deferred("_mine_loop")

func _mine_loop() -> void:
	while is_inside_tree():
		await _drop_mines_staggered()
		await get_tree().create_timer(drop_cooldown).timeout

# Drop mines one by one with small delay
func _drop_mines_staggered() -> void:
	# Make a copy of the spawn points and shuffle it
	var shuffled_spawns = mine_spawns.duplicate()
	shuffled_spawns.shuffle()  # randomizes the order

	for spawn in shuffled_spawns:
		if not spawn:
			continue

		var mine = mine_scene.instantiate()
		mine.global_position = spawn.global_position
		mine.global_rotation = spawn.global_rotation
		get_tree().current_scene.add_child(mine)

		# Optional: debug
		print("Spawned mine at ", mine.global_position)

		await get_tree().create_timer(stagger_delay).timeout
