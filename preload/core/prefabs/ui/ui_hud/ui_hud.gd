extends CanvasLayer

# Arrastra aquí la escena del icono que acabamos de crear
@export var player_icon_scene: PackedScene 

@onready var icon_container = %IconContainer
var icons: Dictionary = {} # Para buscar rápidamente el icono de un jugador

func create_icons(total_players: int, host_is_pc: bool):
	# Limpiamos por si acaso
	for child in icon_container.get_children():
		child.queue_free()
	icons.clear()
	
	# Creamos un icono por cada jugador
	var start_id = 1 if not host_is_pc else 1 
	# (Ajusta la lógica de IDs según cómo los repartas en el SpawnManager)
	
	# Simplemente creamos tantos iconos como jugadores vivos haya al principio
	for i in range(total_players):
		var id = i + 1 # Asumiendo que los IDs van del 1 en adelante
		var new_icon = player_icon_scene.instantiate()
		icon_container.add_child(new_icon)
		new_icon.setup(id)
		icons[id] = new_icon

func update_player_death(player_id: int):
	if icons.has(player_id):
		icons[player_id].set_dead()
