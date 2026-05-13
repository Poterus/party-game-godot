extends Node2D
class_name SprintLane

# ====================================================
# CARRIL INDIVIDUAL REUTILIZABLE PARA SPRINT
# ====================================================

@onready var background = $Background
@onready var finish_line = $FinishLine
@onready var label_player = $LabelPlayer

# --- CONFIGURACIÓN EXPORTADA ---
@export var player_scene: PackedScene  # Arrastra res://entities/player/player.tscn

# --- ESTADO ---
var player_id: int = -1
var current_progress: float = 0.0
var is_winner: bool = false
var player_node: CharacterBody2D = null  # Referencia al Player instanciado

func _ready() -> void:
	_verify_references()

func _verify_references() -> void:
	if not background:
		push_error("❌ SprintLane: No encontré Background")
	if not finish_line:
		push_error("❌ SprintLane: No encontré FinishLine")
	if not label_player:
		push_error("❌ SprintLane: No encontré LabelPlayer")

func setup(p_id: int, p_face: ImageTexture = null) -> void:
	player_id = p_id
	is_winner = false
	current_progress = 0.0
	
	if label_player:
		label_player.text = "P%d" % p_id
	
	_spawn_player(p_id, p_face)
	
	print("✓ Lane P%d configurado" % p_id)

func _spawn_player(p_id: int, p_face: ImageTexture) -> void:
	if not player_scene:
		push_error("❌ SprintLane: player_scene no asignado")
		return
	
	# Limpiar player anterior si existe
	if player_node:
		player_node.queue_free()
	
	# Instanciar Player
	player_node = player_scene.instantiate()
	background.add_child(player_node)
	player_node.anim_player.active = false
	
	# Posición inicial dentro del lane
	
	# Lo centramos perfectamente en la altura del background (40 / 2 = 20)
	player_node.position = Vector2(10, background.size.y / 2.0)
	# Desactivar física completamente
	player_node.set_physics_process(false)
	player_node.set_process(false)
	player_node.can_move = false
	
	# Asignar ID y cara
	player_node.my_player_id = p_id
	if p_face:
		player_node._apply_face_texture(p_face)
	
	# Iniciar animación idle
	player_node.anim_player.play("idle")
	player_node.anim_player.pause()
	player_node.anim_player.seek(0, true)

func update_progress(progress: float) -> void:
	current_progress = clamp(progress, 0.0, 1.0)
	
	# Mover el player horizontalmente
	if player_node:
		var target_x = current_progress * background.size.x
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(player_node, "position:x", target_x, 0.1)
		
		# Avanzar un frame de la animación walk
		_advance_walk_frame()

func _advance_walk_frame() -> void:
	if not player_node:
		return
	
	var anim = player_node.anim_player
	var walk_anim = anim.get_animation("walk")
	
	if not anim.active:
		anim.active = true
	
	if anim.current_animation != "walk":
		anim.play("walk")
	
	anim.advance(0.1)
	anim.pause()
	
func get_player_id() -> int:
	return player_id

func get_progress() -> float:
	return current_progress

func highlight_winner() -> void:
	is_winner = true
	if player_node:
		player_node.anim_player.play("idle")
	if background:
		var tween = create_tween()
		tween.set_loops(3)
		tween.tween_property(background, "modulate", Color.GOLD, 0.2)
		tween.tween_property(background, "modulate", Color.WHITE, 0.2)

func highlight_loser() -> void:
	if player_node:
		player_node.anim_player.play("idle")
	if background:
		var tween = create_tween()
		tween.tween_property(background, "modulate", Color(0.5, 0.5, 0.5), 0.5)

func reset() -> void:
	current_progress = 0.0
	is_winner = false
	if player_node:
		player_node.position.x = 10
		player_node.anim_player.play("idle")
	if background:
		background.modulate = Color.WHITE
	print("🔄 Lane P%d reseteado" % player_id)
