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
	# En lugar de player_joined, escuchamos cuando el jugador manda su foto (ya está listo)
	NetworkManager.player_face_updated.connect(_on_player_ready)
	
	_generate_lobby_qr()
	
	button_back.pressed.connect(_on_back_pressed)
	button_start.pressed.connect(_on_start_pressed)
	button_debug_add.pressed.connect(_on_debug_add_pressed)
	
	# Desactivamos el botón de empezar hasta que haya gente
	_update_start_button()
	
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
	
	# --- ESTA ES LA PARTE QUE FALLABA ---
	if grid_players.has_node(slot_name):
		var existing_slot = grid_players.get_node(slot_name)
		# ¡Usamos el método del slot, nada de buscar "FaceTexture" a mano!
		existing_slot.configure_slot(id, texture, Color.WHITE) 
		return
	# ------------------------------------
		
	# Instanciamos la nueva casilla
	var new_slot = PLAYER_SLOT_SCENE.instantiate()
	new_slot.name = slot_name
	
	grid_players.add_child(new_slot)
	
	var player_color = Color.WHITE
	new_slot.configure_slot(id, texture, player_color)
	
	_update_start_button()
	
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
	get_tree().change_scene_to_file("res://ui/menus/mode_selection/mode_selection.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/menus/main_menu/main_menu.tscn")
	
func _on_debug_add_pressed() -> void:
	# Cuidado aquí: debug_add_fake_player() tendría que generar una imagen falsa
	# y emitir player_face_updated para que aparezca en el grid.
	NetworkManager.debug_add_fake_player()
