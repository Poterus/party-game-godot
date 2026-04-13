extends Node2D
class_name BaseMinigame

signal minigame_finished(results: Dictionary)

# Diccionario compartido: { peer_id: {"name": str, "alive": bool, "score": int} }
var players_metadata: Dictionary = {}

func _ready():
	# Inicializamos a los jugadores basándonos en los datos del Lobby de Steam
	setup_players()

func setup_players():
	# Aquí obtendrías la lista de IDs de tu NetworkManager (Steam)
	var connected_ids = NetworkManager.get_all_peer_ids()
	for id in connected_ids:
		players_metadata[id] = {
			"alive": true,
			"score": 0
		}

# Función genérica para matar a un jugador
func set_player_dead(id: int):
	if players_metadata.has(id):
		players_metadata[id]["alive"] = false
		check_game_over_conditions()

# Esta función es un "hueco" que cada minijuego rellenará a su manera
func check_game_over_conditions():
	pass 

# Notificar al Host y a Steam que esto acabó
func end_game():
	if NetworkManager.is_host():
		# El host decide el resultado final y lo manda por P2P
		NetworkManager.broadcast_minigame_end(players_metadata)
