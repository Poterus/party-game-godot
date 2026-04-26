extends CanvasLayer

signal countdown_finished # Esta señal le dirá al juego: "¡EMPIEZA!"

@onready var label = $Main/NumberLabel
@onready var timer = $CountdownTimer

var count = 3

func start_countdown():
	show() # Nos aseguramos de que sea visible
	count = 3
	label.text = str(count)
	timer.start()
	# Aquí podrías poner un sonido de "Beep"
	_animate_number()

func _on_countdown_timer_timeout():
	count -= 1
	
	if count > 0:
		label.text = str(count)
		_animate_number()
		# Sonido de "Beep"
	elif count == 0:
		label.text = "GO!"
		_animate_number()
		# Sonido de "Beep agudo"
		countdown_finished.emit() # ¡Avisamos al nivel!
		timer.start() # Un último segundo para que se vea el "¡YA!"
	else:
		timer.stop()
		hide() # Nos ocultamos para no molestar

func _animate_number():
	# Pequeño efecto visual de escala para que el número "salte"
	var tween = create_tween()
	label.scale = Vector2(1.5, 1.5)
	label.pivot_offset = label.size / 2
	tween.tween_property(label, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BACK)
