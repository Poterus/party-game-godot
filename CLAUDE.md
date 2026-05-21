# Party Game Godot — CLAUDE.md

## Qué es este proyecto

Juego de fiesta multijugador (hasta 8 jugadores) hecho en **Godot 4.6**. Los jugadores usan sus teléfonos como mandos conectándose a una interfaz web vía WebSocket. El host juega en PC (o también por móvil).

- Resolución base: 480x270, escalada a 1280x720 (pixel art)
- Idioma del código: español (variables, comentarios, prints)

---

## Arquitectura de red (`NetworkManager`)

Autoload singleton en `preload/core/network/network_manager.gd`.

- **Puerto 8080** — WebSocket para comunicación de mandos (inputs, joystick, fotos)
- **Puerto 8000** — HTTP que sirve `res://web/index.html` al teléfono del jugador

### IDs de jugadores
- Si `host_plays_on_pc = true`: el host es siempre el jugador 1 (teclado), los móviles empiezan en 2
- Si `host_plays_on_pc = false`: todos son móviles, empiezan en 1
- El primer jugador en mandar foto se convierte en host

### Layouts del teléfono
`send_layout_to_all(layout_name)` cambia la pantalla de todos los móviles. Layouts existentes: `"lobby"`, `"lobby_host"`, `"espera"`, `"menu"`, `"joystick"`.

### Señales clave
```gdscript
NetworkManager.player_joined(player_id)
NetworkManager.player_joystick(player_id, axis_x, axis_y)
NetworkManager.player_face_updated(player_id, texture)
NetworkManager.host_changed(new_id)
NetworkManager.host_start_game
```

### Debug
`NetworkManager.debug_add_fake_player()` añade un jugador fantasma con icono por defecto, sin necesitar móvil.

---

## Entidad Player (`preload/entities/player/`)

Extiende `CharacterBody2D`. Archivos: `player.gd`, `player.tscn`.

```gdscript
@export var mode: ControllerMode  # HORIZONTAL o TOP_DOWN
@export var SPEED = 250.0
@export var ACCELERATION = 0.3
var my_player_id: int
var can_move: bool  # false hasta que acaba la cuenta atrás
var is_dead: bool
signal player_died(id: int)
```

- El movimiento lee primero el joystick del teléfono (`player_joysticks[id]`), y si no hay input usa el teclado (`left_1`, `right_1`, etc.)
- Para matar a un jugador: llamar `player.die()` — gestiona la animación y emite `player_died`
- La foto de cara se aplica automáticamente vía señal de NetworkManager

---

## Framework de minijuegos (`BaseMinigame`)

Archivo: `preload/core/classes/base_minigame.gd`

Para crear un minijuego nuevo, extender `BaseMinigame` y sobreescribir los hooks:

```gdscript
extends BaseMinigame

func _minigame_start() -> void:   # Se llama al acabar la cuenta atrás
    pass

func _minigame_end() -> void:     # Se llama cuando queda ≤1 jugador vivo
    pass

func _minigame_player_died(_id: int) -> void:  # Cada vez que muere un jugador
    pass

func _setup_custom_player(_player: Node2D) -> void:  # Para cada jugador al spawnear
    pass
```

**Importante:** llamar `super._ready()` siempre al principio del `_ready()` del minijuego.

### Exports que necesita la escena del minijuego
```gdscript
@export var spawn_manager: Node2D      # SpawnManager con Marker2D hijos
@export var countdown_ui: CanvasLayer  # ui_countdown.tscn
@export var victory_ui: PackedScene    # ui_victory.tscn
@export var hud_ui: CanvasLayer        # ui_hud.tscn
@export var minigame_layout: String    # Layout del teléfono durante el juego
```

### Lógica de victoria automática
- **Solo**: termina cuando `players_alive <= 0`, muestra tiempo sobrevivido
- **Multi**: termina cuando `players_alive <= 1`, muestra al ganador

---

## SpawnManager (`preload/core/prefabs/spawn/`)

Poner `Marker2D` como hijos del SpawnManager para definir puntos de spawn. Si hay más jugadores que markers, los extras spawnean en posiciones por defecto.

---

## Minijuegos existentes

| Nombre | Archivo | Modo | Descripción |
|--------|---------|------|-------------|
| Sprint | `preload/minigames/sprint/Sprint.tscn` | HORIZONTAL | Carrera pulsando botones con carriles dinámicos |
| Yunque | `preload/minigames/yunque/yunque.tscn` | HORIZONTAL | Esquivar yunques que caen; se acelera con el tiempo |

---

## Estructura de carpetas

```
preload/
  addons/qr_code/       # Plugin de QR para conectar móviles
  assets/               # Fuentes, sprites, spritesheet de personaje
  core/
    classes/            # BaseMinigame
    network/            # NetworkManager (autoload)
    prefabs/
      spawn/            # SpawnManager
      sprint_lane/      # Carril para Sprint
      ui/               # ui_countdown, ui_hud, ui_player_icon, ui_victory
  entities/
    obstacles/          # Obstáculo genérico
    player/             # Player (CharacterBody2D)
    player_dummy/       # Dummy sin input para pruebas
  minigames/
    sprint/
    yunque/
  examples/qr_code/     # Ejemplo del addon QR
```

---

## Convenciones

- Los prints de debug usan emojis (✅ ❌ 📱 👑 📸 🔄)
- Las señales se conectan con `.connect()`, no `connect()` legacy
- `call_deferred` para `add_child` dentro del SpawnManager (evita errores de física)
- El código está en español
