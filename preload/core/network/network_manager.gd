extends Node

# ==========================================
# MEMORIA Y ESTADO GLOBAL
# ==========================================
var current_play_mode: String = "solo" # "solo", "local", "online"
var current_minigame_layout: String = "joystick" # Layout que usa el minijuego activo
var game_phase: String = "lobby" # "lobby", "menu", "playing"
var host_plays_on_pc: bool = false 

# Diccionarios de estado de los jugadores
var player_joysticks: Dictionary = {}
var player_faces: Dictionary = {}
var player_ips: Dictionary = {}      # player_id -> IP string
var ws_ips: Dictionary = {}          # ws object id -> IP string (temporal hasta join)

# --- SERVIDOR WEBSOCKET (Juego) ---
const WS_PORT = 8080
var ws_server := TCPServer.new()
var connected_phones: Array = [] 

# --- SERVIDOR HTTP (Web del Mando) ---
const HTTP_PORT = 8000
var http_server := TCPServer.new()
var web_clients: Array[StreamPeerTCP] = []
var html_content: String = ""

# --- HOST ---
var host_player_id: int = -1 # -1 = sin host asignado aún

# --- SEÑALES ---
signal player_joined(player_id: int)
signal player_joystick(player_id: int, axis_x: float, axis_y: float)
signal player_face_updated(player_id: int, texture: ImageTexture)
signal host_changed(new_id: int)
signal host_start_game

# ==========================================
# INICIO Y BUCLE PRINCIPAL
# ==========================================
func _ready() -> void:
	_setup_host_pc_controls()
	_load_html_file()
	
	if ws_server.listen(WS_PORT) == OK:
		print("✅ Servidor WebSocket en puerto ", WS_PORT)
	if http_server.listen(HTTP_PORT) == OK:
		print("🌐 Servidor Web (HTML) en puerto ", HTTP_PORT)

func _load_html_file() -> void:
	var path = "res://web/index.html"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		html_content = file.get_as_text()
		file.close()
	else:
		push_error("❌ No se encontró el index.html en: ", path)
		html_content = "<h1>Error: Falta index.html</h1>"

func _process(_delta: float) -> void:
	_process_http_server()
	_process_websocket_server()

# ==========================================
# LÓGICA DEL SERVIDOR WEB
# ==========================================
func _process_http_server() -> void:
	if http_server.is_connection_available():
		var peer: StreamPeerTCP = http_server.take_connection()
		web_clients.append(peer)
		
	for i in range(web_clients.size() - 1, -1, -1):
		var client = web_clients[i]
		client.poll()
		
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			if client.get_available_bytes() > 0:
				var request = client.get_utf8_string(client.get_available_bytes())
				if request.begins_with("GET"):
					_send_html_response(client)
		elif client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			web_clients.remove_at(i)
			
func _send_html_response(peer: StreamPeerTCP) -> void:
	var body_bytes = html_content.to_utf8_buffer()
	
	# Mejoramos las cabeceras HTTP para navegadores móviles
	var header = "HTTP/1.1 200 OK\r\n"
	header += "Content-Type: text/html; charset=UTF-8\r\n"
	header += "Cache-Control: no-cache, no-store, must-revalidate\r\n" # Evita que los móviles guarden webs viejas
	header += "Content-Length: " + str(body_bytes.size()) + "\r\n"
	header += "Connection: close\r\n\r\n"
	
	peer.put_data(header.to_utf8_buffer())
	peer.put_data(body_bytes)
	
# ==========================================
# LÓGICA DEL WEBSOCKET
# ==========================================
func _process_websocket_server() -> void:
	if ws_server.is_connection_available():
		var tcp_peer: StreamPeerTCP = ws_server.take_connection()
		var peer_ip = tcp_peer.get_connected_host()
		var ws := WebSocketPeer.new()
		ws.accept_stream(tcp_peer)
		connected_phones.append(ws)
		ws_ips[ws.get_instance_id()] = peer_ip
		print("📱 ¡Nuevo dispositivo conectado desde ", peer_ip, "!")

	for i in range(connected_phones.size() - 1, -1, -1):
		var ws = connected_phones[i]
		if typeof(ws) == TYPE_STRING: # Skip jugadores de debug
			continue
			
		ws.poll()
		var state = ws.get_ready_state()
		
		if state == WebSocketPeer.STATE_OPEN:
			while ws.get_available_packet_count() > 0:
				var packet = ws.get_packet()
				var message = packet.get_string_from_utf8()
				
				
				var data = JSON.parse_string(message)
				
				if typeof(data) == TYPE_DICTIONARY:
					# --- CHIVATO DE TIPO ---
					_handle_phone_message(ws, data)
					
		elif state == WebSocketPeer.STATE_CLOSED:
			var disconnected_id = _get_player_id_from_ws(ws)
			print("📴 Jugador ", disconnected_id, " desconectado. Limpiando datos...")
			ws_ips.erase(ws.get_instance_id())
			player_joysticks.erase(disconnected_id)
			connected_phones.remove_at(i)
			# player_faces y player_ips se conservan para permitir reconexión por IP

