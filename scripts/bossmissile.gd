extends CharacterBody2D

@export var rise_height: float = 50.0       # how high it rises straight up
@export var rise_time: float = 0.3           # seconds to rise
@export var move_time: float = 1.0           # seconds to reach target
@export var explosion_scene: PackedScene

var target_position: Vector2
var _start_position: Vector2
var _apex_position: Vector2
var _phase: int = 0     # 0 = rising, 1 = arcing, 2 = done
var _rise_timer: float = 0.0
var _bezier_t: float = 0.0

func set_target(pos: Vector2) -> void:
    _start_position = global_position
    target_position = pos
    _apex_position = _start_position - Vector2(0, rise_height)
    _phase = 0
    _rise_timer = 0.0
    _bezier_t = 0.0

func _physics_process(delta: float) -> void:
    match _phase:
        0:
            _rise_phase(delta)
        1:
            _arc_phase(delta)

func _rise_phase(delta: float) -> void:
    _rise_timer += delta
    var t = clampf(_rise_timer / rise_time, 0.0, 1.0)
    # Smooth ease-out cubic
    var eased_t = 1.0 - pow(1.0 - t, 3)
    global_position.y = lerpf(_start_position.y, _apex_position.y, eased_t)
    
    if t >= 1.0:
        _phase = 1
        _bezier_t = 0.0

func _arc_phase(delta: float) -> void:
    _bezier_t += delta / move_time
    if _bezier_t >= 1.0:
        _bezier_t = 1.0
        _explode()
        return

    # Control point above midpoint for smooth arc
    var mid = (_apex_position + target_position) * 0.5
    var control = mid - Vector2(0, rise_height * 0.5)
    global_position = _quadratic_bezier(_apex_position, control, target_position, _bezier_t)

    # Rotate missile to face direction
    if _bezier_t < 1.0:
        var next_pos = _quadratic_bezier(_apex_position, control, target_position, _bezier_t + 0.01)
        rotation = (next_pos - global_position).angle()

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
    return (1-t)*(1-t)*p0 + 2*(1-t)*t*p1 + t*t*p2

func _explode() -> void:
    if explosion_scene:
        var expl = explosion_scene.instantiate()
        get_parent().add_child(expl)
        expl.global_position = global_position
    queue_free()
