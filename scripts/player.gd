extends CharacterBody2D


@export var SPEED = 300.0
@export var JUMP_VELOCITY = -400.0

@export var STAMINA = 100.0
@export var MAX_STAMINA = 100.0

@export var REGEN_FACTOR = 10.0
@export var REGEN_DELAY = 1.0 # in seconds

var is_dashing = false
var has_airjumped = false

var MAX_ZOOM = 4.0
var MIN_ZOOM = 0.75

var attempt_regen:= Timer.new()

var current_dash_trail: DashTrail


func _ready() -> void:
	add_child(attempt_regen)
	attempt_regen.wait_time = REGEN_DELAY
	attempt_regen.one_shot = false
	attempt_regen.connect("timeout", attempt_regen_timeout)
	
	attempt_regen.start()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY	
		else:
			_airjump()
		
	if is_on_floor() and has_airjumped:
		print("DEBUG: has_airjumped set to false")
		has_airjumped = false
	
	if Input.is_action_just_pressed("dash"):
		_dash()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	move_and_slide()
	
func _dash() -> void:
	print("DEBUG: Function call: _dash()")
	
	if not is_dashing:
		
		if STAMINA >= 40:
			print("DEBUG: Dash timer started")
			make_trail()
			is_dashing = true
			var originalSpeed = SPEED
			SPEED = SPEED * 20
			STAMINA = STAMINA - 40
			print ("INFO: New Stamina: ", STAMINA)
			await get_tree().create_timer(0.05).timeout
			SPEED = originalSpeed
			is_dashing = false
			if (current_dash_trail):
				current_dash_trail.stop()
				current_dash_trail = null
			print("DEBUG: Dash timer stopped")
		
		else:  
			print("DEBUG: Not enough stamina")
	else:
		print("DEBUG: Attempted dashing")
		
func _airjump() -> void:
	print("DEBUG: Function call: _airjump()")
	
	if STAMINA >= 20:
		if not has_airjumped:
			STAMINA -= 20
			has_airjumped = true
			velocity.y = JUMP_VELOCITY
			print("INFO: New stamina: ", STAMINA)
		else: 
			print("INFO: Already airjumped")
			

	else: 
		print("DEBUG: Not enough stamina for airjump")
		
	
func attempt_regen_timeout() -> void:
	
	print("DEBUG: Attempted stamina regen")
	
	if (STAMINA + REGEN_FACTOR) > MAX_STAMINA:
		STAMINA = MAX_STAMINA
	else:
		STAMINA += REGEN_FACTOR

	
	
func _process(delta: float) -> void:
	zoom()
	

func zoom() -> void:
	
	if Input.is_action_just_released("zoom_in"):
		if ($Camera2D.zoom.x >= MAX_ZOOM):
			print("INFO: Attempted zoom_in, max zoom reached")
		else:
			$Camera2D.zoom.x += 0.25
			$Camera2D.zoom.y = $Camera2D.zoom.x

	if Input.is_action_just_released("zoom_out"):
		if ($Camera2D.zoom.x <= MIN_ZOOM):
			print("INFO: Attempted zoom_out, min zoom reached")
		else:
			$Camera2D.zoom.x -= 0.25
			$Camera2D.zoom.y = $Camera2D.zoom.x

func make_trail() -> void:
	if current_dash_trail:
		current_dash_trail.stop()
	current_dash_trail = DashTrail.create()
	add_child(current_dash_trail)
	
