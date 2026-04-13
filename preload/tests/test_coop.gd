extends Node

func _ready():
	# Nos suscribimos a las señales del NetworkManager
	NetworkManager.local_player_joined.connect(_on_player_joined)
	NetworkManager.mobile_input_received.connect(_on_mobile_input)

func _on_player_joined(player_id: int):
	print("Menú Principal: Añadiendo UI para el Jugador ", player_id)
	# Aquí harías un instance() de tu personaje y lo meterías en la escena

func _on_mobile_input(player_id: int, action: String):
	if action == "boton_rojo":
		print("El Jugador ", player_id, " ha saltado o atacado.")
	elif action == "boton_azul":
		print("El Jugador ", player_id, " está usando un objeto.")
