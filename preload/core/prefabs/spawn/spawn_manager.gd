extends Node2D

@export var player_scene: PackedScene

func spawn_all_players(play_mode: String, host_on_pc: bool, connected_count: int) -> int:
	var markers = get_children()
	var players_to_spawn = []
	
	# Lógica de IDs que ya conocemos
	if play_mode == "solo":
		players_to_spawn = [1]
	else:
		if host_on_pc: players_to_spawn.append(1)
		var offset = 2 if host_on_pc else 1
		for i in range(connected_count):
			players_to_spawn.append(offset + i)

	# El Spaneo real
	for i in range(players_to_spawn.size()):
		if i < markers.size():
			_create_player(players_to_spawn[i], markers[i].global_position)
	
	return players_to_spawn.size() # Devolvemos cuántos hay vivos

func _create_player(id: int, pos: Vector2):
	var p = player_scene.instantiate()
	p.my_player_id = id
	p.global_position = pos
	p.name = "Player_" + str(id)
	
	# Color automático por ID
	var sprite = p.get_node_or_null("Sprite2D")
	if sprite: sprite.modulate = Color.from_hsv(id * 0.125, 0.8, 1.0)
	
	# Lo añadimos al nivel (owner es el nivel donde soltaste el manager)
	get_parent().add_child(p)
