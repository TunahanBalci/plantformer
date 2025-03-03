extends TextureProgressBar

func _process(delta: float) -> void:
	value = %player.STAMINA
	# print("value:", value) # DEBUG