# ==========================================
# GESTIÓN DE JUGADORES E INPUTS
# ==========================================

# Función auxiliar MUY IMPORTANTE para unificar cómo calculamos el ID
func _get_player_id_from_ws(ws) -> int:
	var index = connected_phones.find(ws)
	if host_plays_on_pc:
		return index + 2 # El Host es el 1, los móviles empiezan en el 2
	else:
		return index + 1 # Todos son móviles, empiezan en el 1

func _handle_phone_message(ws: WebSocketPeer, data: Dictionary) -> void:
	if not data.has("type"): return
	
	var player_id = _get_player_id_from_ws(ws)
	
	match data["type"]:
		"join":
			# Comprobar si esta IP ya tenía un jugador (reconexión)
			var peer_ip = ws_ips.get(ws.get_instance_id(), "")
			var recovered_id = -1
			for pid in player_ips:
				if player_ips[pid] == peer_ip and peer_ip != "":
					recovered_id = pid
					break
			
			if recovered_id > 0:
				# Reconexión: reasignar el mismo ID
				player_id = recovered_id
				print("🔄 Reconexión detectada: Jugador ", player_id, " desde ", peer_ip)
				ws.send_text(JSON.stringify({"type": "welcome", "player_id": player_id}))
				# Si tenía foto, mandársela de vuelta no hace falta — el HTML ya la tiene
				# Restaurar host_status si era el host
				var all_ids = player_faces.keys()
				if player_id == host_player_id:
					ws.send_text(JSON.stringify({"type": "host_status", "is_host": true, "player_ids": all_ids}))
					var host_layout = "lobby_host" if game_phase == "lobby" else "menu"
					ws.send_text(JSON.stringify({"type": "change_layout", "layout": host_layout}))
				else:
					ws.send_text(JSON.stringify({"type": "host_status", "is_host": false, "player_ids": all_ids}))
					var player_layout = "espera" if game_phase != "playing" else current_minigame_layout
					ws.send_text(JSON.stringify({"type": "change_layout", "layout": player_layout}))
				# Si tenía foto, re-emitir para que el lobby la muestre
				if player_faces.has(player_id):
					player_face_updated.emit(player_id, player_faces[player_id])
			else:
				# Jugador nuevo
				print("Jugador ", player_id, " ha pulsado Unirse.")
				if peer_ip != "":
					player_ips[player_id] = peer_ip
				ws.send_text(JSON.stringify({"type": "welcome", "player_id": player_id}))
				player_joined.emit(player_id)
			
		"input":
			var action_name = data["action"] + "_" + str(player_id) 
			var is_pressed = data["state"] == "pressed"
			
			if not InputMap.has_action(action_name): InputMap.add_action(action_name)
				
			if is_pressed: Input.action_press(action_name)
			else: Input.action_release(action_name)
			
			# Si es el host, simular eventos de UI para navegar menús
			if player_id == host_player_id:
				var ui_map = {
					"up": "ui_up",
					"down": "ui_down",
					"left": "ui_left",
					"right": "ui_right",
					"dash": "ui_accept"
				}
				var ui_action = ui_map.get(data["action"], "")
				if ui_action != "":
					var ev = InputEventAction.new()
					ev.action = ui_action
					ev.pressed = is_pressed
					Input.parse_input_event(ev)
				
		"joystick":
			player_joysticks[player_id] = Vector2(float(data["axis_x"]), float(data["axis_y"]))
			
		"face_photo":
			if data.has("data"):
				_process_face_photo(player_id, data["data"])
		
		"transfer_host":
			# Solo el host actual puede transferir
			if player_id == host_player_id and data.has("to_player_id"):
				set_host(int(data["to_player_id"]))
		
		"start_game":
			# Solo el host puede arrancar la partida
			if player_id == host_player_id:
				host_start_game.emit()

