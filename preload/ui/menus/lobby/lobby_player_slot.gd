extends PanelContainer

@onready var dummy       = find_child("PlayerDummy", true, false)
@onready var name_label  = find_child("NameLabel",   true, false)

func configure_slot(id: int, new_texture: ImageTexture, _color: Color = Color.WHITE) -> void:
	if name_label != null:
		var nombre: String = NetworkManager.player_names.get(id, "JUGADOR " + str(id))
		name_label.text = nombre
	if dummy != null:
		dummy.setup_dummy(new_texture)
	else:
		printerr("CRITICO: No encuentro ningun nodo PlayerDummy dentro de la casilla!")

func update_customization(skin_color: Color, hat_id: int) -> void:
	if dummy != null:
		dummy.apply_color(skin_color)
		dummy.apply_hat(hat_id)
