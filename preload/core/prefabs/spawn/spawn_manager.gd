extends Node2D

@export var player_scene: PackedScene

# Nos aseguramos de precargar la escena
const PLAYER_SCENE = preload("res://entities/player/player.tscn")

func spawn_all_players() -> Array:
	var players_created = []
	var ids = NetworkManager.player_faces.keys() 
	
	# 1. Recopilamos todos los Marker2D que hayas puesto como hijos de este nodo
	var spawn_points = []
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
			
	print("SpawnManager: Encontrados ", spawn_points.size(), " puntos de spawn.")
	
	for i in range(ids.size()):
		var p_id = ids[i]
		var new_player = PLAYER_SCENE.instantiate()
		new_player.my_player_id = p_id
		new_player.name = "Player_" + str(p_id)
		
		get_parent().call_deferred("add_child", new_player)
		
		# 2. Calculamos la posición usando tus Markers
		var final_pos = Vector2.ZERO
		if i < spawn_points.size():
			# Si hay un marker disponible para este jugador, usamos su posición exacta
			final_pos = spawn_points[i].global_position
		else:
			# Paracaídas por si entran 8 jugadores y solo pusiste 4 markers
			final_pos = Vector2(100 + (i * 100), 100) 
			printerr("Aviso: Faltan Marker2D para el jugador ", p_id)
		
		# Aplicamos la posición
		new_player.set_deferred("global_position", final_pos)
		
		players_created.append(new_player)
		
	return players_created
