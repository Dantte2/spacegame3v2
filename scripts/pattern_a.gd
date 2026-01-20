extends Node2D

# ====================
# EXPORTS
# ====================
@export var missile_scene: PackedScene
@export var laser_scene: PackedScene

@export var missile_count: int = 6
@export var missile_delay: float = 0.2
@export var laser_waves: int = 3
@export var lasers_per_wave: int = 5
@export var laser_warning_time: float = 0.5
@export var laser_duration: float = 2.0
@export var laser_wave_delay: float = 0.3
@export var pattern_a_move_speed: float = 900.0  # speed for moving boss

# Instead of using $ paths, assign these in the inspector
@export var missile_spawns: Array[Node2D]
@export var muzzle_flash: AnimatedSprite2D
@export var boss_node: NodePath  # assign your boss CharacterBody2D here

# ====================
# FUNCTIONS
# ====================
func start_pattern(player: Node2D) -> void:
    if not boss_node:
        push_error("PatternA: boss_node not set!")
        return
    var boss = get_node(boss_node)

    # Move boss to middle Y
    var middle_y = 500.0  # or calculate based on limits
    await move_boss_to_y(boss, middle_y)

    # Then fire
    await fire_missiles(player)
    await fire_lasers()

func move_boss_to_y(boss: Node2D, target_y: float) -> void:
    while abs(boss.global_position.y - target_y) > 1.0:
        var diff = target_y - boss.global_position.y
        var move_amount = min(abs(diff), pattern_a_move_speed * get_process_delta_time())
        boss.global_position.y += sign(diff) * move_amount
        await get_tree().process_frame
    boss.global_position.y = target_y

func fire_missiles(target: Node2D) -> void:
    if missile_scene == null or missile_spawns.size() == 0:
        push_error("PatternA: missile_scene or missile_spawns not set!")
        return

    for i in range(missile_count):
        var spawn = missile_spawns[i % missile_spawns.size()]
        var missile = missile_scene.instantiate()
        missile.global_position = spawn.global_position
        missile.global_rotation = -PI / 2
        if missile.has_method("set_target"):
            missile.set_target(target)
        get_tree().current_scene.add_child(missile)

        if muzzle_flash:
            var flash = muzzle_flash.duplicate()
            flash.global_position = spawn.global_position
            flash.visible = true
            get_tree().current_scene.add_child(flash)
            flash.play()
            flash.animation_finished.connect(Callable(flash, "queue_free"))

        await get_tree().create_timer(missile_delay).timeout

func fire_lasers() -> void:
    if laser_scene == null:
        push_error("PatternA: laser_scene not set!")
        return

    for wave in range(laser_waves):
        var players = get_tree().get_nodes_in_group("player")
        var player_x = players[0].global_position.x if players.size() > 0 else 0.0
        var tracking_index = randi() % lasers_per_wave

        for i in range(lasers_per_wave):
            var laser = laser_scene.instantiate()
            laser.position.x = player_x if i == tracking_index else randf_range(100, 1200)
            laser.position.y = 0
            get_tree().current_scene.add_child(laser)
            if laser.has_method("start_telegraph"):
                laser.start_telegraph(laser_warning_time, laser_duration)

        await get_tree().create_timer(laser_warning_time + laser_duration).timeout
        if wave < laser_waves - 1:
            await get_tree().create_timer(laser_wave_delay).timeout
