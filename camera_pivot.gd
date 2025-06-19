extends Node3D  # à mettre sur CameraPivot

@export var target: Node3D  # le CharacterBody3D à suivre
@export var smooth_speed := 5.0  # vitesse de suivi (plus grand = plus rapide)

func _process(delta):
	if target:
		# Interpoler la position vers la position du joueur
		global_position = global_position.lerp(target.global_position, smooth_speed * delta)
