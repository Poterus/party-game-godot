extends CharacterBody2D

enum ControllerMode { HORIZONTAL, TOP_DOWN }
@export var mode: ControllerMode = ControllerMode.HORIZONTAL
@export var SPEED: float = 250.0
@export var SPEED_TOP_DOWN: float = 130.0

const PALETTE_SHADER = preload("res://assets/shaders/palette_swap.gdshader")
const SRC_LIGHT_HEX  = "#0696DB"
const BANDANA_HEX    = "#E7333B"
const DEFAULT_COLOR  = "#909090"

var can_move: bool = false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var my_player_id: int = 1
var is_dead: bool = false
var is_jumping: bool = false
var jump_vel_y: float = 0.0       # impulso vertical del salto en TOP_DOWN
var platforms_below: int = 0      # plataformas que actualmente cubren al player
var on_ice: int = 0               # tiles de hielo que cubren al player (inercia alta)
var scroll_force: float = 0.0    # fuerza descendente externa (ej: scroll de Subida)
var coyote_time: float = 0.0      # ventana de gracia tras salir de plataforma
var _anim_state: String = ""      # estado lógico actual de animación para evitar play() redundante

const JUMP_IMPULSE: float = -90.0     # px/s hacia arriba al saltar
const JUMP_GRAVITY: float = 320.0     # decaimiento (px/s²) — vuelve al suelo
const COYOTE_DURATION: float = 0.15   # segundos de margen tras pisar el borde

@onready var sprite       = $Sprite2D
@onready var anim_player  = $AnimationPlayer
@onready var face_polygon = $Sprite2D/Polygon2D
@onready var face_sprite  = $Sprite2D/Polygon2D/FaceSprite
@onready var hat_sprite   = $HatSprite
var shadow: Sprite2D = null  # se asigna en _ready si el nodo existe

signal player_died(id: int)

func _ready() -> void:
	NetworkManager.player_face_updated.connect(_on_player_face_updated)
	anim_player.animation_finished.connect(_on_animation_finished)
	shadow = get_node_or_null("Shadow")
	if shadow:
		shadow.visible = false
	_check_for_stored_face()
	_setup_shader()
	_apply_customization()
	_add_fall_animation()

# Crea la animación "fall" en runtime usando los frames descendentes del salto (52-55).
# Se ejecuta por instancia, es seguro modificar la sublibrary embebida del .tscn.
func _add_fall_animation() -> void:
	var lib := anim_player.get_animation_library("")
	if lib.has_animation("fall"):
		return
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 0.1
	# Track 0: 2 frames del descenso — con speed_scale=0.5 dura 0.2s real por ciclo
	var ti := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ti, NodePath("Sprite2D:frame"))
	anim.value_track_set_update_mode(ti, Animation.UPDATE_DISCRETE)
	anim.track_insert_key(ti, 0.0,   53)
	anim.track_insert_key(ti, 0.05,  54)
	# Track 1: posición de la cara
	var fi := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(fi, NodePath("Sprite2D/Polygon2D:position"))
	anim.value_track_set_update_mode(fi, Animation.UPDATE_DISCRETE)
	anim.track_insert_key(fi, 0.0, Vector2(0, 1))
	lib.add_animation("fall", anim)

func _physics_process(delta: float) -> void:
	if is_dead:
		if mode == ControllerMode.HORIZONTAL and not is_on_floor():
			velocity.y += gravity * delta
			move_and_slide()
		return

	if not can_move:
		velocity = Vector2.ZERO
		return

	var move_dir := _get_move_dir()

	match mode:
		ControllerMode.HORIZONTAL:
			velocity.x = move_dir.x * SPEED
			if not is_on_floor():
				velocity.y += gravity * delta
			_update_flip(move_dir.x)

		ControllerMode.TOP_DOWN:
			# Coyote time: contar hacia abajo
			if coyote_time > 0.0:
				coyote_time = max(0.0, coyote_time - delta)
			# Arco completo: sube (-90 → 0) y vuelve (0 → +90 → clamp a 0)
			if jump_vel_y != 0.0:
				jump_vel_y += JUMP_GRAVITY * delta
				if jump_vel_y >= -JUMP_IMPULSE:  # completó el arco de vuelta
					jump_vel_y = 0.0
			var target_x := move_dir.x * SPEED_TOP_DOWN
			var target_y := move_dir.y * SPEED_TOP_DOWN
			if on_ice > 0:
				# En hielo: inercia alta, control reducido.
				# Aislamos scroll_force y jump del lerp para que siempre se apliquen completos.
				var ctrl_y := velocity.y - jump_vel_y - scroll_force
				velocity.x = lerp(velocity.x, target_x, 0.07)
				velocity.y = lerp(ctrl_y, target_y, 0.07) + jump_vel_y + scroll_force
			else:
				velocity.x = target_x
				velocity.y = target_y + jump_vel_y + scroll_force
			_check_jump()
			_update_shadow()

	move_and_slide()
	_update_animations(move_dir)

func _get_move_dir() -> Vector2:
	var joy: Vector2 = NetworkManager.player_joysticks.get(my_player_id, Vector2.ZERO)
	if joy.length() > 0.08:
		return joy
	var p := str(my_player_id)
	return Vector2(
		Input.get_axis("left_" + p, "right_" + p),
		Input.get_axis("up_" + p, "down_" + p)
	)

func _update_flip(dir_x: float) -> void:
	if dir_x > 0.01:
		sprite.flip_h = false
		face_polygon.scale.x = 1
	elif dir_x < -0.01:
		sprite.flip_h = true
		face_polygon.scale.x = -1

