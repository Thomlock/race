extends CharacterBody3D
class_name Player

const ACCELERATION = 20.0
const DECELERATION = 16.0
const TURN_SPEED = 2.0
const MAX_REVERSE_SPEED = -20.0

const JUMP_VELOCITY = 5.0
const SLIP_FACTOR = 0.05

const DRIFT_THRESHOLD = 20.0
const DRIFT_DECAY = 10.0

const BOOST_DURATION = 1.0
const BOOST_MULTIPLIER = 2.0

var MAX_SPEED = 30.0

var speed = 0.0
var lateral_velocity := Vector3.ZERO
var is_boosting = false
var boost_timer = 0.0
var drift_power = 0.0
var gravity_direction = Vector3.DOWN
var gravity_strength = 8.8
var wall_ride = false

func _physics_process(delta: float) -> void:
	var accelerating = Input.is_action_pressed("ui_up")
	var braking = Input.is_action_pressed("ui_down")
	var turning_left = Input.is_action_pressed("ui_left")
	var turning_right = Input.is_action_pressed("ui_right")

	if accelerating:
		speed += ACCELERATION * delta
	elif braking:
		speed -= DECELERATION * delta * 2
	else:
		speed -= sign(speed) * DECELERATION * delta

	speed = clamp(speed, MAX_REVERSE_SPEED, MAX_SPEED)

	var direction = 0
	var is_turning = false
	if speed != 0:
		if turning_left:
			direction = 1
			is_turning = true
		elif turning_right:
			direction = -1
			is_turning = true
		var speed_factor = clamp(abs(speed) / MAX_SPEED, 0.5, 1.0)
		rotation.y += direction * TURN_SPEED * delta * speed_factor

	var forward = -transform.basis.z.normalized()
	var right = transform.basis.x.normalized()
	var forward_velocity = forward * speed

	lateral_velocity *= SLIP_FACTOR
	var slip_amount = 0.0
	if speed != 0:
		slip_amount = direction * TURN_SPEED * delta * (abs(speed) / MAX_SPEED) * sqrt(abs(speed)) * 100.0
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
		MAX_SPEED = 40.0
		forward_velocity *= BOOST_MULTIPLIER
	else:
		MAX_SPEED = 30.0

	velocity.x = forward_velocity.x + lateral_velocity.x
	velocity.z = forward_velocity.z + lateral_velocity.z

	if not is_on_floor():
		velocity += gravity_direction.normalized() * gravity_strength * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if $anglefloor.is_colliding():
		var normal = $anglefloor.get_collision_normal()
		var angleforward = -transform.basis.z.normalized()
		align_to_surface(normal, angleforward)

	if is_boosting:
		boost_timer -= delta
		if boost_timer <= 0.0:
			is_boosting = false

	move_and_slide()

	if $floorDetecte.is_colliding():
		var normal = $floorDetecte.get_collision_normal()
		var angle = rad_to_deg(acos(normal.dot(Vector3.UP)))

		if angle > 45 and is_on_wall():
			if get_slide_collision_count() > 0:
				var wall_normal = get_last_slide_collision().get_normal()
				gravity_direction = -wall_normal
				gravity_strength = 9.8
				wall_ride = true

				# 💥 Force plus forte vers le mur pour rester collé
				var wall_stick_force = wall_normal * -200.0
				velocity += wall_stick_force * delta

				# ⬆️ Pas besoin de velocity.y = 0 si on pousse déjà vers le mur

				var forward_dir = -transform.basis.z.normalized()
				align_to_surface(wall_normal, forward_dir)
		else:
			reset_gravity()
	else:
		reset_gravity()

func reset_gravity():
	gravity_direction = Vector3.DOWN
	gravity_strength = 8.8
	wall_ride = false
	align_to_surface(Vector3.UP, -transform.basis.z)

func align_to_surface(normal: Vector3, forward_dir: Vector3):
	if normal.length() == 0 or forward_dir.length() == 0:
		return

	var y_axis = normal.normalized()
	var z_axis = -forward_dir.normalized()

	if abs(y_axis.dot(z_axis)) > 0.99:
		z_axis = y_axis.cross(Vector3(1, 0, 0)).normalized()
		if z_axis.length() == 0:
			z_axis = y_axis.cross(Vector3(0, 0, 1)).normalized()

	var x_axis = y_axis.cross(z_axis).normalized()
	z_axis = x_axis.cross(y_axis).normalized()

	var new_basis = Basis()
	new_basis.x = x_axis
	new_basis.y = y_axis
	new_basis.z = z_axis

	# 🔁 Rotation plus rapide si on est en wallride
	var rotation_speed = 0.6 if wall_ride else 0.1
	transform.basis = transform.basis.slerp(new_basis, rotation_speed)
