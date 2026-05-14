extends BaseMinigame
class_name Sprint

# ====================================================
# SPRINT: Carrera horizontal DINÁMICA
# - Max 4 jugadores por columna
# - 5-8 jugadores: dos columnas
# - SIN scaling: lanes mantienen su tamaño original
# ====================================================

# --- CONFIGURACIÓN EXPORTADA ---
@export var sprint_lane_scene: PackedScene
@export var speed_per_press: float = 0.05

# --- ESTADO DEL JUEGO ---
var player_progress: Dictionary = {}
var finish_order: Array = []
var button_press_count: Dictionary = {}
var lanes: Dictionary = {}

# --- CONSTANTES ---
const LANE_W = 480.0     # Ancho real del lane en el editor
const LANE_H = 50.0      # Altura real del lane en el editor
const LANE_MARGIN = 5.0  # Margen entre lanes
const MAX_PER_COLUMN = 4 # Máximo lanes por columna
const MAX_PLAYERS = 8    # Máximo total de jugadores

# --- REFERENCIAS DE NODOS ---
@onready var lanes_container = $LanesContainer

func _ready() -> void:
	if NetworkManager.player_faces.is_empty():
		NetworkManager.debug_add_fake_player()
	
	for p_id in NetworkManager.player_faces.keys():
		player_progress[p_id] = 0.0
		button_press_count[p_id] = 0
	
	_instantiate_lanes()
	
	super()
	
	minigame_layout = "sprint"
	NetworkManager.current_minigame_layout = minigame_layout
	
	print("✅ Sprint iniciado con %d jugadores" % lanes.size())

func _process(delta: float) -> void:
	super(delta)

func _input(event: InputEvent) -> void:
	if not game_active:
		return
	
	for p_id in NetworkManager.player_faces.keys():
		var action_name = "dash_" + str(p_id)
		if Input.is_action_just_pressed(action_name):
			_on_player_button_pressed(p_id)

# =========================================================
# CREACIÓN DINÁMICA DE LANES
# =========================================================

func _instantiate_lanes() -> void:
	if not sprint_lane_scene:
		push_error("❌ ERROR: 'sprint_lane_scene' no asignado")
		return
	
	for child in lanes_container.get_children():
		child.queue_free()
	lanes.clear()
	
	var player_ids = NetworkManager.player_faces.keys()
	var face_dict = NetworkManager.player_faces
	var total = min(player_ids.size(), MAX_PLAYERS)
	
	var screen_w = ProjectSettings.get_setting("display/window/size/viewport_width")
	var screen_h = ProjectSettings.get_setting("display/window/size/viewport_height")
	
	# Determinar columnas
	var columns = 1 if total <= MAX_PER_COLUMN else 2
	var lanes_per_column = ceil(total / float(columns))
	
	# Centrado vertical
	var slot_h = LANE_H + LANE_MARGIN
	var total_height = lanes_per_column * slot_h
	var center_y = (screen_h / 2.0) - (total_height / 2.0)
	
	# Centrado horizontal por columnas
	var column_width = screen_w / float(columns)
	var lane_x_offset = (column_width - LANE_W) / 2.0
	
	for i in range(total):
		var p_id = player_ids[i]
		var col = i / int(MAX_PER_COLUMN)
		var row = i % int(MAX_PER_COLUMN)
		
		var new_lane: SprintLane = sprint_lane_scene.instantiate()
		lanes_container.add_child(new_lane)
		
		var pos_x = (column_width * col) + lane_x_offset
		var pos_y = center_y + (row * slot_h)
		new_lane.position = Vector2(pos_x, pos_y)
		
		new_lane.setup(p_id, face_dict.get(p_id, null))
		lanes[p_id] = new_lane

# =========================================================
# LÓGICA DE PULSACIONES Y PROGRESO
# =========================================================

func _on_player_button_pressed(player_id: int) -> void:
	button_press_count[player_id] += 1
	player_progress[player_id] += speed_per_press
	player_progress[player_id] = min(player_progress[player_id], 1.0)
	
	if lanes.has(player_id):
		lanes[player_id].update_progress(player_progress[player_id])
	
	NetworkManager.send_to_player(player_id, {
		"type": "button_feedback",
		"progress": player_progress[player_id],
		"button_count": button_press_count[player_id]
	})
	
	print("🏃 P%d pulsa #%d. Progreso: %.0f%%" % [
		player_id,
		button_press_count[player_id],
		player_progress[player_id] * 100
	])
	
	if player_progress[player_id] >= 1.0:
		_on_player_finished(player_id)

func _on_player_finished(player_id: int) -> void:
	if finish_order.size() > 0:
		print("⚠️ P%d terminó pero ya hay ganador" % player_id)
		return
	
	finish_order.append(player_id)
	print("🏆 ¡GANADOR! P%d en %d pulsaciones" % [player_id, button_press_count[player_id]])
	
	if lanes.has(player_id):
		lanes[player_id].highlight_winner()
	
	NetworkManager.send_to_player(player_id, {
		"type": "race_finished",
		"winner": true,
		"position": 1,
		"presses": button_press_count[player_id]
	})
	
	_end_minigame_base()

# =========================================================
# GANCHOS DE BASEMINIGAME
# =========================================================

func _minigame_start() -> void:
	print("🎮 Sprint comenzado - ¡A pulsar!")

func _minigame_end() -> void:
	print("🏁 Sprint terminado")

func _minigame_player_died(id: int) -> void:
	if lanes.has(id):
		lanes[id].highlight_loser()

func _setup_custom_player(player: Node2D) -> void:
	pass

# =========================================================
# UTILIDADES
# =========================================================

func get_lane(player_id: int) -> SprintLane:
	return lanes.get(player_id, null)

func get_player_progress(player_id: int) -> float:
	return player_progress.get(player_id, 0.0)

func get_winner() -> int:
	return finish_order[0] if finish_order.size() > 0 else -1

func reset_game() -> void:
	for p_id in player_progress.keys():
		player_progress[p_id] = 0.0
		button_press_count[p_id] = 0
		if lanes.has(p_id):
			lanes[p_id].reset()
	finish_order.clear()
	print("🔄 Juego reseteado")
