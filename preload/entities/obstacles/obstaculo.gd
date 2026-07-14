extends Area2D

@export var fall_speed: float = 250.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position.y += fall_speed * delta
	position = position.round() # Evita sub-pixel flickering

	if position.y > 400:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Verificamos si lo que tocamos tiene el método para morir
	if body.has_method("die"): 
		body.die()
	elif body.name.begins_with("Player"):
		# Si no tiene el método, usamos el sistema que ya tenías
		var main_scene = get_tree().current_scene
		if main_scene.has_method("player_died"):
			main_scene.player_died(body.my_player_id)
		body.queue_free()
