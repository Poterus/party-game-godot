extends Node2D

@export var player_scene: PackedScene

# Ahora esta función devuelve un Array con los nodos de los jugadores creados
func spawn_all_players(play_mode: String, host_on_pc: bool, connected_count: int) -> Array:
	var markers = get_children()
	var players_to_spawn = []
	var spawned_nodes = [] # <--- Lista para guardar los que vamos creando
	
	if play_mode == "solo":
		players_to_spawn = [1]
	else:
		if host_on_pc: players_to_spawn.append(1)
		var offset = 2 if host_on_pc else 1
		for i in range(connected_count):
			players_to_spawn.append(offset + i)

	for i in range(players_to_spawn.size()):
		if i < markers.size():
			var p = _create_player(players_to_spawn[i], markers[i].global_position)
			spawned_nodes.append(p)
	
	# Devolvemos la lista de nodos reales, no un número
	return spawned_nodes 

func _create_player(id: int, pos: Vector2) -> Node2D:
	var p = player_scene.instantiate()
	p.my_player_id = id
	p.global_position = pos
	p.name = "Player_" + str(id)
	
	# Lo añadimos directamente para que el nivel pueda acceder a él al instante
	get_parent().add_child(p)
	return p
