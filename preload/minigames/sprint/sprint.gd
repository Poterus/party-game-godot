extends BaseMinigame
class_name Sprint

# ====================================================
# SPRINT: Carrera horizontal DINÁMICA
# Crea lanes automáticamente según jugadores activos
# ====================================================

# --- CONFIGURACIÓN EXPORTADA ---
@export var sprint_lane_scene: PackedScene  # Arrastra sprint_lane.tscn aquí
@export var lane_spacing: float = 120.0  # Espacio vertical entre lanes
@export var start_y_offset: float = 50.0  # Donde empieza el primer lane
@export var speed_per_press: float = 0.05  # % de progreso por pulsación

# --- ESTADO DEL JUEGO ---
var player_progress: Dictionary = {}  # player_id -> float (0.0 a 1.0)
var finish_order: Array = []  # Orden de llegada
var button_press_count: Dictionary = {}  # Contador de pulsaciones
var lanes: Dictionary = {}  # player_id -> SprintLane nodo (referencia)

# --- REFERENCIAS DE NODOS ---
@onready var lanes_container = $LanesContainer

func _ready() -> void:
	# 1. Inicializar diccionarios de estado
	for p_id in NetworkManager.player_faces.keys():
		player_progress[p_id] = 0.0
		button_press_count[p_id] = 0
	
	# 2. IMPORTANTE: Crear lanes ANTES de super()._ready()
	_instantiate_lanes()
	
	# 3. Llamar al _ready() del padre (BaseMinigame)
	super()
	
	# 4. Configurar layout del minijuego
	minigame_layout = "sprint"
	NetworkManager.current_minigame_layout = minigame_layout
	
	print("✅ Sprint iniciado con %d jugadores" % lanes.size())

func _process(delta: float) -> void:
	super(delta)
	# No hay lógica adicional por frame en Sprint
	# Todo es event-driven (pulsaciones)

func _input(event: InputEvent) -> void:
	"""Captura las pulsaciones del botón 'dash' de cada jugador."""
	if not game_active:
		return
	
	# Revisar cada jugador activo
	for p_id in NetworkManager.player_faces.keys():
		var action_name = "dash_" + str(p_id)
		
		if Input.is_action_just_pressed(action_name):
			_on_player_button_pressed(p_id)

# =========================================================
# CREACIÓN DINÁMICA DE LANES
# =========================================================

func _instantiate_lanes() -> void:
	"""
	Crea un Lane por cada jugador de forma dinámica.
	Reutiliza la escena SprintLane según el número de jugadores.
	
	Esto se llama en _ready() ANTES de que el juego empiece.
	"""
	
	if not sprint_lane_scene:
		push_error("❌ ERROR: 'sprint_lane_scene' no asignado en el inspector. Arrastra res://core/prefabs/sprint_lane/sprint_lane.tscn")
		return
	
	# Limpiar lanes viejos si existieran
	for child in lanes_container.get_children():
		child.queue_free()
	lanes.clear()
	
	var player_ids = NetworkManager.player_faces.keys()
	var face_dict = NetworkManager.player_faces
	
	print("📍 Creando lanes dinámicamente...")
	print("   - Total jugadores: %d" % player_ids.size())
	
	# Crear un lane por cada jugador
	for i in range(player_ids.size()):
		var p_id = player_ids[i]
		var face = face_dict.get(p_id, null)
		
		# 1. Instanciar la escena de lane
		var new_lane: SprintLane = sprint_lane_scene.instantiate()
		lanes_container.add_child(new_lane)
		
		# 2. Posicionar verticalmente (stack)
		new_lane.position = Vector2(0, start_y_offset + (i * lane_spacing))
		
		# 3. Configurar el lane (ID, foto del jugador)
		new_lane.setup(p_id, face)
		
		# 4. Guardar referencia para acceso rápido
		lanes[p_id] = new_lane
		
		print("   ✓ Lane P%d en Y=%.0f" % [p_id, new_lane.position.y])

# =========================================================
# LÓGICA DE PULSACIONES Y PROGRESO
# =========================================================

