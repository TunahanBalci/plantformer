extends KinematicBody2D

var held_seed = null
var can_control = true

# References to child nodes
onready var hand = $Hand
onready var interaction_area = $InteractionArea
onready var animation_player = $AnimationPlayer

func _ready():
	add_to_group("player")  # Add to "player" group for easy reference

func _input(event):
	if not can_control:
		return
	# Pick up seed with 'E'
	if event.is_action_pressed("pick_up"):  # Define "pick_up" as 'E' in Input Map
		var seeds = interaction_area.get_overlapping_bodies()
		for seed in seeds:
			if seed is RigidBody2D and seed.has_method("pick_up") and not seed.is_held:
				pick_up_seed(seed)
				break
	# Throw seed with left click
	if event.is_action_pressed("throw"):  # Define "throw" as left click in Input Map
		if held_seed:
			throw_seed()

func pick_up_seed(seed):
	if held_seed:
		return  # Already holding a seed
	held_seed = seed
	seed.pick_up(self)

func throw_seed():
	var seed = held_seed
	held_seed = null
	seed.throw(get_global_mouse_position())

func play_death_animation():
	can_control = false
	animation_player.play("death")
	# Optionally await animation_player.animation_finished if you want to delay removal

func play_growth_animation():
	can_control = false
	animation_player.play("growth")
	await(animation_player, "animation_finished")
	can_control = true
	emit_signal("growth_animation_finished")

signal growth_animation_finished
