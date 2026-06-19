extends Node2D

# ====================================================
# ESCENA DE TEST — movimiento TOP_DOWN + salto + coyote
# ====================================================

@onready var player          = $Player
@onready var plt1: Plataforma = $Plataforma1
@onready var plt2: Plataforma = $Plataforma2
@onready var label_estado: Label = $CanvasLayer/LabelEstado
@onready var label_coyote: Label = $CanvasLayer/LabelCoyote

const COLOR_AZUL   = Color(0.19, 0.38, 0.91)
const COLOR_NARANJA = Color(0.94, 0.47, 0.16)

func _ready() -> void:
	player.mode = player.ControllerMode.TOP_DOWN
	player.can_move = true
	plt1.set_color_id(1, COLOR_AZUL)
	plt2.set_color_id(4, COLOR_NARANJA)

func _process(_delta: float) -> void:
	# ── Estado de plataforma ──────────────────────────
	if player.platforms_below > 0:
		label_estado.text = "▶ En plataforma"
		label_estado.modulate = Color.GREEN
	elif player.coyote_time > 0.0:
		label_estado.text = "▶ En plataforma"
		label_estado.modulate = Color.GREEN  # visualmente sigue "en plataforma"
	else:
		label_estado.text = "▶ Fuera"
		label_estado.modulate = Color.RED

	# ── Coyote time ───────────────────────────────────
	if player.coyote_time > 0.0:
		label_coyote.text   = "COYOTE  %.2fs" % player.coyote_time
		label_coyote.modulate = Color.YELLOW
	else:
		label_coyote.text   = ""
