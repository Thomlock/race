extends SpringArm3D

@export var target: Node3D  # La voiture
@export var follow_speed := 5.0  # Suivi fluide

func _process(delta):
	if target:
		# Suivre la position
		global_position = target.global_position

		# Suivre la rotation Y de la voiture
		var target_rot_y = target.rotation.y
		rotation.y = lerp_angle(rotation.y, target_rot_y, follow_speed * delta)
