extends CharacterBody2D

# Valores visuales/colisión (para revertir: ESCALA = 1.0, RADIO = 10.0)
const ESCALA = 0.4
const RADIO = 20.0

var vel_z = 100.0
var dano = 10.0

func _ready():
	add_to_group("zombis")
	$Sprite2D.scale = Vector2(ESCALA, ESCALA)
	var forma = CircleShape2D.new()
	forma.radius = RADIO
	$CollisionShape2D.shape = forma

func liberar():
	queue_free()

func _physics_process(delta):
	var jug = get_parent().get_node("Jugador")
	var dist = position.distance_to(jug.position)
	var dir = (jug.position - position).normalized()

	if dist > 45:
		velocity = dir * vel_z
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	if dist < 55:
		jug.vida -= dano * delta
