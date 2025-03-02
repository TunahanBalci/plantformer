extends Node2D

func _process(delta: float) -> void:
	
	var viewportHeight = get_viewport().size.y
	var scale = viewportHeight / $BackgroundSprite.texture.get_size().y / 1.2
	
	$BackgroundSprite.set_scale(Vector2(scale, scale))
	
