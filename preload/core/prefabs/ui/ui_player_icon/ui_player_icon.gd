extends PanelContainer

@onready var background = $Background
@onready var face_image = $FaceImage
@onready var death_cross = $DeathCross

var my_id: int = 0

func setup(player_id: int):
	my_id = player_id
	# Asignamos el mismo color que usa su monigote
	background.modulate = Color.from_hsv(player_id * 0.125, 0.8, 1.0)
	
	# EN EL FUTURO: Aquí es donde pondrías: 
	# face_image.texture = NetworkManager.get_player_photo(player_id)

func set_dead():
	# Volvemos la foto gris y mostramos la cruz roja
	face_image.modulate = Color(0.3, 0.3, 0.3) 
	background.modulate = Color(0.2, 0.2, 0.2)
	death_cross.show()