func _process_face_photo(player_id: int, base64_data: String) -> void:
	# 1. Convertir Base64 a raw bytes
	var raw_data = Marshalls.base64_to_raw(base64_data)
	if raw_data.is_empty():
		push_error("Error decodificando la foto Base64 del jugador ", player_id)
		return
		
	# 2. Intentar cargar los bytes como PNG primero, luego JPG como fallback
	var image := Image.new()
	var error = image.load_png_from_buffer(raw_data)
	if error != OK:
		error = image.load_jpg_from_buffer(raw_data)
	
	if error == OK:
		# 3. Crear una textura
		var texture = ImageTexture.create_from_image(image)
		
		# 4. TRUCO PIXEL ART: Anulamos el filtro de suavizado para que encaje con el juego
		# (Aunque en Godot 4 esto se suele manejar en los Project Settings o en el CanvasItem, 
		# no viene mal recordarlo. Si tu juego es Pixel Art, la foto no desentonará).
		
		# 5. Guardamos en el diccionario y avisamos al resto del juego
		player_faces[player_id] = texture
		player_face_updated.emit(player_id, texture)
		print("📸 Foto recibida y procesada con éxito para Jugador ", player_id)
		# El primero en mandar foto es el host
		if host_player_id == -1:
			set_host(player_id)
	else:
		push_error("Error convirtiendo bytes a imagen. Código: ", error)

# ==========================================
# CONTROLES Y HERRAMIENTAS
# ==========================================
func _setup_host_pc_controls() -> void:
	var pc_controls = {
		"up_1": [KEY_W, KEY_UP],
		"down_1": [KEY_S, KEY_DOWN],
		"left_1": [KEY_A, KEY_LEFT],
		"right_1": [KEY_D, KEY_RIGHT],
		"dash_1": [KEY_SPACE, KEY_ENTER]
	}
	for action in pc_controls:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key_code in pc_controls[action]:
			var key_event = InputEventKey.new()
			key_event.keycode = key_code
			InputMap.action_add_event(action, key_event)
			

# Manda un mensaje JSON a un jugador concreto por su ID
func send_to_player(player_id: int, data: Dictionary) -> void:
	var index = player_id - (2 if host_plays_on_pc else 1)
	if index >= 0 and index < connected_phones.size():
		var ws = connected_phones[index]
		if typeof(ws) == TYPE_OBJECT and ws.has_method("send_text"):
			ws.send_text(JSON.stringify(data))

# Asigna el host, avisa a todos los móviles y emite la señal
func set_host(new_id: int) -> void:
	var old_id = host_player_id
	host_player_id = new_id
	var all_ids = player_faces.keys()
	# Avisar al móvil que pierde el host
	if old_id > 0:
		send_to_player(old_id, {"type": "host_status", "is_host": false, "player_ids": all_ids})
	# Avisar al móvil que gana el host (incluye lista de jugadores para el panel DAR HOST)
	send_to_player(new_id, {"type": "host_status", "is_host": true, "player_ids": all_ids})
	# Layout del host según fase actual
	if game_phase == "lobby":
		send_to_player(new_id, {"type": "change_layout", "layout": "lobby_host"})
	host_changed.emit(new_id)
	print("👑 Host asignado al Jugador ", new_id)

func debug_add_fake_player() -> void:
	# Calculamos la siguiente ID libre inteligentemente
	var fake_id = 1
	if not player_faces.is_empty():
		# Si ya hay gente (móviles o bots), cogemos el número más alto y le sumamos 1
		var ids = player_faces.keys()
		ids.sort() # Ordenamos de menor a mayor
		fake_id = ids[-1] + 1 
	
	var default_icon = load("res://assets/sprites/icon.svg")
	
	var img = default_icon.get_image()
	var fake_texture = ImageTexture.create_from_image(img)
	
	if not "player_faces" in self:
		printerr("Aviso: No encontré el diccionario 'player_faces' en NetworkManager.")
	else:
		player_faces[fake_id] = fake_texture
	
	player_face_updated.emit(fake_id, fake_texture)
	
	print("DEBUG: Jugador fantasma añadido de forma segura con ID: ", fake_id)
		# Crear las acciones de input para este jugador
	var actions = ["up", "down", "left", "right", "dash"]
	for action in actions:
		var action_name = action + "_" + str(fake_id)
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
	

	
func send_layout_to_all(layout_name: String) -> void:
	var msg_string = JSON.stringify({"type": "change_layout", "layout": layout_name})
	for ws in connected_phones:
		if typeof(ws) == TYPE_OBJECT and ws.has_method("send_text"):
			ws.send_text(msg_string)
