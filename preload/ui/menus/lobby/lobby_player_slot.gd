extends PanelContainer # (O Control, lo que tengas puesto arriba)

# Usamos find_child para que Godot busque en todos los sub-nodos automáticamente
# IMPORTANTE: Los nombres entre comillas deben ser EXACTOS a como se llaman los nodos en tu escena.
@onready var dummy = find_child("PlayerDummy", true, false)
@onready var name_label = find_child("NameLabel", true, false) 

func configure_slot(id: int, new_texture: ImageTexture, color: Color) -> void:
	# 1. Ponemos el nombre (si existe el texto)
	if name_label != null:
		name_label.text = "Player " + str(id)
	
	# 2. Pasamos la foto al maniquí
	if dummy != null:
		dummy.setup_dummy(new_texture, color)
	else:
		# Si sigue saliendo este error, es que el nodo no se llama "PlayerDummy" exactamente
		printerr("CRÍTICO: ¡No encuentro ningún nodo llamado 'PlayerDummy' dentro de la casilla!")