func _check_jump() -> void:
	if is_jumping or jump_vel_y != 0.0 or not can_move or is_dead:
		return
	# Solo se puede saltar estando sobre una plataforma o en ventana coyote
	if platforms_below <= 0 and coyote_time <= 0.0:
		return
	var p := str(my_player_id)
	if Input.is_action_just_pressed("dash_" + p):
		if anim_player.has_animation("jump"):
			is_jumping = true
			jump_vel_y = JUMP_IMPULSE
			coyote_time = 0.0  # consumir la ventana
			_anim_state = "jump"
			anim_player.play("jump")

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "jump":
		is_jumping = false
		jump_vel_y = 0.0

## Llamado por Plataforma cuando el player entra en su Area2D
func on_platform_entered() -> void:
	platforms_below += 1

## Llamado por Plataforma cuando el player sale de su Area2D
func on_platform_exited() -> void:
	platforms_below = max(0, platforms_below - 1)
	if platforms_below == 0:
		coyote_time = COYOTE_DURATION

## Llamado por tile de hielo al entrar/salir
func on_ice_entered() -> void:
	on_ice += 1

func on_ice_exited() -> void:
	on_ice = max(0, on_ice - 1)

func _update_shadow() -> void:
	if not shadow:
		return
	shadow.visible = true
	if jump_vel_y == 0.0:
		# En el suelo: sombra completa
		shadow.scale   = Vector2.ONE
		shadow.modulate.a = 0.55
	else:
		# Durante el arco: t=0 en inicio/fin, t=1 en la cima
		var t: float = 1.0 - abs(jump_vel_y) / abs(JUMP_IMPULSE)
		shadow.scale      = Vector2.ONE * lerp(1.0, 0.45, t)
		shadow.modulate.a = lerp(0.55, 0.15, t)

func _update_animations(move_dir: Vector2) -> void:
	if anim_player.current_animation == "death": return

	var target: String
	match mode:
		ControllerMode.HORIZONTAL:
			if not is_on_floor():
				# En el aire: usar "fall" (si ya está en "jump" por algún uso externo, no interrumpir)
				target = "fall" if anim_player.current_animation != "jump" else "jump"
			elif move_dir.length() > 0.1:
				target = "walk"
			else:
				target = "idle"

		ControllerMode.TOP_DOWN:
			# Mantener la animación de salto hasta que TANTO la animación como el arco físico terminen
			if is_jumping or jump_vel_y != 0.0:
				return
			if move_dir.length() > 0.1:
				target = "walk"
			else:
				target = "idle"

	if target != _anim_state:
		_anim_state = target
		anim_player.play(target)

func die() -> void:
	if is_dead: return
	is_dead = true
	platforms_below = 0
	coyote_time = 0.0
	if sprite.flip_h:
		self.scale.x = -abs(self.scale.x)
		sprite.flip_h = false
		face_polygon.scale.x = 1
	_anim_state = "death"
	anim_player.play("death")
	player_died.emit(my_player_id)
	if face_sprite:
		face_sprite.modulate = Color(0.3, 0.3, 0.3)

# --- GESTIÓN DE FOTO ---
func _check_for_stored_face() -> void:
	if NetworkManager.player_faces.has(my_player_id):
		_apply_face_texture(NetworkManager.player_faces[my_player_id])

func _on_player_face_updated(id: int, texture: ImageTexture) -> void:
	if id == my_player_id:
		_apply_face_texture(texture)

func _apply_face_texture(texture: ImageTexture) -> void:
	if face_sprite:
		face_sprite.texture = texture
		face_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		face_sprite.visible = true

# --- PERSONALIZACION (COLOR + PANUELO + SOMBRERO) ---
func _setup_shader() -> void:
	var mat  = ShaderMaterial.new()
	mat.shader = PALETTE_SHADER
	var src  = Color.from_string(SRC_LIGHT_HEX, Color.WHITE)
	var band = Color.from_string(BANDANA_HEX,   Color.WHITE)
	mat.set_shader_parameter("src_hue_center",  src.h)
	mat.set_shader_parameter("src_hue_range",   0.20)
	mat.set_shader_parameter("src_val",         src.v)
	mat.set_shader_parameter("band_hue_center", band.h)
	mat.set_shader_parameter("band_hue_range",  0.05)
	mat.set_shader_parameter("sat_min",         0.12)
	mat.set_shader_parameter("bandana_color",   Color.from_string("#282828", Color.BLACK))
	sprite.material = mat
	apply_color(Color.from_string(DEFAULT_COLOR, Color.WHITE))

func _apply_customization() -> void:
	if not NetworkManager.player_customizations.has(my_player_id):
		return
	var data: Dictionary = NetworkManager.player_customizations[my_player_id]
	var hex: String = data.get("skin_color", SRC_LIGHT_HEX)
	apply_color(Color.from_string(hex, Color.WHITE))
	apply_hat(data.get("hat", 0))

func apply_color(color: Color) -> void:
	if sprite.material is ShaderMaterial:
		sprite.material.set_shader_parameter("player_color", color)

func apply_bandana_color(color: Color) -> void:
	if sprite.material is ShaderMaterial:
		sprite.material.set_shader_parameter("bandana_color", color)

func apply_hat(hat_id: int) -> void:
	if hat_id <= 0:
		hat_sprite.visible = false
		return
	var path = "res://assets/sprites/hats/hat_" + str(hat_id) + ".png"
	if ResourceLoader.exists(path):
		hat_sprite.texture = load(path)
		hat_sprite.visible = true
	else:
		hat_sprite.visible = false
