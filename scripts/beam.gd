extends RayCast2D

@export var cast_speed := 7000.0
@export var max_length := 2300.0
@export var start_distance := 40.0
@export var growth_time := 0.1
@export var color := Color.WHITE: set = set_color
@export var is_casting := false: set = set_is_casting

# Damage values
@export var damage_to_shield := 2000.0      # damage per second to shield
@export var damage_to_health := 1.0      # damage per second to health

var tween: Tween = null

@onready var line_2d: Line2D = $Line2D
@onready var casting_particles: GPUParticles2D = $CastingParticles2D
@onready var collision_particles: GPUParticles2D = $CollisionParticles2D
@onready var beam_particles: GPUParticles2D = $BeamParticles2D

@onready var line_width := line_2d.width

func _ready() -> void:
    set_color(color)
    set_is_casting(is_casting)
    line_2d.points[0] = Vector2.RIGHT * start_distance
    line_2d.points[1] = Vector2.ZERO
    line_2d.visible = false
    casting_particles.position = line_2d.points[0]

    if not Engine.is_editor_hint():
        set_physics_process(false)

func _physics_process(delta: float) -> void:
    var target_pos := Vector2.RIGHT * max_length
    target_pos = target_pos.move_toward(Vector2.RIGHT * max_length, cast_speed * delta)
    
    var laser_end_position := target_pos
    target_position = laser_end_position
    force_raycast_update()

    var collided_body: Node = null

    if is_colliding():
        laser_end_position = to_local(get_collision_point())
        collision_particles.global_rotation = get_collision_normal().angle()
        collision_particles.position = laser_end_position
        collided_body = get_collider()

        # Apply continuous damage
        if collided_body and collided_body.is_in_group("player_body"):
            var player = collided_body
            while player and not player.has_method("take_damage"):
                player = player.get_parent()
            if player:
                if player.shield > 0:
                    player.apply_shield_damage(damage_to_shield * delta, global_position)
                else:
                    player.take_damage(damage_to_health * delta)

    line_2d.points[1] = laser_end_position

    var laser_start_position := line_2d.points[0]
    beam_particles.position = laser_start_position + (laser_end_position - laser_start_position) * 0.5
    beam_particles.process_material.emission_box_extents.x = laser_end_position.distance_to(laser_start_position) * 0.5

    collision_particles.emitting = is_colliding()


func set_is_casting(new_value: bool) -> void:
    if is_casting == new_value:
        return
    is_casting = new_value
    set_physics_process(is_casting)

    if beam_particles == null:
        return

    beam_particles.emitting = is_casting
    casting_particles.emitting = is_casting

    if is_casting:
        var laser_start := Vector2.RIGHT * start_distance
        line_2d.points[0] = laser_start
        line_2d.points[1] = laser_start
        casting_particles.position = laser_start
        appear()
    else:
        collision_particles.emitting = false
        disappear()


func appear() -> void:
    line_2d.visible = true
    if tween and tween.is_running():
        tween.kill()
    tween = create_tween()
    tween.tween_property(line_2d, "width", line_width, growth_time * 2.0).from(0.0)

func disappear() -> void:
    if tween and tween.is_running():
        tween.kill()
    tween = create_tween()
    tween.tween_property(line_2d, "width", 0.0, growth_time).from_current()
    tween.tween_callback(line_2d.hide)

func set_color(new_color: Color) -> void:
    color = new_color
    if line_2d == null:
        return
    line_2d.modulate = new_color
    casting_particles.modulate = new_color
    collision_particles.modulate = new_color
    beam_particles.modulate = new_color
