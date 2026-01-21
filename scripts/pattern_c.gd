extends Node

# ====================
# EXPORTS
# ====================
@export var projectile_scene: PackedScene
@export var telegraph_scene: PackedScene
@export var rise_height: float = 80.0
@export var rise_time: float = 0.3
@export var move_speed: float = 800.0
@export var telegraph_duration: float = 0.5
@export var delay_before_fire: float = 0.5
@export var explosion_random_radius: float = 20.0  # random offset for missiles
@export var missiles_per_attack: int = 4  # number of missiles per pattern

# Base target positions
@export var base_positions: Array[Vector2] = [
    Vector2(350, 185),
    Vector2(350, 535),
    Vector2(350, 885),
    Vector2(585, 225),
    Vector2(735, 525),
    Vector2(501, 877)
]

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
@export var volleys: int = 2          # number of times to fire the pattern
@export var delay_between_volleys: float = 1.0  # seconds between volleys

func start_pattern(_target: Node2D = null) -> void:
    for v in range(volleys):
        await fire_pattern()
        # Delay before next volley, unless it’s the last one
        if v < volleys - 1:
            await get_tree().create_timer(delay_between_volleys).timeout

# ====================
# FIRE PATTERN
# ====================
func fire_pattern() -> void:
    if base_positions.size() < missiles_per_attack:
        push_error("Pattern C: Not enough target positions")
        return

    # Build a pool of targets with small random offsets
    var pool: Array[Vector2] = []
    for pos in base_positions:
        # Add 3 variations around each base position
        for i in range(3):
            var offset = Vector2(
                randf() * explosion_random_radius * 2 - explosion_random_radius,
                randf() * explosion_random_radius * 2 - explosion_random_radius
            )
            pool.append(pos + offset)

    # Remove last used targets
    var choices = pool.duplicate()
    for t in _last_targets:
        if t in choices:
            choices.erase(t)

    # Fallback if not enough targets
    if choices.size() < missiles_per_attack:
        choices = pool.duplicate()

    # Shuffle and pick
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

    # Fire missiles with stagger
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
        proj.set_target(target_pos)  # each missile has its own copy of the target
    get_tree().current_scene.add_child(proj)
