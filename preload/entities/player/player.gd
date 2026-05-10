extends CharacterBody2D

enum ControllerMode { HORIZONTAL, TOP_DOWN }
@export var mode: ControllerMode = ControllerMode.HORIZONTAL

@export var SPEED = 250.0
@export var ACCELERATION = 0.3

var can_move: bool = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var my_player_id: int = 1
var is_dashing: bool = false
var is_dead: bool = false

@onready var sprite = $Sprite2D
@onready var anim_player = $AnimationPlayer
@onready var face_polygon = $Polygon2D 
@onready var face_sprite = $Polygon2D/FaceSprite 

signal player_died(id: int)

func _ready() -> void:
	NetworkManager.player_face_updated.connect(_on_player_face_updated)
	_check_for_stored_face()

func _physics_process(delta: float) -> void:
	if is_dead:
		if mode == ControllerMode.HORIZONTAL and not is_on_floor():
			velocity.y += gravity * delta
			move_and_slide()
		return 

	if not can_move: return 
	
	var p_id = str(my_player_id)
	var move_dir = Vector2.ZERO
	var joy_vector = NetworkManager.player_joysticks.get(my_player_id, Vector2.ZERO)
	
	if joy_vector.length() > 0.15:
		move_dir = joy_vector
	else:
		move_dir.x = Input.get_axis("left_" + p_id, "right_" + p_id)
		move_dir.y = Input.get_axis("up_" + p_id, "down_" + p_id)

	if mode == ControllerMode.HORIZONTAL:
		if not is_on_floor():
			velocity.y += gravity * delta
		
		# Girar solo visualmente mientras está vivo
		if move_dir.x > 0.01:
			sprite.flip_h = false
			face_polygon.scale.x = 1
		elif move_dir.x < -0.01:
			sprite.flip_h = true
			face_polygon.scale.x = -1
			
		velocity.x = lerp(velocity.x, move_dir.x * SPEED, ACCELERATION)
		
	move_and_slide()
	_update_animations(move_dir)

func _update_animations(move_dir: Vector2) -> void:
	if anim_player.current_animation == "death": return
	if move_dir.length() > 0.1:
		anim_player.play("walk")
	else:
		anim_player.play("idle")

# --- ESTA ES LA FUNCIÓN QUE ARREGLA LA MUERTE RÁPIDO ---
func die() -> void:
	if is_dead: return 
	is_dead = true
	
	# Truco: Si miramos a la izquierda, en lugar de flip_h,
	# invertimos el scale.x del nodo raíz brevemente para que
	# la animación de muerte "piense" que va hacia la derecha.
	if sprite.flip_h:
		self.scale.x = -1
		# Invertimos el flip_h para que no se doble-invierta
		sprite.flip_h = false 
		face_polygon.scale.x = 1
	
	anim_player.play("death")
	
	player_died.emit(my_player_id)
	if face_sprite:
		face_sprite.modulate = Color(0.3, 0.3, 0.3) 

# --- GESTIÓN DE FOTO ---
func _check_for_stored_face():
	if NetworkManager.player_faces.has(my_player_id):
		_apply_face_texture(NetworkManager.player_faces[my_player_id])

func _on_player_face_updated(id: int, texture: ImageTexture):
	if id == my_player_id:
		_apply_face_texture(texture)

# --- VERSIÓN LIMPIA (RESPETA EL EDITOR) ---
func _apply_face_texture(texture: ImageTexture): 
	if face_sprite != null:
		face_sprite.texture = texture
		face_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		
		# ¡Todo el código de matemáticas y zoom borrado!
		# Ahora Godot respeta tu Scale de 0.2 (o el que le pongas) y tu Position en el Editor.
			
		face_sprite.visible = true
