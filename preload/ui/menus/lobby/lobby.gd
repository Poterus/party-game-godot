extends Control

# ==========================================
# REFERENCIAS A LOS NODOS (La UI)
# ==========================================
@onready var label_ip: Label = $MarginContainer/MainVBox/HBox/LocalPanel/LabelIP
@onready var list_local: ItemList = $MarginContainer/MainVBox/HBox/LocalPanel/ListLocal
@onready var list_steam: ItemList = $MarginContainer/MainVBox/HBox/SteamPanel/ListSteam
@onready var button_start: Button = $MarginContainer/MainVBox/ButtonStart
@onready var button_back: Button = $MarginContainer/MainVBox/ButtonBack
@onready var texture_qr: QRCodeRect = $MarginContainer/MainVBox/HBox/LocalPanel/TextureQR

func _ready() -> void:
	# 1. Conectar botones
	button_start.pressed.connect(_on_button_start_pressed)
	button_back.pressed.connect(_on_button_back_pressed)
	
	# 2. Conectar la señal del Autoload (El grito del NetworkManager)
	NetworkManager.player_joined.connect(_on_network_player_joined)
	
	# 3. Mostrar la IP y generar el QR
	_setup_local_connection()
	
	# 4. Textos por defecto en las listas
	list_local.clear()
	list_local.add_item("Esperando dispositivos...")
	
	list_steam.clear()
	list_steam.add_item("Tú (Host)")

# ==========================================
# LÓGICA DE RED Y QR
# ==========================================
func _setup_local_connection() -> void:
	var ip_addresses = IP.get_local_addresses()
	var local_ip = "127.0.0.1"
	
	for ip in ip_addresses:
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172.16."):
			local_ip = ip
			break
			
	# Construimos la URL con la barra final para evitar el bloc de notas
	var url_mando = "http://" + local_ip.strip_edges() + ":8000/" 
	
	# Mostramos el texto y generamos el QR en bytes
	label_ip.text = url_mando
	texture_qr.data = url_mando.to_utf8_buffer()

# ==========================================
# LÓGICA DE ACTUALIZACIÓN DE INTERFAZ
# ==========================================
func _on_network_player_joined(player_id: int) -> void:
	# Borramos el mensaje de espera si es lo único que hay
	if list_local.get_item_count() > 0 and list_local.get_item_text(0) == "Esperando dispositivos...":
		list_local.clear()
		
	# Añadimos al jugador a la interfaz visual
	list_local.add_item("Jugador " + str(player_id) + " conectado")
	list_local.deselect_all()

# ==========================================
# LÓGICA DE BOTONES
# ==========================================
func _on_button_start_pressed() -> void:
	print("¡Iniciando minijuego!")

func _on_button_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/menus/main_menu/main_menu.tscn")
