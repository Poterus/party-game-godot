extends Control

# 1. PRECARGAMOS LA ESCENA DE LA CASILLA (Asegúrate de que la ruta es correcta)
const PLAYER_SLOT_SCENE = preload("res://ui/menus/lobby/lobby_player_slot.tscn")

@onready var label_ip: Label = $MarginContainer/MainVBox/HBox/LocalPanel/LabelIP
@onready var texture_qr: QRCodeRect = $MarginContainer/MainVBox/HBox/LocalPanel/TextureQR

# 2. CAMBIAMOS EL ITEMLIST POR EL GRIDCONTAINER
@onready var grid_players: GridContainer = $MarginContainer/MainVBox/HBox/SteamPanel/GridPlayers

@onready var button_back: Button = $MarginContainer/MainVBox/HBoxContainer/ButtonBack
@onready var button_start: Button = $MarginContainer/MainVBox/HBoxContainer/ButtonStart
@onready var button_debug_add: Button = %ButtonDebugAdd

func _ready() -> void:
	NetworkManager.player_face_updated.connect(_on_player_ready)
	NetworkManager.player_customization_updated.connect(_on_player_customization_updated)
	
	_generate_lobby_qr()
	
	button_back.pressed.connect(_on_back_pressed)
	button_start.pressed.connect(_on_start_pressed)
	button_debug_add.pressed.connect(_on_debug_add_pressed)
	
	_update_start_button()
	
	NetworkManager.game_phase = "lobby"
	# Al entrar al lobby, mandar "espera" a todos los que ya estén conectados
	NetworkManager.send_layout_to_all("espera")
	
	# El host puede arrancar desde su móvil
	NetworkManager.host_start_game.connect(_on_start_pressed)
	
	# Repoblar slots si volvemos al lobby con jugadores ya conectados
	for id in NetworkManager.player_faces.keys():
		_on_player_ready(id, NetworkManager.player_faces[id])
	
	# Restaurar layout del host
	if NetworkManager.host_player_id > 0:
		NetworkManager.send_to_player(NetworkManager.host_player_id, {"type": "change_layout", "layout": "lobby_host"})
	
func _generate_lobby_qr() -> void:
	var local_ip = "127.0.0.1"
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10."):
			local_ip = ip
			break
	
	var url = "http://" + local_ip + ":8000/"
	label_ip.text = url
	texture_qr.data = url.to_utf8_buffer()

# --- LÓGICA DE APARICIÓN DE JUGADORES ---
func _on_player_ready(id: int, texture: ImageTexture) -> void:
	var slot_name = "PlayerSlot_" + str(id)
	
	if grid_players.has_node(slot_name):
		var existing_slot = grid_players.get_node(slot_name)
		existing_slot.configure_slot(id, texture, Color.WHITE)
		return
	
	var new_slot = PLAYER_SLOT_SCENE.instantiate()
	new_slot.name = slot_name
	grid_players.add_child(new_slot)
	new_slot.configure_slot(id, texture, Color.WHITE)
	
	# Todos van a personalización primero (incluido el host).
	# Al pulsar LISTO: el host recibirá "lobby_host", el resto "espera".
	NetworkManager.send_to_player(id, {"type": "change_layout", "layout": "lobby"})
	
	_update_start_button()
	
func _on_player_customization_updated(id: int, skin_color: Color, hat: int) -> void:
	var slot_name = "PlayerSlot_" + str(id)
	if grid_players.has_node(slot_name):
		grid_players.get_node(slot_name).update_customization(skin_color, hat)

func _update_start_button() -> void:
	var players_ready = grid_players.get_child_count()
	
	# Desbloqueamos si hay al menos 1 o 2 jugadores (Cámbialo a 2 para el juego real)
	if players_ready >= 1: 
		button_start.disabled = false
		button_start.text = "Start Game (" + str(players_ready) + " Ready)"
	else:
		button_start.disabled = true
		button_start.text = "Waiting for photos..."

# --- BOTONES ---
func _on_start_pressed() -> void:
	# 1. Mandar a todos que giren el móvil a horizontal
	NetworkManager.send_layout_to_all("gira")
	# 2. Esperar 3 segundos para que lo hagan
	button_start.disabled = true
	button_start.text = "Cargando..."
	await get_tree().create_timer(1.5).timeout
	# 3. Al host le mandamos "menu" para que pueda navegar, al resto "espera"
	for id in NetworkManager.player_faces.keys():
		if id == NetworkManager.host_player_id:
			NetworkManager.send_to_player(id, {"type": "change_layout", "layout": "menu"})
		else:
			NetworkManager.send_to_player(id, {"type": "change_layout", "layout": "espera"})
	# 4. Navegar a selección de minijuego
	get_tree().change_scene_to_file("res://ui/menus/mode_selection/mode_selection.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/menus/main_menu/main_menu.tscn")
	
func _on_debug_add_pressed() -> void:
	# Cuidado aquí: debug_add_fake_player() tendría que generar una imagen falsa
	# y emitir player_face_updated para que aparezca en el grid.
	NetworkManager.debug_add_fake_player()
