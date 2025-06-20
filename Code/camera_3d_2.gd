extends Camera3D

@export var target_path: NodePath
@export var distance = 5.0
@export var height = 2.0
@export var rotation_speed = 2.0
@export var return_speed = 70.0
@export var max_side_angle = 50.0  # Angle maximum en degrés

var target: Node3D
var current_side_angle = 0.0
var is_rotating = false

func _ready():
	if target_path != null and target_path != NodePath(""):
		target = get_node(target_path)
	set_as_top_level(true)

	
func _process(delta):
	
	if not target:
		return
	
	# Rotation manuelle avec input
	var rotation_input = Input.get_axis("camera_left", "camera_right")
	if abs(rotation_input) > 0.1:
		current_side_angle += -rotation_input * rotation_speed
		current_side_angle = clamp(current_side_angle, -max_side_angle, max_side_angle)
		is_rotating = true
	elif is_rotating:
		# Retour progressif à l'angle 0 quand le joueur relâche l'input
		current_side_angle = move_toward(current_side_angle, 0.0, return_speed * delta)
		if abs(current_side_angle) < 0.1:
			current_side_angle = 0.0
			is_rotating = false
	
	# Position de base derrière la cible
	var target_rotation = target.global_transform.basis.get_rotation_quaternion()
	var offset = Vector3(0, height, distance)
	
	# Application de l'angle latéral
	var side_rotation = Quaternion(Vector3.UP, deg_to_rad(current_side_angle))
	var final_rotation = target_rotation * side_rotation
	
	# Calcul de la position finale
	var desired_position = target.global_position + final_rotation * offset
	
	# Interpolation fluide
	global_position = global_position.lerp(desired_position, 10.0 * delta)
	look_at(target.global_position + Vector3(0, height * 0.5, 0), Vector3.UP)
