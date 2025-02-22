extends CharacterBody2D

# HAREKET VE FİZİK AYARLARI
@export var speed: float = 200            # Yatay hareket hızı
@export var gravity: float = 800          # Yerçekimi kuvveti
@export var jump_force: float = -300      # Zıplama kuvveti
@export var max_fall_speed: float = 1000    # Normal maksimum düşme hızı
@export var max_x_speed: float = 300       # Dash dışı maksimum X hızı
@export var fast_fall_acceleration: float = 1200  # Hızlı düşüş ivmesi
@export var max_fast_fall_speed: float = 1500     # Hızlı düşüş maksimum hızı

# DASH AYARLARI
@export var dash_speed: float = 800       # Dash hızı
@export var dash_duration: float = 0.2    # Dash süresi (saniye cinsinden)
@export var dash_cooldown: float = 1.0    # Dash sonrası bekleme süresi

# DOUBLE TAP için yardımcı değişkenler
var last_right_tap_time: float = 0.0
var right_tap_count: int = 0
var last_left_tap_time: float = 0.0
var left_tap_count: int = 0
var double_tap_threshold: float = 0.3

# DURUM DEĞİŞKENLERİ
var is_dashing: bool = false
var dash_time: float = 0.0
var dash_timer: float = 0.0
var dash_direction: String = ""           # Dash yönünü saklamak için

var can_double_jump: bool = true          # Hava zıplaması için

# YÜZEY YÜRÜYÜŞÜ İÇİN DURUM: "floor", "wall_left", "wall_right", "ceiling", "air"
var surface_state: String = "floor"

@onready var anim = $AnimatedSprite2D

# Kendi zaman sayacımız (saniye cinsinden)
var elapsed_time: float = 0.0

# Delta ile zaman sayacını güncellemek için _process fonksiyonu
func _process(delta: float) -> void:
	elapsed_time += delta

# DOUBLE TAP DASH için _input fonksiyonu
func _input(event):
	# Sağ (D) tuşu kontrolü
	if event.is_action_pressed("move_right"):
		var current_time = elapsed_time
		if current_time - last_right_tap_time < double_tap_threshold:
			right_tap_count += 1
		else:
			right_tap_count = 1
		last_right_tap_time = current_time
		if right_tap_count >= 2 and dash_timer <= 0:
			start_dash("right")
			right_tap_count = 0

	# Sol (A) tuşu kontrolü
	if event.is_action_pressed("move_left"):
		var current_time = elapsed_time
		if current_time - last_left_tap_time < double_tap_threshold:
			left_tap_count += 1
		else:
			left_tap_count = 1
		last_left_tap_time = current_time
		if left_tap_count >= 2 and dash_timer <= 0:
			start_dash("left")
			left_tap_count = 0

# Dash başlatma fonksiyonu
func start_dash(direction: String) -> void:
	is_dashing = true
	dash_time = dash_duration
	dash_timer = dash_cooldown
	dash_direction = direction  # Dash yönünü sakla
	if direction == "right":
		velocity.x = dash_speed
	elif direction == "left":
		velocity.x = -dash_speed
	velocity.y = 0  # Dash sırasında Y hareketini sıfırla

func _physics_process(delta: float) -> void:
	# Dash soğuma zamanını güncelle
	if dash_timer > 0:
		dash_timer -= delta

	# Eğer dash halindeysek, dash süresi boyunca hareketi uygula ve erken çık
	if is_dashing:
		dash_time -= delta
		velocity.y = 0  # Dash sırasında Y hareketini sıfır tut
		if dash_time <= 0:
			is_dashing = false
			# Dash bittiğinde maksimum hızı dash yönünde ayarla
			if dash_direction == "right":
				velocity.x = max_x_speed
			elif dash_direction == "left":
				velocity.x = -max_x_speed
		move_and_slide()  # Godot 4'te parametresiz çağrılıyor
		return

	# --- YÜZEY DURUMUNU BELİRLEME ---
	if is_on_floor():
		surface_state = "floor"
		rotation = 0
	elif is_on_wall():
		if get_slide_collision_count() > 0:
			var collision = get_slide_collision(0)
			var n = collision.get_normal()
			if n.x > 0:
				surface_state = "wall_left"
				rotation = -90
			elif n.x < 0:
				surface_state = "wall_right"
				rotation = 90
	elif is_on_ceiling():
		surface_state = "ceiling"
		rotation = 180
	else:
		surface_state = "air"

	# --- YÜRÜME VE HAREKET ---
	match surface_state:
		"floor":
			var input_dir = 0
			if Input.is_action_pressed("move_right"):
				input_dir += 1
			if Input.is_action_pressed("move_left"):
				input_dir -= 1
			velocity.x = input_dir * speed

			# Dash dışı X hızını sınırla
			if velocity.x > max_x_speed:
				velocity.x = max_x_speed
			elif velocity.x < -max_x_speed:
				velocity.x = -max_x_speed

			if not is_on_floor():
				velocity.y += gravity * delta
				if velocity.y > max_fall_speed:
					velocity.y = max_fall_speed
			else:
				velocity.y = 0
				can_double_jump = true  # Yerdeyken hava zıplamasını sıfırla

			if Input.is_action_just_pressed("jump"):
				velocity.y = jump_force

		"wall_left", "wall_right":
			# Duvar üzerinde otomatik yürüyüş: Örneğin, duvarda yukarı doğru hareket
			velocity = Vector2(0, -speed)
		"ceiling":
			# Tavanda otomatik yürüyüş: Örneğin, sürekli sola doğru hareket
			velocity = Vector2(-speed, 0)
		"air":
			# Hava kontrolü: Yatay hareketi güncelle
			var input_dir = 0
			if Input.is_action_pressed("move_right"):
				input_dir += 1
			if Input.is_action_pressed("move_left"):
				input_dir -= 1
			velocity.x = input_dir * speed

			# Dash dışı X hızını sınırla
			if velocity.x > max_x_speed:
				velocity.x = max_x_speed
			elif velocity.x < -max_x_speed:
				velocity.x = -max_x_speed

			# Normal yerçekimi
			velocity.y += gravity * delta
			
			# Hızlı düşüş (S tuşu)
			if Input.is_action_pressed("move_down"):
				velocity.y += fast_fall_acceleration * delta
				if velocity.y > max_fast_fall_speed:
					velocity.y = max_fast_fall_speed
			else:
				if velocity.y > max_fall_speed:
					velocity.y = max_fall_speed
			
			# Hava zıplaması
			if Input.is_action_just_pressed("jump") and can_double_jump:
				velocity.y = jump_force
				can_double_jump = false  # Hava zıplamasını bir kez kullan

	# --- ANİMASYON KONTROLÜ ---
	if abs(velocity.x) > 0:  # Hareket varsa yönü güncelle
		anim.flip_h = velocity.x < 0  # Sol ise true, sağ ise false
		if surface_state == "floor":
			anim.play("run")
		else:
			anim.play("walk")
	else:
		if surface_state == "floor":
			anim.play("idle")
		else:
			anim.play("walk")

	move_and_slide()  # Godot 4'te parametresiz çağrılıyor
