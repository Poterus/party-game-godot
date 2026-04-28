extends CharacterBody2D

enum ControllerMode { HORIZONTAL, TOP_DOWN }
@export var mode: ControllerMode = ControllerMode.HORIZONTAL

@export var SPEED = 400.0
@export var DASH_SPEED = 800.0
@export var DASH_DURATION = 0.15
@export var FRICTION = 0.15 
@export var ACCELERATION = 0.3

var can_move: bool = false # Nacen petrificados
# Obtenemos la gravedad oficial de tu proyecto
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var my_player_id: int = 1
var is_dashing: bool = false

# --- NUEVO: Estado de vida ---
var is_dead: bool = false

# Referencias a los nodos de animación
@onready var sprite = $Sprite2D
@onready var anim_player = $AnimationPlayer
# @onready var collision_shape = $CollisionShape2D # Ver nota abajo sobre colisiones

signal player_died(id: int) # <--- NUEVA LÍNEA

func _physics_process(delta: float) -> void:
	# --- NUEVO: Lógica de Muerte ---
	if is_dead:
		# Si está muerto en modo horizontal, permitimos que la gravedad actúe
		# para que el cuerpo caiga al suelo si murió en el aire.
		if mode == ControllerMode.HORIZONTAL and not is_on_floor():
			velocity.y += gravity * delta
			move_and_slide()
		else:
			# Una vez en el suelo, o en top-down, nos aseguramos de que no se mueva nada más.
			velocity = Vector2.ZERO
		
		# IMPORTANTE: Salimos de la función aquí. No leemos inputs de móviles ni dashes.
		return 

	# --- CANDADO DE MOVIMIENTO (Spawn inicial) ---
	if not can_move:
		if not is_on_floor() and mode == ControllerMode.HORIZONTAL:
			velocity.y += gravity * delta
			move_and_slide()
		return 
		
	if is_dashing:
		move_and_slide()
		return

	var p_id = str(my_player_id)
	var move_dir = Vector2.ZERO
	
	# Input de WebSocket (Móviles) a través del NetworkManager
	var joy_vector = NetworkManager.player_joysticks.get(my_player_id, Vector2.ZERO)
	
	if joy_vector.length() > 0.15:
		move_dir = joy_vector
	else:
		# Input de teclado (Fallback local para PC). 
		# Nota: Esto podría dar errores si no blindaste el InputMap como vimos antes.
		move_dir.x = Input.get_axis("left_" + p_id, "right_" + p_id)
		move_dir.y = Input.get_axis("up_" + p_id, "down_" + p_id)

	var target_velocity = Vector2.ZERO
	
	if mode == ControllerMode.HORIZONTAL:
		# Lógica de gravedad normal
		if not is_on_floor():
			velocity.y += gravity * delta
		
		target_velocity.x = move_dir.x * SPEED
		
		# Voltear el Sprite
		if move_dir.x > 0.01:
			sprite.flip_h = false
		elif move_dir.x < -0.01:
			sprite.flip_h = true
			
		# Solo suavizamos la X
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION)
		
	else:
		# Modo Cenital (Top Down)
		target_velocity = move_dir.normalized() * SPEED
		if move_dir.length() > 0:
			var target_angle = move_dir.angle()
			rotation = lerp_angle(rotation, target_angle, 0.2)
		velocity = velocity.lerp(target_velocity, ACCELERATION)

	# Control del Dash
	if Input.is_action_just_pressed("dash_" + p_id) and not is_dashing:
		_start_dash(move_dir)

	move_and_slide()
	
	# Actualizar animaciones de movimiento (walk/idle)
	_update_animations(move_dir)


func _update_animations(move_dir: Vector2) -> void:
	# Si ya está reproduciendo la muerte, no hacemos nada más.
	# La animación "death" se detendrá sola en el último frame porque no tiene bucle.
	if anim_player.current_animation == "death":
		return

	if move_dir.length() > 0.1:
		if anim_player.current_animation != "walk":
			anim_player.play("walk")
	else:
		if anim_player.current_animation != "idle":
			anim_player.play("idle")


# --- NUEVO: Función para matar al jugador ---
# Puedes llamar a esto desde un script de peligro (ej. lava, pinchos, bala)
func die() -> void:
	if is_dead: return # Evitar matar a un muerto

	is_dead = true
	is_dashing = false 
	
	anim_player.play("death")
	
	# --- NUEVA LÍNEA: Avisamos al mundo de que este jugador ha caído ---
	player_died.emit(my_player_id)
	
	# ... (el resto del código de muerte) ...
	
	# NOTA SOBRE COLISIONES:
	# Dependiendo de tu minijuego, quizás quieras que los cuerpos muertos NO estorben 
	# a los vivos. Si es así, necesitas cambiar las capas de colisión (Collision Layers).
	# Por ejemplo, asumiendo que la capa 1 es el mundo y la 2 son jugadores:
	
	# collision_layer = 0 # Ya no es un "jugador", nada puede chocar CON él.
	# collision_mask = 1  # Pero él sigue chocando con el SUELO (capa 1) para poder caer.
	
	# Si usas Area2D para peligros, asegúrate de desactivarlas también aquí.


func _start_dash(direction: Vector2) -> void:
	is_dashing = true
	
	var dash_vec = direction.normalized()
	if dash_vec == Vector2.ZERO:
		if mode == ControllerMode.HORIZONTAL:
			dash_vec = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
		else:
			dash_vec = Vector2.RIGHT.rotated(rotation)
			
	velocity = dash_vec * DASH_SPEED
	
	await get_tree().create_timer(DASH_DURATION).timeout
	# Si murió durante el dash, no restauramos el estado de dashing false aquí
	if not is_dead:
		is_dashing = false
