extends CharacterBody2D

# ====================
# EXPORTS
# ====================
@export var base_speed: float = 100.0      # starting speed
@export var max_speed: float = 600.0       # max speed it can accelerate to
@export var acceleration: float = 50.0     # how fast it accelerates
@export var turn_speed: float = 2.0        # how fast it turns toward target (radians/sec)
@export var damage_to_health: int = 1
@export var damage_to_shield: int = 1

# ====================
# INTERNAL
# ====================
var current_speed: float

@onready var sprite: Node = $Sprite2D

func _ready() -> void:
    current_speed = base_speed
    
    # Play sprite animation if AnimatedSprite2D
    if sprite and sprite is AnimatedSprite2D:
        sprite.play()
    
    # Collision layers
    collision_layer = 2   # bullet/mine layer
    collision_mask = 1    # collides with player

    # Connect signals
    connect("body_entered", Callable(self, "_on_body_entered"))
    connect("area_entered", Callable(self, "_on_area_entered"))

func _physics_process(delta: float) -> void:
    # Find closest player from the group
    var players = get_tree().get_nodes_in_group("Player")
    if players.empty():
        return
    
    var closest_player: Node2D = null
    var min_dist = 1e9
    for p in players:
        if not p is Node2D:
            continue
        var d = global_position.distance_to(p.global_position)
        if d < min_dist:
            min_dist = d
            closest_player = p
    
    if not closest_player:
        return
    
    # direction to target
    var dir = (closest_player.global_position - global_position).normalized()
    
    # Smoothly rotate velocity toward target
    if velocity.length() > 0:
        var angle_diff = velocity.angle_to(dir)
        var turn = clamp(angle_diff, -turn_speed * delta, turn_speed * delta)
        velocity = velocity.rotated(turn)
    else:
        velocity = dir
    
    # accelerate
    current_speed = min(current_speed + acceleration * delta, max_speed)
    
    # move
    velocity = velocity.normalized() * current_speed
    move_and_slide()

# ====================
# COLLISION HANDLING
# ====================
func _on_body_entered(body: Node) -> void:
    _handle_hit(body)

func _on_area_entered(area: Node) -> void:
    _handle_hit(area)

func _handle_hit(target: Node) -> void:
    # climb parent chain to find take_damage method
    var obj = target
    while obj and not obj.has_method("take_damage"):
        obj = obj.get_parent()
    if not obj:
        return
    
    # Apply damage
    if "shield" in obj and obj.shield > 0:
        if obj.has_method("apply_shield_damage"):
            obj.apply_shield_damage(damage_to_shield, global_position)
    else:
        obj.take_damage(damage_to_health)
    
    queue_free()
