extends CharacterBody3D

class_name Player


# Configuration générale
const ACCELERATION = 20.0
const DECELERATION = 16.0
const TURN_SPEED = 2.0
const MAX_REVERSE_SPEED = -20.0

const JUMP_VELOCITY = 5
const SLIP_FACTOR = 0.05

const DRIFT_THRESHOLD = 20.0
const DRIFT_DECAY = 10.0    

var MAX_SPEED = 30.0

const BOOST_DURATION = 1.0
const BOOST_MULTIPLIER = 2

# États internes
var speed = 0.0
var lateral_velocity := Vector3.ZERO
var is_boosting = false
var boost_timer = 0.0
var drift_power = 0.0
var gravity_direction = Vector3(0, -1, 0)
var gravity_strength = 8.8
var wall_normal = null


var wall_ride = false

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

	lateral_velocity *= SLIP_FACTOR
	var slip_amount = 0.0
	#print(is_on_wall_only())
	if not $floorDetecte.is_colliding():
		is_on_wall()
	if speed != 0:
		slip_amount = direction * TURN_SPEED * delta * (abs(speed) / MAX_SPEED) * sqrt(speed) * 100.0
		lateral_velocity += right * slip_amount


	if is_turning:
		drift_power += abs(slip_amount) * 0.01
	else:
		if drift_power >= DRIFT_THRESHOLD and not is_boosting:
			is_boosting = true
			boost_timer = BOOST_DURATION
			drift_power = 0.0
		else:

			drift_power = clamp(drift_power - DRIFT_DECAY * delta, 0.0, 100.0)

	if is_boosting:
		MAX_SPEED = 50
		forward_velocity *= BOOST_MULTIPLIER
	else:
		MAX_SPEED = 30

	# Application de la vélocité totale
	velocity.x = forward_velocity.x + lateral_velocity.x
	velocity.z = forward_velocity.z + lateral_velocity.z


	if not is_on_floor():
		velocity += gravity_direction.normalized() * gravity_strength * delta

	# Gestion du saut
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Alignement au sol (raycast)
	if $anglefloor.is_colliding():
		var normal = $anglefloor.get_collision_normal()
		forward = -transform.basis.z.normalized()
		align_to_surface(normal, forward)
	
	if is_boosting:
		boost_timer -= delta
		if boost_timer <= 0.0:
			is_boosting = false

	# Déplacement a vec la physique
	move_and_slide()
	if is_on_wall() and not $floorDetecte.is_colliding():
		if get_slide_collision_count() > 0:
			print(get_last_slide_collision())
			var wall_normal = get_last_slide_collision().get_normal()
			gravity_direction = -wall_normal
			wall_ride = true
			velocity.y = velocity.y * 0
			
	else:
		gravity_direction = Vector3(0, -1, 0)
		wall_ride = false
		align_to_surface(Vector3.UP, -transform.basis.z)
		
		
func align_to_surface(normal: Vector3, forward_dir: Vector3):
	var new_basis = Basis()
	new_basis.y = normal.normalized()
	new_basis.z = -forward_dir.normalized()
	new_basis.x = new_basis.y.cross(new_basis.z).normalized()
	new_basis.z = new_basis.x.cross(new_basis.y).normalized()
	transform.basis = new_basis
