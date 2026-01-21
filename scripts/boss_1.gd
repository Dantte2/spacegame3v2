extends CharacterBody2D

# ====================
# EXPORTS
# ====================
@export var force_pattern: int = -1 # -1 = normal cycle, 0 = Pattern A, 1 = Pattern B, 2 = Pattern C
@export var fire_rate: float = 5.0

# ====================
# NODES
# ====================
@onready var pattern_a_node = $Scripts/PatternA
@onready var pattern_b_node = $Scripts/PatternB
@onready var pattern_c_node = $Scripts/PatternC  
@onready var coneshot_node = $Scripts/ConeShot
@onready var exhaust: AnimatedSprite2D = $exhaust

# ====================
# INTERNAL
# ====================
var fire_timer := 0.0
var attacking := false
var pattern_index := 0

# ====================
# READY
# ====================
func _ready() -> void:
    randomize()
    if exhaust:
        exhaust.visible = true
        exhaust.play("default")

# ====================
# PROCESS
# ====================
func _process(delta: float) -> void:
    if attacking:
        return

    fire_timer -= delta
    if fire_timer <= 0.0:
        var player = get_player()
        if player:
            start_attack(player)
        fire_timer = fire_rate

# ====================
# PLAYER HELPER
# ====================
func get_player() -> Node2D:
    var players = get_tree().get_nodes_in_group("player")
    return players[0] if players.size() > 0 else null

# ====================
# ATTACK CONTROL
# ====================
func start_attack(target: Node2D) -> void:
    if attacking:
        return

    attacking = true

    var pattern_to_run = force_pattern if force_pattern >= 0 else pattern_index
    match pattern_to_run:
        0:
            if pattern_a_node:
                await pattern_a_node.start_pattern(target)
        1:
            if pattern_b_node:
                await pattern_b_node.start_pattern()
        2:
            if pattern_c_node:
                await pattern_c_node.start_pattern(target)  

    if force_pattern < 0:
        pattern_index = (pattern_index + 1) % 3  

    attacking = false
