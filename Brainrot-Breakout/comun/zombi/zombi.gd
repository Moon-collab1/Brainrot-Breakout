extends CharacterBody2D

# Zombi básico. Persigue al jugador en línea recta y le quita vida si está cerca.
# Va en el grupo "zombis": oleadas.gd cuenta cuántos quedan y jugador.gd los libera con la
# cachetada (liberar() lo borra y el jugador suma 1 a "libres"). Su modelo es un círculo verde
# con ojos dibujado por código (sin textura).
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

# Camina hacia el jugador (se detiene a 45 px) y le hace daño continuo a menos de 55 px
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
	# Dibujo un poco más grande que el modelo base para que cubra la colisión (radio 20)
	var esc = Vector2(1.2, 1.2)
	var verde = Color(0.494, 0.851, 0.341)
	var verde_osc = Color(0.16, 0.43, 0.16)
	# sombra en el piso
	draw_set_transform(Vector2(0, 31), 0.0, Vector2(esc.x, esc.y * 0.28))
	draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, esc)
	# cuerpo (ropa gris azulada)
	var ropa = StyleBoxFlat.new()
	ropa.bg_color = Color(0.333, 0.353, 0.467)
	ropa.set_corner_radius_all(8)
	draw_style_box(ropa, Rect2(-13, -5, 26, 28))
	# cabeza verde con contorno oscuro
	draw_circle(Vector2(0, -15), 15.0, verde_osc)
	draw_circle(Vector2(0, -15), 13.0, verde)
	# ojos con pupila
	draw_circle(Vector2(-5, -14), 3.2, Color(1, 1, 1))
	draw_circle(Vector2(5, -14), 3.2, Color(1, 1, 1))
	draw_circle(Vector2(-5, -14), 1.4, Color(0, 0, 0))
	draw_circle(Vector2(5, -14), 1.4, Color(0, 0, 0))
	# cejas fruncidas
	draw_arc(Vector2(-4.5, -19), 4.5, deg_to_rad(200), deg_to_rad(340), 8, verde_osc, 1.6)
	draw_arc(Vector2(4.5, -19), 4.5, deg_to_rad(200), deg_to_rad(340), 8, verde_osc, 1.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
