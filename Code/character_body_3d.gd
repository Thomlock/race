extends CharacterBody3D

class_name Player


const MAX_SPEED = 20.0
const ACCELERATION = 10.0
const DECELERATION = 8.0
const TURN_SPEED = 2.0  # vitesse de rotation (rad/s)
const MAX_REVERSE_SPEED = -10.0
const JUMP_VELOCITY = 5
var speed = 0.0

func _ready() -> void:
	pass	

func _physics_process(delta: float) -> void:
	
	var accelerating = Input.is_action_pressed("ui_up")
	var braking = Input.is_action_pressed("ui_down")
	var turning_left = Input.is_action_pressed("ui_left")
	var turning_right = Input.is_action_pressed("ui_right")
	speed = clamp(speed, MAX_REVERSE_SPEED, MAX_SPEED)
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if accelerating:
		speed += ACCELERATION * delta
	elif braking:
		speed -= DECELERATION * delta * 2
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

	if $RayCast3D.is_colliding():
		var collision_normal = $RayCast3D.get_collision_normal()
		# On veut que l'axe "up" de la voiture corresponde à cette normale
		var current_forward = -transform.basis.z.normalized()
		
		# Calculer la base (orientation) en utilisant la normale comme up
		var new_basis = Basis()
		new_basis.y = collision_normal.normalized()
		new_basis.z = -current_forward
		new_basis.x = new_basis.y.cross(new_basis.z).normalized()
		new_basis.z = new_basis.x.cross(new_basis.y).normalized()

		transform.basis = new_basis



	# Calcul direction de déplacement
	var forward = -transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	move_and_slide()
