extends Node2D

# --- CONFIGURACIÓN ---
# ¡OJO! Hemos borrado @export var player_scene de aquí. 
# Ahora debes arrastrar el player.tscn al Inspector del nodo SpawnManager.
@export var anvil_scene: PackedScene     # Arrastra tu obstaculo.tscn aquí

@onready var game_timer: Timer = $Timer
@onready var spawn_manager: Node2D = $SpawnManager

# --- ESTADO ---
var players_alive: int = 0

func _ready() -> void:
	# 1. Limpiamos la escena de jugadores de prueba que pusimos a mano
	_clear_test_players()
	
	# 2. Delegamos TODO el trabajo sucio al SpawnManager
	# Nos devuelve el número de jugadores que han aparecido
	players_alive = spawn_manager.spawn_all_players(
		NetworkManager.current_play_mode, 
		NetworkManager.host_plays_on_pc, 
		NetworkManager.connected_phones.size()
	)
	
	# 3. Iniciamos la lluvia de yunques
	game_timer.timeout.connect(_on_anvil_timer_timeout)
	game_timer.start()

func _clear_test_players() -> void:
	# Por si dejaste algún jugador suelto en el editor para ver la escala
	for child in get_children():
		if child.name.begins_with("Player"):
			child.queue_free()

# ==========================================
# LÓGICA DE JUEGO (YUNQUES)
# ==========================================
func _on_anvil_timer_timeout() -> void:
	var nuevo_yunque = anvil_scene.instantiate()
	# Rango basado en el tamaño estándar de pantalla de Godot (ajusta si usas otro)
	var random_x = randf_range(64, 1088)
	nuevo_yunque.global_position = Vector2(random_x, -100)
	add_child(nuevo_yunque)

# ==========================================
# SISTEMA DE ELIMINACIÓN
# ==========================================
func player_died(id: int) -> void:
	players_alive -= 1
	print("Jugador ", id, " ELIMINADO. Quedan: ", players_alive)
	
	if players_alive <= 1:
		_end_minigame()

func _end_minigame() -> void:
	game_timer.stop()
	print("¡PARTIDA FINALIZADA!")
	# Aquí podrías instanciar un cartel de "VICTORIA"
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://ui/menus/mode_selection/mode_selection.tscn")
