extends Node2D
class_name SprintLane

# ====================================================
# CARRIL INDIVIDUAL - Versión simple con Sprite2D
# ====================================================
@export var lane_width: float = 480.0
@export var lane_height: float = 50.0

@onready var background = $Background
@onready var finish_line = $FinishLine
@onready var label_player = $LabelPlayer
@onready var player_sprite = $PlayerSprite  # Sprite2D simple

# --- ESTADO ---
var player_id: int = -1
var current_progress: float = 0.0
var is_winner: bool = false

func _ready() -> void:
	if not background:
		push_error("❌ SprintLane: No encontré Background")

func setup(p_id: int, p_face: ImageTexture = null) -> void:
	player_id = p_id
	is_winner = false
	current_progress = 0.0
	
	if label_player:
		label_player.text = "P%d" % p_id
	
	# Posición inicial del sprite
	if player_sprite:
		player_sprite.position = Vector2(10, lane_height / 2.0)
	
	print("✓ Lane P%d configurado" % p_id)

func update_progress(progress: float) -> void:
	current_progress = clamp(progress, 0.0, 1.0)
	
	if player_sprite:
		var target_x = current_progress * lane_width
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(player_sprite, "position:x", target_x, 0.1)

func get_player_id() -> int:
	return player_id

func get_progress() -> float:
	return current_progress

func highlight_winner() -> void:
	is_winner = true
	if background:
		var tween = create_tween()
		tween.set_loops(3)
		tween.tween_property(background, "modulate", Color.GOLD, 0.2)
		tween.tween_property(background, "modulate", Color.WHITE, 0.2)

func highlight_loser() -> void:
	if background:
		var tween = create_tween()
		tween.tween_property(background, "modulate", Color(0.5, 0.5, 0.5), 0.5)

func reset() -> void:
	current_progress = 0.0
	is_winner = false
	if player_sprite:
		player_sprite.position.x = 10
	if background:
		background.modulate = Color.WHITE
	print("🔄 Lane P%d reseteado" % player_id)
