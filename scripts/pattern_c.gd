extends Node

# ====================
# EXPORTS
# ====================
@export var projectile_scene: PackedScene
@export var telegraph_scene: PackedScene
@export var rise_height: float = 80.0
@export var rise_time: float = 0.5
@export var move_speed: float = 800.0
@export var telegraph_duration: float = 0.5
@export var delay_before_fire: float = 0.5

@export var missiles_per_attack: int = 6        # number of missiles per volley
@export var volleys: int = 2                    # number of volleys
@export var delay_between_volleys: float = 2.0  # seconds between volleys

# Base target positions (world coordinates)
@export var base_positions: Array[Vector2]

# Missile spawn points
@export var spawn1_path: NodePath
@export var spawn2_path: NodePath

# ====================
# INTERNAL
# ====================
var spawn1: Node2D
var spawn2: Node2D
var _last_targets: Array[Vector2] = []

# ====================
# READY
# ====================
func _ready() -> void:
	if spawn1_path:
		spawn1 = get_node_or_null(spawn1_path)
	if spawn2_path:
		spawn2 = get_node_or_null(spawn2_path)
	if spawn1 == null or spawn2 == null:
		push_error("PatternC: Spawn points not assigned or not found!")

# ====================
# PUBLIC
# ====================
func start_pattern(_target: Node2D = null) -> void:
	for v in range(volleys):
		await fire_pattern()
		if v < volleys - 1:
			await get_tree().create_timer(delay_between_volleys).timeout

# ====================
# FIRE PATTERN
# ====================
func fire_pattern() -> void:
	if base_positions.size() < missiles_per_attack:
		push_error("Pattern C: Not enough target positions")
		return

	# Create a copy of base_positions and remove last used targets
	var choices = base_positions.duplicate()
	for t in _last_targets:
		if t in choices:
			choices.erase(t)

	# Fallback if not enough targets
	if choices.size() < missiles_per_attack:
		choices = base_positions.duplicate()

	# Shuffle and pick targets
	choices.shuffle()
	var targets: Array[Vector2] = []
	for i in range(missiles_per_attack):
		targets.append(choices[i])

	# Track used targets
	_last_targets = targets.duplicate()

	# Spawn telegraphs
	for t in targets:
		_spawn_telegraph(t)

	# Delay before firing
	await get_tree().create_timer(delay_before_fire).timeout

	# Fire missiles with small stagger
	for i in range(targets.size()):
		var spawn_pos = spawn1.global_position if i % 2 == 0 else spawn2.global_position
		_fire_projectile(spawn_pos, targets[i])
		await get_tree().create_timer(0.15).timeout

# ====================
# TELEGRAPH
# ====================
func _spawn_telegraph(world_position: Vector2) -> void:
	if telegraph_scene == null:
		return
	var tele = telegraph_scene.instantiate()
	tele.global_position = world_position
	tele.modulate = Color(1, 0, 0, 0.6)
	get_tree().current_scene.add_child(tele)
	if "duration" in tele:
		tele.duration = telegraph_duration

# ====================
# PROJECTILE
# ====================
func _fire_projectile(spawn_pos: Vector2, target_pos: Vector2) -> void:
	if projectile_scene == null:
		return
	var proj = projectile_scene.instantiate()
	proj.global_position = spawn_pos
	if "rise_height" in proj:
		proj.rise_height = rise_height
	if "rise_time" in proj:
		proj.rise_time = rise_time
	if "move_speed" in proj:
		proj.move_speed = move_speed
	if "set_target" in proj:
		proj.set_target(target_pos)
	get_tree().current_scene.add_child(proj)
