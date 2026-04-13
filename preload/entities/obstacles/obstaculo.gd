extends RigidBody2D

# Esta función se activa cuando algo toca el Area2D llamado "Hitbox"
func _on_hitbox_body_entered(body: Node2D) -> void:
	# Si hemos configurado bien las Masks, 'body' será siempre un jugador.
	# Pero por seguridad, chequeamos que tenga la variable my_player_id
	if "my_player_id" in body:
		print("¡AUCH! El jugador ", body.my_player_id, " ha sido golpeado")
		
		# 1. Avisamos al nivel (el padre del obstáculo) que alguien murió
		# Usamos owner o get_parent() dependiendo de cómo se instancie
		if get_parent().has_method("player_died"):
			get_parent().player_died(body.my_player_id)
		
		# 2. Borramos al jugador
		body.queue_free()
