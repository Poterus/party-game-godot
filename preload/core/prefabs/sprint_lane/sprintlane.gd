extends Node2D
class_name SprintLane

# ====================================================
# CARRIL INDIVIDUAL REUTILIZABLE PARA SPRINT
# Puede usarse en cualquier minijuego de carrera
# ====================================================

@onready var background = $Background
@onready var finish_line = $FinishLine
@onready var sprite_player = $PlayerSprite
@onready var label_player = $LabelPlayer

# --- CONFIGURACIÓN EXPORTADA ---
@export var lane_width: float = 1200.0
@export var lane_height: float = 100.0
@export var finish_x: float = 1200.0
@export var enable_animations: bool = true

# --- ESTADO ---
var player_id: int = -1
var current_progress: float = 0.0  # 0.0 a 1.0
var face_texture: ImageTexture
var is_winner: bool = false

func _ready() -> void:
	# Las propiedades se configuran vía setup()
	# Aquí solo hacemos setup visual básico
	_setup_ui_references()

func _setup_ui_references() -> void:
	"""Verifica que todos los referencias existan."""
	if not background:
		push_error("❌ SprintLane: No encontré Background")
	if not finish_line:
		push_error("❌ SprintLane: No encontré FinishLine")
	if not sprite_player:
		push_error("❌ SprintLane: No encontré PlayerSprite")
	if not label_player:
		push_error("❌ SprintLane: No encontré LabelPlayer")

func setup(p_id: int, p_face: ImageTexture = null) -> void:
	"""
	Configura el carril para un jugador específico.
	
	Args:
		p_id: ID del jugador (1, 2, 3, ...)
		p_face: Textura de la cara del jugador (opcional)
	"""
	player_id = p_id
	face_texture = p_face
	is_winner = false
	current_progress = 0.0
	
	# Actualizar label con ID
	if label_player:
		label_player.text = "P%d" % p_id
	
	# Asignar textura de cara si existe
	if sprite_player and face_texture:
		sprite_player.texture = face_texture
		sprite_player.visible = true
	elif sprite_player:
		# Fallback: icono por defecto
		sprite_player.visible = false
	
	# Configurar tamaños
	if background:
		background.custom_minimum_size = Vector2(lane_width, lane_height)
		background.color = Color(0.2, 0.2, 0.2, 1)
	
	print("✓ Lane P%d configurado" % p_id)

func update_progress(progress: float) -> void:
	"""
	Actualiza la posición visual según el progreso (0.0-1.0).
	Se llama desde Sprint cuando el jugador pulsa.
	"""
	current_progress = clamp(progress, 0.0, 1.0)
	
	if sprite_player and enable_animations:
		# Animación suave
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(sprite_player, "position:x", current_progress * finish_x, 0.1)
	else:
		# Movimiento instantáneo
		if sprite_player:
			sprite_player.position.x = current_progress * finish_x

func get_player_id() -> int:
	"""Retorna el ID del jugador en este carril."""
	return player_id

func get_progress() -> float:
	"""Retorna el progreso actual (0.0-1.0)."""
	return current_progress

func highlight_winner() -> void:
	"""Efecto visual cuando gana este jugador - Parpadeo dorado."""
	is_winner = true
	
	if not background:
		return
	
	var tween = create_tween()
	tween.set_loops(3)  # 3 veces
	
	# Parpadeo dorado
	tween.tween_property(background, "modulate", Color.GOLD, 0.2)
	tween.tween_property(background, "modulate", Color.WHITE, 0.2)

func highlight_loser() -> void:
	"""Efecto visual cuando pierde (gris más oscuro)."""
	if background:
		var tween = create_tween()
		tween.tween_property(background, "modulate", Color(0.5, 0.5, 0.5), 0.5)

func reset() -> void:
	"""Reinicia el carril a estado inicial."""
	current_progress = 0.0
	is_winner = false
	
	if sprite_player:
		sprite_player.position.x = 0
	
	if background:
		background.modulate = Color.WHITE
	
	print("🔄 Lane P%d reseteado" % player_id)

# =========================================================
# UTILIDADES
# =========================================================

func get_player_name() -> String:
	"""Retorna el nombre del jugador (para UI)."""
	return "Jugador %d" % player_id

func set_visible_progress_label(visible: bool) -> void:
	"""Muestra/oculta el label del jugador."""
	if label_player:
		label_player.visible = visible

func set_lane_color(color: Color) -> void:
	"""Cambia el color del fondo del carril (para temas)."""
	if background:
		background.color = color

func get_finish_line_position() -> Vector2:
	"""Retorna la posición de la meta."""
	if finish_line:
		return finish_line.position
	return Vector2(finish_x, 0)

# =========================================================
# ANIMACIONES AVANZADAS (OPCIONAL)
# =========================================================

func shake_effect() -> void:
	"""Efecto de temblor cuando se pulsa (feedback)."""
	if not enable_animations:
		return
	
	var original_pos = sprite_player.position
	var shake_amount = 5.0
	var tween = create_tween()
	
	for i in range(4):
		var offset = Vector2(randf_range(-shake_amount, shake_amount), 0)
		tween.tween_property(sprite_player, "position", original_pos + offset, 0.05)
	
	tween.tween_property(sprite_player, "position", original_pos, 0.05)

func boost_effect() -> void:
	"""Efecto visual de boost (si hubiera power-ups)."""
	if not sprite_player or not enable_animations:
		return
	
	var original_scale = sprite_player.scale
	var tween = create_tween()
	
	tween.tween_property(sprite_player, "scale", original_scale * 1.2, 0.1)
	tween.tween_property(sprite_player, "scale", original_scale, 0.1)
