extends Node2D
class_name BaseMinigame

@export var spawn_manager: Node2D
@export var countdown_ui: CanvasLayer
@export var victory_ui: PackedScene
@export var hud_ui: CanvasLayer
@export var pause_ui: PackedScene
@export var minigame_layout: String = "joystick"

var game_active: bool = false
var time_survived: float = 0.0
var players_alive: int = 0
var initial_players_count: int = 0
var is_solo_mode: bool = false
var is_game_over: bool = false
var is_paused: bool = false
var player_nodes: Array = []
var pause_menu_instance = null

func _ready() -> void:
	is_solo_mode = (NetworkManager.current_play_mode == "solo")

	if spawn_manager:
		player_nodes = spawn_manager.spawn_all_players()
		players_alive = player_nodes.size()
		initial_players_count = players_alive
		if hud_ui:
			hud_ui.create_icons(players_alive, NetworkManager.host_plays_on_pc)
		for p in player_nodes:
			p.player_died.connect(_on_player_died_base)
			_setup_custom_player(p)
	else:
		players_alive = NetworkManager.player_faces.size()
		initial_players_count = players_alive
		if hud_ui:
			hud_ui.create_icons(players_alive, NetworkManager.host_plays_on_pc)
	
	NetworkManager.game_phase = "playing"
	NetworkManager.current_minigame_layout = minigame_layout
	if not is_solo_mode:
		NetworkManager.send_layout_to_all(minigame_layout)
	
	countdown_ui.countdown_finished.connect(_internal_start_game)
	countdown_ui.start_countdown()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not is_game_over:
		if is_paused:
			_reanudar()
		else:
			_pausar()

func _process(delta: float) -> void:
	if game_active and is_solo_mode:
		time_survived += delta

func _internal_start_game():
	game_active = true
	if spawn_manager:
		for child in spawn_manager.get_parent().get_children():
			if child.name.begins_with("Player") and not child.is_dead:
				child.can_move = true
	_minigame_start()

func _on_player_died_base(id: int) -> void:
	if is_game_over: return
	players_alive -= 1
	if hud_ui:
		hud_ui.update_player_death(id)
	_minigame_player_died(id)
	if is_solo_mode:
		if players_alive <= 0: _end_minigame_base()
	else:
		if players_alive <= 1: _end_minigame_base()

func _end_minigame_base() -> void:
	if is_game_over: return
	is_game_over = true
	game_active = false
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
	for p in player_nodes:
		if not p.is_dead:
			return p.my_player_id
	return -1

func _pausar() -> void:
	is_paused = true
	game_active = false
	if pause_ui and pause_menu_instance == null:
		pause_menu_instance = pause_ui.instantiate()
		get_tree().root.add_child(pause_menu_instance)
		pause_menu_instance.reanudar_pressed.connect(_reanudar)
		pause_menu_instance.salir_pressed.connect(_salir_al_lobby)

func _reanudar() -> void:
	is_paused = false
	game_active = true
	if pause_menu_instance:
		pause_menu_instance.queue_free()
		pause_menu_instance = null

func _salir_al_lobby() -> void:
	if pause_menu_instance:
		pause_menu_instance.queue_free()
		pause_menu_instance = null
	get_tree().change_scene_to_file("res://ui/menus/lobby/lobby_local.tscn")

func _minigame_start() -> void:
	pass

func _minigame_end() -> void:
	pass

func _minigame_player_died(_id: int) -> void:
	pass

func _setup_custom_player(_player: Node2D) -> void:
	pass
