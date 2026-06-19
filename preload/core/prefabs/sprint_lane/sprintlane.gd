extends Node2D
class_name SprintLane

# ====================================================
# CARRIL INDIVIDUAL — mecánica estilo Mario Party
# ====================================================

@export var lane_width: float = 500.0
@export var lane_height: float = 20.0
@export var player_scene: PackedScene
@export var boat_scene: PackedScene

@export var speed_per_press: float = 39.0
@export var max_velocity: float = 234.0
@export var acceleration: float = 700.0
@export var friction: float = 9.0
@export var min_velocity: float = 5.0

@onready var background = $Background
@onready var finish_line = $FinishLine
@onready var label_player = $LabelPlayer

const START_X := 8.0

signal lane_finished(p_id: int)

var player_id: int = -1
var current_progress: float = 0.0
var lane_velocity: float = 0.0
var target_velocity: float = 0.0
var exact_x: float = START_X

var is_winner: bool = false
var is_finished: bool = false

var player_node = null
var boat_node = null


func _ready() -> void:
	if not background:
		push_error("❌ SprintLane: No encontré Background")


func setup(p_id: int, _p_face: ImageTexture = null) -> void:
	player_id = p_id
	is_winner = false
	is_finished = false
	current_progress = 0.0
	lane_velocity = 0.0
	target_velocity = 0.0
	exact_x = START_X

	if label_player:
		label_player.text = "P%d" % p_id

	_setup_player()
	print("✓ Lane P%d configurado" % p_id)


func _setup_player() -> void:
	if not player_scene:
		push_error("❌ SprintLane: player_scene no asignado")
		return

	if player_node:
		player_node.queue_free()
		player_node = null

	player_node = player_scene.instantiate()
	player_node.my_player_id = player_id
	player_node.mode = player_node.ControllerMode.TOP_DOWN
	player_node.position = Vector2(round(START_X), lane_height - 8)

	add_child(player_node)

	player_node.can_move = false

	var collision = player_node.get_node_or_null("CollisionShape2D")
	if collision:
		collision.disabled = true

	player_node.anim_player.speed_scale = 0.5
	player_node.anim_player.play("idle")

	if boat_scene:
		boat_node = boat_scene.instantiate()
		boat_node.z_index = 1
		player_node.add_child(boat_node)
		print("⛵ Barco añadido a P%d" % player_id)


func on_button_pressed() -> void:
	if is_finished:
		return

	target_velocity = min(
		target_velocity + speed_per_press,
		max_velocity
	)


func _process(delta: float) -> void:
	if not player_node or is_finished:
		return

	# Decaimiento
	target_velocity *= max(0.0, 1.0 - friction * delta)

	# Frenado limpio
	if target_velocity < min_velocity:
		target_velocity = 0.0
		lane_velocity = 0.0
	else:
		lane_velocity = move_toward(
			lane_velocity,
			target_velocity,
			acceleration * delta
		)

	# Movimiento lógico suave
	exact_x += lane_velocity * delta
	exact_x = clamp(exact_x, START_X, lane_width)

	# Render pixel-perfect
	player_node.position.x = round(exact_x)

	# Idle fijo
	var anim = player_node.anim_player
	if anim.current_animation != "idle":
		anim.play("idle")

	current_progress = (
		exact_x - START_X
	) / (
		lane_width - START_X
	)

	if current_progress >= 1.0 and not is_finished:
		is_finished = true
		lane_finished.emit(player_id)


func get_player_id() -> int:
	return player_id


func get_progress() -> float:
	return current_progress


func highlight_winner() -> void:
	is_winner = true

	if background:
		var tween = create_tween()
		tween.set_loops(3)
		tween.tween_property(
			background,
			"modulate",
			Color.GOLD,
			0.2
		)
		tween.tween_property(
			background,
			"modulate",
			Color.WHITE,
			0.2
		)


func highlight_loser() -> void:
	if background:
		var tween = create_tween()
		tween.tween_property(
			background,
			"modulate",
			Color(0.5, 0.5, 0.5),
			0.5
		)


func reset() -> void:
	current_progress = 0.0
	lane_velocity = 0.0
	target_velocity = 0.0
	exact_x = START_X
	is_winner = false
	is_finished = false

	if player_node:
		player_node.position.x = round(START_X)
		player_node.anim_player.speed_scale = 0.5
		player_node.anim_player.play("idle")

	if background:
		background.modulate = Color.WHITE

	print("🔄 Lane P%d reseteado" % player_id)   
