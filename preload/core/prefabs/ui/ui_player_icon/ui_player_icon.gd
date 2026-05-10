extends PanelContainer

@onready var background = $Background
@onready var face_image = $FaceImage
@onready var death_cross = $DeathCross

var my_id: int = 0

func _ready() -> void:
	NetworkManager.player_face_updated.connect(_on_player_face_updated)

func setup(player_id: int):
	my_id = player_id
	background.modulate = Color.from_hsv(player_id * 0.125, 0.8, 1.0)
	
	if NetworkManager.player_faces.has(my_id):
		_apply_face_texture(NetworkManager.player_faces[my_id])

func _on_player_face_updated(id: int, texture: ImageTexture) -> void:
	if id == my_id:
		_apply_face_texture(texture)

func _apply_face_texture(texture: ImageTexture) -> void:
	if face_image != null:
		face_image.texture = texture
		face_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		
		# Ajustamos la escala para que la foto de 64x64 encaje en el cuadradito
		# Puedes cambiar este 0.8 por 0.5 o 0.3 si ves que la cara queda muy grande
		face_image.scale = Vector2(0.8, 0.8)
		
		# Centramos el pivot
		face_image.pivot_offset = face_image.size / 2

func set_dead():
	face_image.modulate = Color(0.3, 0.3, 0.3) 
	background.modulate = Color(0.2, 0.2, 0.2)
	death_cross.show()
