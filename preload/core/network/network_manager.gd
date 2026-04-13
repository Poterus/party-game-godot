extends Node

# ==========================================
# MEMORIA Y ESTADO GLOBAL
# ==========================================
var current_play_mode: String = "solo" # Puede ser: "solo", "local", o "online"
var host_plays_on_pc: bool = true # <-- ¡AQUÍ ESTÁ LA VARIABLE QUE FALTABA!

# Aquí guardaremos la posición exacta del joystick de cada jugador
var player_joysticks: Dictionary = {}

# --- SERVIDOR WEBSOCKET (Para jugar) ---
const WS_PORT = 8080
var ws_server := TCPServer.new()
var connected_phones: Array = [] # Array genérico para permitir jugadores falsos

# --- SERVIDOR HTTP (Para enviar el HTML del mando) ---
const HTTP_PORT = 8000
var http_server := TCPServer.new()
var web_clients: Array[StreamPeerTCP] = []
var html_content: String = ""

# --- SEÑALES ---
signal player_joined(player_id: int)
signal player_joystick(player_id: int, axis_x: float, axis_y: float)

# ==========================================
# INICIO Y BUCLE PRINCIPAL
# ==========================================
func _ready() -> void:
	_setup_host_pc_controls()
	# 1. Cargar el archivo HTML a la memoria
	_load_html_file()
	
	# 2. Iniciar el servidor WebSocket (El juego)
	if ws_server.listen(WS_PORT) == OK:
		print("✅ Servidor WebSocket en puerto ", WS_PORT)
	
	# 3. Iniciar el servidor HTTP (La web)
	if http_server.listen(HTTP_PORT) == OK:
		print("🌐 Servidor Web (HTML) en puerto ", HTTP_PORT)

func _load_html_file() -> void:
	var file = FileAccess.open("res://web/index.html", FileAccess.READ)
	if file:
		html_content = file.get_as_text()
		file.close()
	else:
		push_error("❌ No se encontró el index.html en res://web/index.html")

func _process(_delta: float) -> void:
	_process_http_server()
	_process_websocket_server()

# ==========================================
# LÓGICA DEL SERVIDOR WEB (Entrega el Mando)
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
	var header = "HTTP/1.1 200 OK\r\n"
	header += "Content-Type: text/html; charset=UTF-8\r\n"
	header += "Content-Length: " + str(body_bytes.size()) + "\r\n"
	header += "Connection: close\r\n\r\n"
	
	peer.put_data(header.to_utf8_buffer())
	peer.put_data(body_bytes)
	OS.delay_msec(10)
	
# ==========================================
# LÓGICA DEL WEBSOCKET (Recibe y Responde)
# ==========================================
func _process_websocket_server() -> void:
	# 1. Aceptar nuevos móviles
	if ws_server.is_connection_available():
		var tcp_peer: StreamPeerTCP = ws_server.take_connection()
		var ws := WebSocketPeer.new()
		ws.accept_stream(tcp_peer)
		connected_phones.append(ws)
		print("📱 ¡Nuevo dispositivo conectado al WebSocket!")

	# 2. Leer los mensajes
	for i in range(connected_phones.size() - 1, -1, -1):
		var ws = connected_phones[i]
		
		# ESCUDO: Si es un jugador falso de Debug, no intentamos leer su red
		if typeof(ws) == TYPE_STRING:
			continue
			
		ws.poll()
		var state = ws.get_ready_state()
		
		if state == WebSocketPeer.STATE_OPEN:
			while ws.get_available_packet_count() > 0:
				# Quitamos los ":" para que Godot no exija un tipo estricto
				var packet = ws.get_packet() 
				var message = packet.get_string_from_utf8()
				
				var data = JSON.parse_string(message)
				if typeof(data) == TYPE_DICTIONARY:
					_handle_phone_message(ws, data)
				else:
					print("Mensaje no reconocido: ", message)
				
		elif state == WebSocketPeer.STATE_CLOSED:
			print("Un mando se ha desconectado.")
			connected_phones.remove_at(i)

# ==========================================
# EL CEREBRO DE LOS INPUTS (Traductor JSON)
# ==========================================
func _handle_phone_message(ws: WebSocketPeer, data: Dictionary) -> void:
	if not data.has("type"): return
	
	match data["type"]:
		"join":
			var phone_index = connected_phones.find(ws)
			var player_id = 0
			
			if host_plays_on_pc:
				player_id = phone_index + 2
			else:
				player_id = phone_index + 1
				
			print("Jugador ", player_id, " ha pulsado Unirse.")
			
			var welcome_msg = {"type": "welcome", "player_id": player_id}
			if typeof(ws) == TYPE_OBJECT:
				ws.send_text(JSON.stringify(welcome_msg))
				var layout_msg = {"type": "change_layout", "layout": "joystick"}
				ws.send_text(JSON.stringify(layout_msg))
			
			player_joined.emit(player_id)
			
		"input":
			var player_id = connected_phones.find(ws) + 1
			var action_name = data["action"] + "_" + str(player_id) 
			var is_pressed = data["state"] == "pressed"
			
			if not InputMap.has_action(action_name):
				InputMap.add_action(action_name)
				
			if is_pressed:
				Input.action_press(action_name)
			else:
				Input.action_release(action_name)
				
		"joystick":
			var player_id = connected_phones.find(ws) + 1
			player_joysticks[player_id] = Vector2(float(data["axis_x"]), float(data["axis_y"]))

# ==========================================
# CONTROLES DE PC Y HERRAMIENTAS DE DEBUG
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
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key_code in pc_controls[action]:
			var key_event = InputEventKey.new()
			key_event.keycode = key_code
			InputMap.action_add_event(action, key_event)
			
	var mouse_event = InputEventMouseButton.new()
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("dash_1", mouse_event)

# Función para testear sin móviles (Ya está bien tabulada y separada de lo anterior)
func debug_add_fake_player() -> void:
	if connected_phones.size() < 7:
		connected_phones.append("fake_socket_debug") 
		
		var new_id = 0
		if host_plays_on_pc:
			new_id = connected_phones.size() + 1
		else:
			new_id = connected_phones.size()
			
		player_joined.emit(new_id)
		print("DEBUG: Jugador falso añadido. ID: ", new_id)
	else:
		print("DEBUG: Límite de 8 jugadores alcanzado.")

# Función centralizada para cambiar el mando de todos los móviles
func send_layout_to_all(layout_name: String) -> void:
	var msg = {"type": "change_layout", "layout": layout_name}
	var msg_string = JSON.stringify(msg)
	
	for ws in connected_phones:
		# Verificamos que sea un objeto real y no un fake de debug
		if typeof(ws) == TYPE_OBJECT and ws.has_method("send_text"):
			ws.send_text(msg_string)
