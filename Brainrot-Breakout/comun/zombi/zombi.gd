extends CharacterBody2D

# Modelo del zombi: círculo verde con ojos, dibujado por código (sin textura).
const RADIO = 20.0

var vel_z = 100.0
var dano = 10.0

func _ready():
	add_to_group("zombis")
	queue_redraw()
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

func _draw():
	var piel = Color(0.45, 0.65, 0.35)
	var piel_osc = Color(0.2, 0.35, 0.15)
	# brazos estirados hacia adelante (se dibujan primero, quedan detrás del cuerpo)
	draw_line(Vector2(-RADIO, 4), Vector2(-RADIO - 12, 16), piel_osc, 7.0)
	draw_line(Vector2(RADIO, 4), Vector2(RADIO + 12, 16), piel_osc, 7.0)
	draw_line(Vector2(-RADIO, 4), Vector2(-RADIO - 12, 16), piel, 4.0)
	draw_line(Vector2(RADIO, 4), Vector2(RADIO + 12, 16), piel, 4.0)
	# cuerpo con contorno oscuro
	draw_circle(Vector2.ZERO, RADIO + 3.0, piel_osc)
	draw_circle(Vector2.ZERO, RADIO, piel)
	# ojos con pupila
	draw_circle(Vector2(-7, -5), 5.5, Color(1, 1, 1))
	draw_circle(Vector2(7, -5), 5.5, Color(1, 1, 1))
	draw_circle(Vector2(-6, -4), 2.2, Color(0.55, 0, 0))
	draw_circle(Vector2(8, -4), 2.2, Color(0.55, 0, 0))
	# boca
	draw_line(Vector2(-8, 8), Vector2(8, 8), Color(0.25, 0.05, 0.05), 3.0)
