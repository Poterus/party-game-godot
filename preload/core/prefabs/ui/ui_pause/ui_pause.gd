extends CanvasLayer

signal reanudar_pressed
signal salir_pressed

@onready var boton_reanudar = $PanelContainer/VBoxContainer/BotonReanudar
@onready var boton_salir = $PanelContainer/VBoxContainer/BotonSalir

func _ready() -> void:
	boton_reanudar.pressed.connect(_on_reanudar)
	boton_salir.pressed.connect(_on_salir)

func _on_reanudar() -> void:
	reanudar_pressed.emit()

func _on_salir() -> void:
	salir_pressed.emit()
