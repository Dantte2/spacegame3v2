extends CharacterBody2D

# --- Laser Variables ---
@export var fire_time := 1.2      # how long the laser stays on
@export var cooldown_time := 1.5  # time between shots
@export var rotation_speed := 5.0 # how fast the laser turns toward the player

@onready var laser := $BulletSpawn/LaserBeam2D
@onready var bullet_spawn := $BulletSpawn

# --- Health System ---
@export var max_health: float = 100.0
var health: float = max_health
@export var death_animation_scene: PackedScene
var running := true

# --- References ---e
var player: Node2D

func _ready() -> void:
    # Find the player in the scene
    var players = get_tree().get_nodes_in_group("player_body")
    if players.size() > 0:
        player = players[0]

    # Make sure laser starts off
    laser.is_casting = false

    # Start firing loop
    loop()


func _exit_tree() -> void:
    running = false


func _physics_process(delta: float) -> void:
    # If laser is firing, continuously rotate toward player
    if player and laser.is_casting:
        aim_at_player(delta)


func loop() -> void:
    await get_tree().process_frame

    while running:
        if player:
            aim_at_player(0.2)  # small initial rotation speed

        # Fire laser
        laser.is_casting = true
        await get_tree().create_timer(fire_time).timeout

        # Stop laser
        laser.is_casting = false
        await get_tree().create_timer(cooldown_time).timeout


func aim_at_player(delta: float) -> void:
    if not player:
        return

    # Direction toward player
    var target_dir = (player.global_position - global_position).angle()

    # Smooth rotation using lerp_angle
    bullet_spawn.rotation = lerp_angle(bullet_spawn.rotation, target_dir, rotation_speed * delta)


# ============================================================
#                   Health / Damage System
# ============================================================

func take_damage(amount: float) -> void:
    if health <= 0:
        return  # already dead

    health -= amount
    health = max(health, 0)
    print("Enemy health:", health)

    if health <= 0:
        die()


func die() -> void:
    running = false  # stop laser loop

    # Optional death animation
    if death_animation_scene:
        var anim = death_animation_scene.instantiate()
        anim.global_position = global_position
        get_tree().get_root().call_deferred("add_child", anim)

    queue_free()  # remove enemy from scene
