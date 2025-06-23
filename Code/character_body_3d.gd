extends CharacterBody3D

class_name Player

# Configuration générale
const ACCELERATION = 10.0
const DECELERATION = 8.0
const TURN_SPEED = 2.0
const MAX_REVERSE_SPEED = -10.0

const JUMP_VELOCITY = 5
const SLIP_FACTOR = 0.05

const DRIFT_THRESHOLD = 20.0
const DRIFT_DECAY = 10.0    

var MAX_SPEED = 20.0

const BOOST_DURATION = 1.0
const BOOST_MULTIPLIER = 2

# États internes
var speed = 0.0
var lateral_velocity := Vector3.ZERO
var is_boosting = false
var boost_timer = 0.0
var drift_power = 0.0



func _physics_process(delta: float) -> void:
	var accelerating = Input.is_action_pressed("ui_up")
	var braking = Input.is_action_pressed("ui_down")
	var turning_left = Input.is_action_pressed("ui_left")
	var turning_right = Input.is_action_pressed("ui_right")

	# Mise à jour de la vitesse longitudinale
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

	# Détecte si on tourne
	var direction = 0
	var is_turning = false
	if speed != 0:
		if turning_left:
			direction = 1
			is_turning = true
		elif turning_right:
			direction = -1
			is_turning = true
		rotation.y += direction * TURN_SPEED * delta * (abs(speed) / MAX_SPEED)

	var forward = -transform.basis.z.normalized()
	var right = transform.basis.x.normalized()
	var forward_velocity = forward * speed

	# Mise à jour de la glisse latérale
	lateral_velocity *= SLIP_FACTOR
	var slip_amount = 0.0

	if speed != 0:
		slip_amount = direction * TURN_SPEED * delta * (abs(speed) / MAX_SPEED) * 1000.0
		lateral_velocity += right * slip_amount

	# Accumule le drift uniquement si on tourne
	if is_turning:
		drift_power += abs(slip_amount) * 0.01
	else:
		# Quand on arrête de tourner, déclenche le boost si puissance suffisante
		if drift_power >= DRIFT_THRESHOLD and not is_boosting:
			is_boosting = true
			boost_timer = BOOST_DURATION
			drift_power = 0.0
		else:
			# Réduit la puissance si pas en train de tourner
			drift_power = clamp(drift_power - DRIFT_DECAY * delta, 0.0, 100.0)

	# Applique le boost
	if is_boosting:
		MAX_SPEED = 40
		forward_velocity *= BOOST_MULTIPLIER
	else:
		MAX_SPEED = 20

	# Application de la vélocité totale
	velocity.x = forward_velocity.x + lateral_velocity.x
	velocity.z = forward_velocity.z + lateral_velocity.z


	if not is_on_floor():
		velocity += get_gravity() * delta

	# Gestion du saut
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Alignement au sol (raycast)
	if $anglefloor.is_colliding():
		var normal = $anglefloor.get_collision_normal()
		var new_basis = Basis()
		new_basis.y = normal.normalized()
		new_basis.z = -forward
		new_basis.x = new_basis.y.cross(new_basis.z).normalized()
		new_basis.z = new_basis.x.cross(new_basis.y).normalized()
		transform.basis = new_basis

	# Gestion du timer de boost
	if is_boosting:
		boost_timer -= delta
		if boost_timer <= 0.0:
			is_boosting = false

	# Déplacement avec la physique
	move_and_slide()
