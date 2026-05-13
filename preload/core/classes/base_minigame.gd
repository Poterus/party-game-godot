extends Node2D
class_name BaseMinigame

# ====================================================
# BASE MINIGAME - Clase base para todos los minijuegos
# Flexible: funciona CON y SIN SpawnManager
# ====================================================

# --- REFERENCIAS OPCIONALES ---
@export var spawn_manager: Node2D  # Opcional (Solo si usas Player con física)
@export var countdown_ui: CanvasLayer
@export var victory_ui: PackedScene
@export var hud_ui: CanvasLayer
@export var minigame_layout: String = "joystick"

# --- ESTADO INTERNO ---
var game_active: bool = false
var time_survived: float = 0.0
var players_alive: int = 0
var initial_players_count: int = 0
var is_solo_mode: bool = false
var is_game_over: bool = false
var spawned_players: Array = []  # Array de jugadores spawneados (puede estar vacío)

func _ready() -> void:
	is_solo_mode = (NetworkManager.current_play_mode == "solo")
	
	# 1. SPAWN DE JUGADORES (solo si spawn_manager existe)
	if spawn_manager:
		spawned_players = spawn_manager.spawn_all_players(
			NetworkManager.current_play_mode, 
			NetworkManager.host_plays_on_pc, 
			NetworkManager.player_faces.size()
		)
		players_alive = spawned_players.size()
		initial_players_count = players_alive
		hud_ui.create_icons(players_alive, NetworkManager.host_plays_on_pc)
		
		# Conectar señales de muerte
		for p in spawned_players:
			p.player_died.connect(_on_player_died_base)
			_setup_custom_player(p)
	else:
		# Sin SpawnManager: el minijuego maneja sus propias entidades
		players_alive = NetworkManager.player_faces.size()
		initial_players_count = players_alive
		hud_ui.create_icons(players_alive, NetworkManager.host_plays_on_pc)
	
	# 2. Configurar layout del mando y fase
	NetworkManager.game_phase = "playing"
	NetworkManager.current_minigame_layout = minigame_layout
	if not is_solo_mode:
		NetworkManager.send_layout_to_all(minigame_layout)
	
	# 3. Arrancamos la UI del countdown
	countdown_ui.countdown_finished.connect(_internal_start_game)
	countdown_ui.start_countdown()

func _process(delta: float) -> void:
	if game_active and is_solo_mode:
		time_survived += delta

func _internal_start_game():
	game_active = true
	
	# Desbloquear movimiento solo si hay jugadores spawneados
	if spawn_manager:
		for child in spawn_manager.get_parent().get_children():
			if child.name.begins_with("Player") and not child.is_dead:
				child.can_move = true
	
	# Avisamos al minijuego específico de que puede empezar
	_minigame_start()

func _on_player_died_base(id: int) -> void:
	if is_game_over: return
	
	players_alive -= 1
	hud_ui.update_player_death(id)
	
	# Avisamos al minijuego específico
	_minigame_player_died(id)
	
	if is_solo_mode:
		if players_alive <= 0: _end_minigame_base()
	else:
		if players_alive <= 1: _end_minigame_base()

func _end_minigame_base() -> void:
	if is_game_over: return
	is_game_over = true
	game_active = false
	
	# Avisamos al minijuego de que termina
	_minigame_end()
	
	await get_tree().create_timer(1.5).timeout
	
	if victory_ui:
		var victory_screen = victory_ui.instantiate()
		get_tree().root.add_child(victory_screen)
		if is_solo_mode:
			victory_screen.show_singleplayer_score(time_survived)
		else:
			victory_screen.show_multiplayer_winner(_get_winner_id())

func _get_winner_id() -> int:
	if players_alive == 1 and spawn_manager:
		for child in spawn_manager.get_parent().get_children():
			if child.name.begins_with("Player") and not child.is_dead:
				return child.my_player_id
	return -1

# =========================================================
# GANCHOS VIRTUALES (a sobrescribir en cada minijuego)
# =========================================================

func _minigame_start() -> void:
	pass

func _minigame_end() -> void:
	pass

func _minigame_player_died(_id: int) -> void:
	pass

func _setup_custom_player(_player: Node2D) -> void:
	pass