func _on_player_button_pressed(player_id: int) -> void:
	"""
	Se llama cada vez que un jugador pulsa el botón "dash".
	Incrementa el progreso y actualiza visualización.
	"""
	
	# 1. Incrementar contador y progreso
	button_press_count[player_id] += 1
	player_progress[player_id] += speed_per_press
	player_progress[player_id] = min(player_progress[player_id], 1.0)
	
	# 2. Actualizar visualización del lane
	if lanes.has(player_id):
		lanes[player_id].update_progress(player_progress[player_id])
		# Opcional: efecto de shake en el carril
		# lanes[player_id].shake_effect()
	
	# 3. Enviar feedback al móvil (vibración, actualización de barra)
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
	
	# 4. Revisar si alcanzó 100%
	if player_progress[player_id] >= 1.0:
		_on_player_finished(player_id)

func _on_player_finished(player_id: int) -> void:
	"""
	Se llama cuando un jugador alcanza 100% de progreso.
	Registra la victoria y termina el minijuego.
	"""
	
	# Evitar múltiples ganadores
	if finish_order.size() > 0:
		print("⚠️ P%d terminó pero ya hay ganador" % player_id)
		return
	
	# Registrar ganador
	finish_order.append(player_id)
	
	print("🏆 ¡GANADOR! P%d completó en %d pulsaciones" % [
		player_id, 
		button_press_count[player_id]
	])
	
	# Efecto visual en el lane ganador
	if lanes.has(player_id):
		lanes[player_id].highlight_winner()
	
	# Enviar notificación al móvil del ganador
	NetworkManager.send_to_player(player_id, {
		"type": "race_finished",
		"winner": true,
		"position": 1,
		"presses": button_press_count[player_id]
	})
	
	# Terminar el minijuego
	_end_minigame_base()

# =========================================================
# GANCHOS DE BASEMINIGAME (virtuales)
# =========================================================

func _minigame_start() -> void:
	"""
	Se llama después del countdown.
	El juego está listo para recibir pulsaciones.
	"""
	print("🎮 Sprint comenzado - ¡A pulsar!")

func _minigame_end() -> void:
	"""
	Se llama cuando termina el minijuego.
	Aquí puedes parar música, limpiar efectos, etc.
	"""
	print("🏁 Sprint terminado")

func _minigame_player_died(id: int) -> void:
	"""
	En Sprint no hay "muerte", pero este gancho está aquí
	para consistencia con otros minijuegos.
	"""
	if lanes.has(id):
		lanes[id].highlight_loser()

func _setup_custom_player(player: Node2D) -> void:
	"""
	Se llama por cada jugador spawneado.
	En Sprint no necesitamos setup especial.
	"""
	pass

# =========================================================
# UTILIDADES PÚBLICAS
# =========================================================

func get_lane(player_id: int) -> SprintLane:
	"""Retorna el lane de un jugador específico."""
	return lanes.get(player_id, null)

func get_all_lanes() -> Dictionary:
	"""Retorna todos los lanes (player_id -> SprintLane)."""
	return lanes.duplicate()

func get_total_lanes() -> int:
	"""Retorna cantidad de lanes activos."""
	return lanes.size()

func get_player_progress(player_id: int) -> float:
	"""Retorna el progreso de un jugador (0.0-1.0)."""
	return player_progress.get(player_id, 0.0)

func get_button_presses(player_id: int) -> int:
	"""Retorna cantidad de pulsaciones de un jugador."""
	return button_press_count.get(player_id, 0)

func get_winner() -> int:
	"""Retorna el ID del ganador (-1 si aún no hay)."""
	return finish_order[0] if finish_order.size() > 0 else -1

func reset_game() -> void:
	"""Reinicia el estado del juego (para pruebas)."""
	for p_id in player_progress.keys():
		player_progress[p_id] = 0.0
		button_press_count[p_id] = 0
		if lanes.has(p_id):
			lanes[p_id].reset()
	
	finish_order.clear()
	print("🔄 Juego reseteado")

# =========================================================
# DEBUG
# =========================================================

func _input_debug(event: InputEvent) -> void:
	"""Herramientas para testing (opcional)."""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _on_player_button_pressed(1)
			KEY_2: _on_player_button_pressed(2)
			KEY_3: _on_player_button_pressed(3)
			KEY_4: _on_player_button_pressed(4)
			KEY_R: reset_game()
