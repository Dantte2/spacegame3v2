extends Line2D

@export_category('Trail')
@export var length: int = 10

@onready var parent: Node2D = get_parent()
var offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	offset = position
	top_level = true

	# --- HDR Gradient with "hot tip" effect ---
	var g := Gradient.new()
	g.colors = [
		Color(2.532, 0.693, 0.0, 1.0),   # Newest point, extra bright tip
		Color(1.166, 0.812, 0.0, 0.761), # Middle of trail
		Color(1.98, 1.43, 0.396, 0.0)  # Oldest point, fully transparent
	]
	g.offsets = [0.0, 0.5, 1.0]
	gradient = g

func _physics_process(_delta: float) -> void:
	global_position = Vector2.ZERO

	var point: Vector2 = parent.global_position + offset
	add_point(point, 0)

	if get_point_count() > length:
		remove_point(get_point_count() - 1)
