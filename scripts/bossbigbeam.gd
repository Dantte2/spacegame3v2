extends Node2D

@onready var anim = $AnimationPlayer
@onready var beam_fx = $BeamFX   # Sprite2D

func _ready():
	# BeamFX starts invisible
	beam_fx.modulate.a = 0.0

func fire_beam():
	# Play beam start animation
	anim.play("beamstart")

func stop_beam():
	# Fade out FX and play beam end animation
	fade_fx_out()
	anim.play("beamend")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "beamstart":
		# Start looping middle beam
		anim.play("beamloop")

		# Show BeamFX ONLY during loop
		beam_fx.modulate.a = 0.0
		fade_fx_in()

		# Stop beam after 2 seconds
		stop_beam_delayed(2.0)

	elif anim_name == "beamloop":
		pass

	elif anim_name == "beamend":
		# Hide everything after end
		hide()

func stop_beam_delayed(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	stop_beam()

func fade_fx_in():
	var tween := create_tween()
	tween.tween_property(beam_fx, "modulate:a", 1.0, 0.15)

func fade_fx_out():
	var tween := create_tween()
	tween.tween_property(beam_fx, "modulate:a", 0.0, 0.15)
