extends CharacterBody3D

const MAX_SPEED = 20.0
const ACCELERATION = 10.0
const DECELERATION = 8.0
const TURN_SPEED = 2.0  # vitesse de rotation (rad/s)
const MAX_REVERSE_SPEED = -10.0
var speed = 0.0


func _physics_process(delta):
	Global.player = self
	Global.pathCam = $pathFollow3D
	var accelerating = Input.is_action_pressed("ui_up")
	var braking = Input.is_action_pressed("ui_down")
	var turning_left = Input.is_action_pressed("ui_left")
	var turning_right = Input.is_action_pressed("ui_right")

	# Accélération et freinage
	if accelerating:
		speed += ACCELERATION * delta
	elif braking:
		speed -= DECELERATION * delta
	else:
		if speed > 0:
			speed -= DECELERATION * delta
		elif speed < 0:
			speed += DECELERATION * delta

	speed = clamp(speed, MAX_REVERSE_SPEED, MAX_SPEED)

	# Rotation (tourner seulement si on bouge)
	if speed != 0:
		var direction = 0
		if turning_left:
			direction = 1
		elif turning_right:
			direction = -1
		rotation.y += direction * TURN_SPEED * delta * (speed / MAX_SPEED)

	# Calcul direction de déplacement
	var forward = -transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed

	# Gravité
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	else:
		velocity.y = 0

	# Appliquer mouvement avec détection du sol
	move_and_slide()
