extends Area2D


@export var damage: int = 30
@export var speed: float = 800.0
@export var lifetime: float = 0.5

@onready var bullet_particle = preload("res://scenes/bullet_particle.tscn")
@onready var bullet_hit_sound = preload("res://scenes/bullet_hit_sound.tscn")
@onready var life_timer: Timer = $LifeTimer

func _ready():
	life_timer.start(lifetime)

func _physics_process(delta):
	position += transform.x * speed * delta

func setup(trans: Transform2D):
	transform = trans
	

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.get_hit(damage, global_transform)
	var bullet_effect = bullet_particle.instantiate()
	get_tree().root.add_child(bullet_effect)
	bullet_effect.setup(global_transform)
	var bullet_hit_player = bullet_hit_sound.instantiate()
	get_tree().root.add_child(bullet_hit_player)
	bullet_hit_player.play()
	queue_free()

func _on_life_timer_timeout():
	var bullet_effect = bullet_particle.instantiate()
	get_tree().root.add_child(bullet_effect)
	bullet_effect.setup(global_transform)
	#var bullet_hit_player = bullet_hit_sound.instantiate()
	#get_tree().root.add_child(bullet_hit_player)
	#bullet_hit_player.play()
	queue_free()
