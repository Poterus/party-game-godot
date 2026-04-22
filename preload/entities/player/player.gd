extends CharacterBody2D

enum ControllerMode { HORIZONTAL, TOP_DOWN }
@export var mode: ControllerMode = ControllerMode.HORIZONTAL

@export var SPEED = 400.0
@export var DASH_SPEED = 800.0
@export var DASH_DURATION = 0.15
@export var FRICTION = 0.15 
@export var ACCELERATION = 0.3

# --- NUEVO: Obtenemos la gravedad oficial de tu proyecto ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var my_player_id: int = 1
var is_dashing: bool = false

func _physics_process(delta: float) -> void:
	if is_dashing:
		move_and_slide()
		return

	var p_id = str(my_player_id)
	var move_dir = Vector2.ZERO
	
	var joy_vector = NetworkManager.player_joysticks.get(my_player_id, Vector2.ZERO)
	
	if joy_vector.length() > 0.15:
		move_dir = joy_vector
	else:
		move_dir.x = Input.get_axis("left_" + p_id, "right_" + p_id)
		move_dir.y = Input.get_axis("up_" + p_id, "down_" + p_id)

	var target_velocity = Vector2.ZERO
	
	if mode == ControllerMode.HORIZONTAL:
		# --- NUEVA LÓGICA DE GRAVEDAD ---
		# Si no está tocando el suelo, le sumamos la gravedad por el tiempo
		if not is_on_floor():
			velocity.y += gravity * delta
		
		target_velocity.x = move_dir.x * SPEED
		
		#if move_dir.x != 0:
		#	$Sprite2D.flip_h = move_dir.x < 0
			
		# Solo suavizamos la X, dejamos que la gravedad controle la Y
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION)
		
	else:
		# Modo Cenital (sin cambios)
		target_velocity = move_dir.normalized() * SPEED
		if move_dir.length() > 0:
			var target_angle = move_dir.angle()
			rotation = lerp_angle(rotation, target_angle, 0.2)
		velocity = velocity.lerp(target_velocity, ACCELERATION)

	if Input.is_action_just_pressed("dash_" + p_id) and not is_dashing:
		_start_dash(move_dir)

	move_and_slide()

func _start_dash(direction: Vector2) -> void:
	is_dashing = true
	
	# Si no se mueve, dash hacia adelante (derecha) por defecto
	var dash_vec = direction.normalized()
	if dash_vec == Vector2.ZERO:
		dash_vec = Vector2.RIGHT
		
	velocity = dash_vec * DASH_SPEED
	
	await get_tree().create_timer(DASH_DURATION).timeout
	is_dashing = false
