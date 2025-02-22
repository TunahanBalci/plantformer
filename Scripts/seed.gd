extends RigidBody2D

var is_held = false
var has_grown = false
var threshold = 0.1  # Velocity threshold to consider the seed stopped
var throw_force = 500  # Adjust as needed

func pick_up(player):
	is_held = true
	# Reparent to player's hand
	get_parent().remove_child(self)
	player.hand.add_child(self)
	position = Vector2(0, 0)  # Local position in hand
	# Disable physics while held
	mode = MODE_STATIC

func throw(mouse_position):
	is_held = false
	# Reparent to world
	get_parent().remove_child(self)
	get_tree().current_scene.add_child(self)
	global_position = get_parent().global_position  # Start at hand's global position
	# Enable physics and throw
	mode = MODE_RIGID
	var throw_direction = (mouse_position - global_position).normalized()
	apply_impulse(Vector2(), throw_direction * throw_force)

func _physics_process(delta):
	if not is_held and linear_velocity.length() < threshold and not has_grown:
		check_ground()

func check_ground():
	var space_state = get_world_2d().direct_space_state
	# Raycast downward 10 pixels to check surface
	var ray = space_state.intersect_ray(position, position + Vector2(0, 10), [self], collision_mask)
	if ray:
		var collider = ray.collider
		if collider.is_in_group("soil"):
			grow_plant()

func grow_plant():
	has_grown = true
	# Instance new player
	var old_player = get_tree().get_nodes_in_group("player")[0]
	var new_player = preload("res://Player.tscn").instantiate()  # Adjust path to your player scene
	new_player.position = self.position
	get_tree().current_scene.add_child(new_player)
	# Handle animations and transition
	old_player.play_death_animation()
	new_player.play_growth_animation()
	# Update camera to follow new player
	get_tree().current_scene.get_node("Camera2D").follow_target = new_player  # Adjust path to your camera
	await new_player.growth_animation_finished  # Replace yield with await
	old_player.queue_free()
	queue_free()  # Remove seed after growing
