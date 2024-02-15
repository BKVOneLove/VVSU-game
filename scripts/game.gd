extends Node2D

@export var noise_shake_speed: float = 15.0
@export var noise_shake_strength: float = 16.0
@export var shake_decay_rate: float = 20.0
@export var spawn_radius: float = 700.0

var start_pos: Vector2
var enemy_list: Array = []
var noise_i: float = 0.0
var shake_strength: float = 0.0

@onready var bullet_class = preload("res://scenes/bullet.tscn")
@onready var camera: Camera2D = $Camera2D
@onready var enemy_class = preload("res://scenes/enemy.tscn")
@onready var player: CharacterBody2D = $Player
@onready var noise = FastNoiseLite.new()
@onready var rand = RandomNumberGenerator.new()
@onready var ground: Polygon2D = $Ground
@onready var spawn_timer:Timer = $SpawnTimer

func _ready():
	#var screen_size = get_viewport_rect().size
	var ground_size = Vector2.ZERO
	for vec in ground.polygon:
		ground_size = Vector2(max(vec.x, ground_size.x), max(vec.y, ground_size.y))
	#start_pos = ground_size / 2
	player.setup(ground_size * 20 / 2)
	print_debug(ground_size)
	# Camera shake related
	rand.randomize()
	noise.seed = rand.randi()
	noise.frequency = 0.1
	spawn_enemies()
	
func _process(delta: float):
	camera.transform = player.transform
		
	if enemy_list.size() != 0:
	#Enemies tp if out from screen
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if abs((player.position - enemy.position).length()) > spawn_radius + 300:
				#enemy.position = player.position + Vector2(pow(-1, randi() % 2) * randf_range(500, 700), pow(-1, randi() % 2) * randf_range(300, 500))
				var rand_pos = randf_range(-1, 1)
				enemy.position = player.position + Vector2(rand_pos, pow(-1, randi() % 2) * (1-abs(rand_pos))).normalized() * spawn_radius
	
	# Nearest enemy detection and auto shoot
		var nearest_enemy : Array
		nearest_enemy = [enemy_list[0], player.position.distance_to(enemy_list[0].position)]
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if player.position.distance_to(enemy.position) < nearest_enemy[1]:
				nearest_enemy = [enemy, player.position.distance_to(enemy.position)]
		player.auto_shooting(nearest_enemy[0].position)
	shake_camera(delta)

func shake_camera(delta: float):
	# Fade out the intensity over time
	shake_strength = lerp(shake_strength, 0.0, shake_decay_rate * delta)
	var shake_offset: Vector2
	shake_offset = get_noise_offset(delta, noise_shake_speed, shake_strength)
	# Shake by adjusting camera.offset, move the camera via it's position
	camera.offset = shake_offset

func get_noise_offset(delta: float, speed: float, strength: float) -> Vector2:
	noise_i += delta * speed
	# Set the x values of each call to 'get_noise_2d' to a different value
	# so that our x and y vectors will be reading from unrelated areas of noise
	return Vector2(
		noise.get_noise_2d(1, noise_i) * strength,
		noise.get_noise_2d(100, noise_i) * strength
	)

func get_random_offset() -> Vector2:
	return Vector2(
		rand.randf_range(-shake_strength, shake_strength),
		rand.randf_range(-shake_strength, shake_strength)
	)

func on_enemy_destroyed(enemy):
	shake_strength = noise_shake_strength
	enemy_list.erase(enemy)

func spawn_enemies():
	# Enemies spawn
	if enemy_list.size() < 200:
		spawn_timer.start(.3)
		var n = randi_range(1, 2)
		for i in range(0, n):
			var enemy = enemy_class.instantiate()
			enemy.connect("enemy_destroyed", on_enemy_destroyed)
			var rand_pos = randf_range(-1, 1)
			var pos = player.position + Vector2(rand_pos, pow(-1, randi() % 2) * (1-abs(rand_pos))).normalized() * spawn_radius
			enemy.setup(pos, player)
			get_tree().root.add_child.call_deferred(enemy)
			enemy_list.append(enemy)

func _on_spawn_timer_timeout():
	spawn_enemies()
