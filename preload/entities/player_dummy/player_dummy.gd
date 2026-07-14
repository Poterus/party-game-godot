extends Node2D

const PALETTE_SHADER = preload("res://assets/shaders/palette_swap.gdshader")
const HAT_BASE_PATH  = "res://assets/sprites/hats/hat_"

const SRC_LIGHT_HEX = "#0696DB"  # Cuerpo: color azul original del sprite
const BANDANA_HEX   = "#E7333B"  # Panuelo: rojo claro original (para extraer el hue)
const DEFAULT_COLOR = "#909090"  # Gris por defecto antes de elegir color

@onready var anim_player = $AnimationPlayer
@onready var face_sprite = $Sprite2D/Polygon2D/FaceSprite
@onready var sprite      = $Sprite2D
@onready var hat_sprite  = $HatSprite

func _ready() -> void:
	_setup_shader()
	anim_player.play("idle")

func _setup_shader() -> void:
	var mat  = ShaderMaterial.new()
	mat.shader = PALETTE_SHADER
	var src  = Color.from_string(SRC_LIGHT_HEX, Color.WHITE)
	var band = Color.from_string(BANDANA_HEX,   Color.WHITE)
	mat.set_shader_parameter("src_hue_center",  src.h)
	mat.set_shader_parameter("src_hue_range",   0.20)
	mat.set_shader_parameter("src_val",         src.v)
	mat.set_shader_parameter("band_hue_center", band.h)
	mat.set_shader_parameter("band_hue_range",  0.05)
	mat.set_shader_parameter("sat_min",         0.12)
	mat.set_shader_parameter("bandana_color",   Color.from_string("#282828", Color.BLACK))
	sprite.material = mat
	apply_color(Color.from_string(DEFAULT_COLOR, Color.WHITE))

# Aplica la foto de cara
func setup_dummy(new_texture: ImageTexture) -> void:
	if face_sprite == null:
		face_sprite = get_node_or_null("Sprite2D/Polygon2D/FaceSprite")
	if face_sprite != null:
		face_sprite.texture = new_texture
		face_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		face_sprite.show()
	else:
		printerr("CRITICO en PlayerDummy: no se encontro FaceSprite")

# Cambia el color del cuerpo
func apply_color(color: Color) -> void:
	if sprite.material is ShaderMaterial:
		sprite.material.set_shader_parameter("player_color", color)

# Cambia el color del panuelo (para minijuegos de equipos)
func apply_bandana_color(color: Color) -> void:
	if sprite.material is ShaderMaterial:
		sprite.material.set_shader_parameter("bandana_color", color)

# Cambia el sombrero (0 = sin sombrero)
func apply_hat(hat_id: int) -> void:
	if hat_id <= 0:
		hat_sprite.visible = false
		return
	var path = HAT_BASE_PATH + str(hat_id) + ".png"
	if ResourceLoader.exists(path):
		hat_sprite.texture = load(path)
		hat_sprite.visible = true
	else:
		printerr("PlayerDummy: no se encontro sombrero en ", path)
		hat_sprite.visible = false
