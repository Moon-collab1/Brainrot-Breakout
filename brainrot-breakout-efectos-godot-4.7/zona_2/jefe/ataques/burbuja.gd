extends Area2D

# Burbuja «1» del Spam de notificaciones. No quita vida: sube la dopamina.
# Grupos: "destruibles" (la cachetada la revienta, sin sumar libres) y "proyectiles"
# (aturdir y morir la borran). Capa 8 (proyectiles), máscara 5 = jugador (1) + obstáculos (4).
# Los primeros GRACIA segundos solo detecta al jugador (máscara 1): al salir del borde del orbe
# puede quedar pegada a un sofá o a la pared de arriba y no debe reventar al nacer.
const GRACIA = 0.25

var vel = Vector2.ZERO     # el jefe la pone al crearla
var rapidez = 170.0        # px/s (el jefe la pone)
var giro = 1.4             # rad/s máximos con que gira hacia el jugador (el jefe la pone)
var vida_util = 6.0        # segundos antes de desaparecer (el jefe la pone)
var dopa = 6.0             # dopamina que sube al tocar al jugador (el jefe la pone)
var t = 0.0
var con_obstaculos = false

func _ready():
	collision_mask = 1
	body_entered.connect(_al_tocar)

func _physics_process(delta):
	t += delta
	if not con_obstaculos and t >= GRACIA:
		con_obstaculos = true
		collision_mask = 5   # desde ahora los obstáculos y límites la destruyen
	if t >= vida_util:
		queue_free()
		return
	# teledirigida: gira hacia el jugador, como máximo "giro" rad/s
	var jug = get_parent().get_node("Jugador")
	var objetivo = (jug.global_position - global_position).angle()
	var dif = angle_difference(vel.angle(), objetivo)
	var paso = clamp(dif, -giro * delta, giro * delta)
	vel = Vector2.from_angle(vel.angle() + paso) * rapidez
	global_position += vel * delta

# La llama jugador.dar_cachetada() (grupo "destruibles")
func reventar():
	queue_free()

func _al_tocar(body):
	if is_queued_for_deletion():
		return
	if body.is_in_group("jugador"):
		body.dopa += dopa   # sin daño de vida
		queue_free()
	else:
		queue_free()   # sofás ("rebotables"), macetas ("obstaculos") y límites: no rebota

# Placeholder dibujado: reemplazar por el PNG real de la burbuja
func _draw():
	draw_circle(Vector2.ZERO, 17.0, Color(1, 0.17, 0.3))
	draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 24, Color(1, 0.7, 0.75), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-17, 7), "1", HORIZONTAL_ALIGNMENT_CENTER, 34, 20, Color(1, 1, 1))
