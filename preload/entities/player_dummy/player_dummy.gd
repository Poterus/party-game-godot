extends Node2D

@onready var anim_player = $AnimationPlayer
@onready var face_sprite = $Polygon2D/FaceSprite
@onready var sprite = $Sprite2D

func _ready():
	anim_player.play("idle") # Que respire desde el principio

func setup_dummy(new_texture: ImageTexture, color: Color) -> void:
	if face_sprite == null:
		face_sprite = get_node_or_null("Polygon2D/FaceSprite")
		
	if face_sprite != null:
		face_sprite.texture = new_texture
		
		# ¡SOLO aplicamos la textura y el filtro! 
		# NO tocamos ni .scale ni .position para que Godot respete tu 0.5 del Editor
		face_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		face_sprite.show()
	else:
		printerr("CRÍTICO en PlayerDummy: ¡No se encontró el nodo FaceSprite!")
		
	if sprite != null:
		sprite.modulate = color
