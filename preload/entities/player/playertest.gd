extends CharacterBody2D

## Configuración de físicas
@export var speed: float = 500.0
@export var acceleration: float = 0.25
@export var friction: float = 0.2

## Configuración del Dash
@export var dash_force: float = 1000.0 # Fuerza del impulso
@export var dash_duration: float = 0.15 # Cuánto dura el impulso (en segundos)
var is_dashing: bool = false
var last_direction: float = 1.0 # Por defecto mira a la derecha (1.0)

## Variables de estado de input
var input_axis: float = 0.0
var wants_to_act: bool = false

func _physics_process(delta: float) -> void:
	# 1. Obtener dirección
	input_axis = Input.get_axis("move_left", "move_right")
	
	# Guardar la última dirección para el Dash si el jugador se está moviendo
	if input_axis != 0:
		last_direction = sign(input_axis)
	
	# 2. Aplicar Movimiento Horizontal (Solo si no estamos en Dash)
	if not is_dashing:
		if input_axis != 0:
			velocity.x = move_toward(velocity.x, input_axis * speed, speed * acceleration)
		else:
			velocity.x = move_toward(velocity.x, 0, speed * friction)
	
	# 3. Acción Especial (Espacio / Dash)
	if Input.is_action_just_pressed("action") or wants_to_act:
		perform_dash()
		wants_to_act = false 
		
	move_and_slide()

func perform_dash():
	if is_dashing: return # Evita spam de dash si ya está ocurriendo
	
	is_dashing = true
	
	# Aplicamos la fuerza en la dirección que miramos
	velocity.x = last_direction * dash_force
	
	# Feedback visual temporal sin Sprites (Cambiamos el color del ColorRect)
	var original_color = $ColorRect.color
	$ColorRect.color = Color(1, 1, 1) # Se vuelve blanco brillante
	
	# Creamos un Timer rápido mediante código para terminar el Dash
	await get_tree().create_timer(dash_duration).timeout
	
	# Volvemos a la normalidad
	is_dashing = false
	$ColorRect.color = original_color
