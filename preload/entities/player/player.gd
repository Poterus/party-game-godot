extends CharacterBody2D

# --- CONFIGURACIÓN ---
enum ControllerMode { HORIZONTAL, TOP_DOWN }
@export var mode: ControllerMode = ControllerMode.HORIZONTAL

@export var SPEED = 400.0
@export var DASH_SPEED = 1200.0
@export var DASH_DURATION = 0.15

# --- ESTADO ---
var my_player_id: int = 1
var is_dashing: bool = false

func _physics_process(delta: float) -> void:
	if is_dashing:
		move_and_slide()
		return

	var p_id = str(my_player_id)
	var move_dir = Vector2.ZERO
	
	# 1. Obtener Input (Prioridad Joystick, luego Teclado)
	var joy_vector = NetworkManager.player_joysticks.get(my_player_id, Vector2.ZERO)
	
	if joy_vector.length() > 0.15:
		move_dir = joy_vector
	else:
		# Leemos los 4 ejes por si acaso
		move_dir.x = Input.get_axis("left_" + p_id, "right_" + p_id)
		move_dir.y = Input.get_axis("up_" + p_id, "down_" + p_id)

	# 2. Aplicar Lógica según el Modo
	if mode == ControllerMode.HORIZONTAL:
		velocity.x = move_dir.x * SPEED
		velocity.y = 0 # Bloqueamos vertical
	else:
		# Modo Cenital: Movimiento libre 360º
		velocity = move_dir.normalized() * SPEED

	# 3. DASH (Funciona en la dirección que te muevas)
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
