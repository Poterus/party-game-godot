extends BaseMinigame # ¡Hereda todo el código de arriba!

@export var anvil_scene: PackedScene     
@onready var game_timer: Timer = $Timer

func _ready() -> void:
	# super._ready() ejecuta el _ready del BaseMinigame (spawn, cuenta atrás, etc.)
	super._ready() 
	game_timer.timeout.connect(_on_anvil_timer_timeout)

# Usamos el gancho de inicio para empezar los yunques
func _minigame_start() -> void:
	print("¡La lluvia de yunques comienza ahora!")
	game_timer.start()

# Usamos el gancho de fin para detener los yunques
func _minigame_end() -> void:
	game_timer.stop()

# Usamos el gancho de configuración de jugador por si queremos algo específico
func _setup_custom_player(player: Node2D) -> void:
	# Como este juego es horizontal, nos aseguramos de que el jugador esté en ese modo
	player.mode = player.ControllerMode.HORIZONTAL

func _on_anvil_timer_timeout() -> void:
	var nuevo_yunque = anvil_scene.instantiate()
	var random_x = randf_range(32, 480) 
	nuevo_yunque.global_position = Vector2(random_x, -100)
	add_child(nuevo_yunque)
	
	var nuevo_tiempo = game_timer.wait_time - 0.1
	game_timer.wait_time = max(nuevo_tiempo, 0.2)
