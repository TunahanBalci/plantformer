extends RigidBody2D

var is_picked_up := false
var ever_picked_up := false

func _physics_process(delta: float) -> void:

	self.rotation_degrees = 0
	
	if ever_picked_up and not is_picked_up:
		var bodies = $teleport_area.get_overlapping_bodies()
		
		for body in bodies:
			if body.name == "earth_tiles":
				get_node("../player").global_position = self.global_position
				queue_free()
	
	if is_picked_up:
		self.position = get_node("../player/seed_position").global_position
		
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("pick_up"):
		var bodies = $Area2D.get_overlapping_bodies()
		for body in bodies:
			if body.name == "player" and get_node("../player").can_pick_up == true:
				is_picked_up = true
				ever_picked_up = true
				get_node("../player").can_pick_up = false
	if Input.is_action_just_pressed("throw") and is_picked_up:
		is_picked_up = false
		get_node("../player").can_pick_up = true
		
		var player_velocity_x = get_node("../player").velocity.x
		var throw_velocity_x := int(player_velocity_x)
		var player_velocity_y = get_node("../player").velocity.y
		var throw_velocity_y := int(player_velocity_y)
		if (player_velocity_y > 0):
			throw_velocity_y = 0

		if get_node("../player").animated_sprite.flip_h:
			apply_impulse(Vector2(throw_velocity_x - 250, throw_velocity_y - 600))
		else:
			apply_impulse(Vector2(throw_velocity_x + 250, throw_velocity_y - 600))
