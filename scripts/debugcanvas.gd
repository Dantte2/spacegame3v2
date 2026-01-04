extends CanvasLayer

# --- Existing enemy stuff ---
@export var enemy_scene: PackedScene
@export var spawn_position: Vector2 = Vector2(400, 300)
@export var vertical_spacing: float = 80.0
@export var enemies_per_press: int = 4

# --- New player reference for shield testing ---
@export var player_node: NodePath  # assign your Player node here in the editor

# --- Called when the "RespawnButton" is pressed ---
func _on_respawnbutton_pressed():
    if not enemy_scene:
        print("No enemy scene assigned!")
        return

    for i in range(enemies_per_press):
        var enemy = enemy_scene.instantiate()
        enemy.global_position = spawn_position + Vector2(0, i * vertical_spacing)
        get_tree().current_scene.add_child(enemy)

    print(enemies_per_press, " enemies spawned with spacing of ", vertical_spacing)

# --- New function: Called when the "DamageShieldButton" is pressed ---
func _on_damageshieldbutton_pressed():
    var player = get_node(player_node)
    if player:
        # deal 100 damage to shield at center
        var hit_pos = Vector2(0.5, 0.5)  # center UV
        player.apply_shield_damage(100, hit_pos)
        print("Dealt 100 damage to shield")
