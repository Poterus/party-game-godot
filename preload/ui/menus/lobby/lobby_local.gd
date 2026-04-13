extends Control

@onready var label_ip: Label = $MarginContainer/MainVBox/HBox/LocalPanel/LabelIP
@onready var texture_qr: QRCodeRect = $MarginContainer/MainVBox/HBox/LocalPanel/TextureQR
@onready var list_local: ItemList = $MarginContainer/MainVBox/HBox/SteamPanel/ListLocal
@onready var button_back: Button = $MarginContainer/MainVBox/ButtonBack
@onready var button_start: Button = $MarginContainer/MainVBox/ButtonStart
@onready var button_debug_add: Button = %ButtonDebugAdd

func _ready() -> void:
	# 1. Escuchar al NetworkManager
	NetworkManager.player_joined.connect(_on_player_joined)
	
	# 2. Configurar la conexión
	_generate_lobby_qr()
	
	# 3. Limpiar lista
	list_local.clear()
	list_local.add_item("Waiting for players...")
	button_back.pressed.connect(_on_back_pressed)
	button_start.pressed.connect(_on_start_pressed)
	button_debug_add.pressed.connect(_on_debug_add_pressed)
	
func _generate_lobby_qr() -> void:
	# Buscamos la IP local (IPv4)
	var local_ip = "127.0.0.1"
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10."):
			local_ip = ip
			break
	
	var url = "http://" + local_ip + ":8000/"
	label_ip.text = url
	
	# Generamos el QR pasando los datos como bytes
	texture_qr.data = url.to_utf8_buffer()

func _on_player_joined(id: int) -> void:
	if list_local.get_item_text(0) == "Waiting for players...":
		list_local.clear()
	
	list_local.add_item("Player " + str(id) + " - READY")
	
func _on_start_pressed() -> void:
	# Todos los jugadores ya están conectados. El Host elige el modo.
	get_tree().change_scene_to_file("res://ui/menus/mode_selection/mode_selection.tscn")

func _on_back_pressed() -> void:
	print("¡El botón funciona y me ha escuchado!") # <-- AÑADE ESTO
	get_tree().change_scene_to_file("res://ui/menus/main_menu/main_menu.tscn")
	
func _on_debug_add_pressed() -> void:
	NetworkManager.debug_add_fake_player()
