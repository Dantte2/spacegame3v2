extends CharacterBody2D

@export var rise_height: float = 80.0
@export var rise_time: float = 0.3
@export var move_speed: float = 800.0

var target_position: Vector2
var _start_position: Vector2
var _rise_timer: float = 0.0
var _phase: int = 0
# 0 = rising, 1 = moving, 2 = arrived

# AnimatedSprite2D reference
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    _start_position = global_position

    # Play animation immediately
    if anim_sprite:
        anim_sprite.animation = "default"
        anim_sprite.play()

func set_target(pos: Vector2) -> void:
    target_position = pos

func _physics_process(delta: float) -> void:
    match _phase:
        0:
            _rise_phase(delta)
        1:
            _move_to_target(delta)

func _rise_phase(delta: float) -> void:
    _rise_timer += delta
    var t: float = clampf(_rise_timer / rise_time, 0.0, 1.0)

    # ease-out cubic
    var eased_t: float = 1.0 - ((1.0 - t) * (1.0 - t) * (1.0 - t))

    global_position.y = lerpf(
        _start_position.y,
        _start_position.y - rise_height,
        eased_t
    )

    if t >= 1.0:
        _phase = 1

func _move_to_target(delta: float) -> void:
    var dir: Vector2 = target_position - global_position
    var dist: float = dir.length()

    if dist < 5.0:
        global_position = target_position
        _phase = 2
        on_reached_target()
        return

    velocity = dir.normalized() * move_speed
    move_and_slide()

func on_reached_target() -> void:
    pass
