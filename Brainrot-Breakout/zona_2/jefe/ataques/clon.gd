extends Area2D

# Proyectil de «Recomendado para ti»: una perla mágica que vuela recto hacia el jugador.
# Grupos: "destruibles" (la cachetada lo revienta, sin sumar libres) y "proyectiles".
# Capa 8 (proyectiles), máscara 5 = jugador (1) + obstáculos (4).
# Los primeros GRACIA segundos solo detecta al jugador (máscara 1): al salir del borde del orbe
# puede quedar pegado a un sofá o a la pared de arriba y no debe reventar al nacer.
const GRACIA = 0.25
const MARGEN_FUERA = 150.0   # si se aleja tanto del mapa, se borra

var vel = Vector2.ZERO   # el jefe la pone (ángulo bloqueado * velocidad)
var dano = 10.0          # el jefe la pone
var empuje = 150.0       # píxeles de empujón (el jefe lo pone)
var t = 0.0
var con_obstaculos = false

# Se ve como una perla mágica (la misma de los Gemelos) que vuela hacia ti

func _ready():
	$Sprite2D.visible = false
	collision_mask = 1
	body_entered.connect(_al_tocar)

func _physics_process(delta):
	t += delta
	if not con_obstaculos and t >= GRACIA:
		con_obstaculos = true
		collision_mask = 5   # desde ahora los obstáculos y límites lo destruyen
	global_position += vel * delta
	queue_redraw()
	var p = global_position
	if p.x < -MARGEN_FUERA or p.x > 1152 + MARGEN_FUERA or p.y < -MARGEN_FUERA or p.y > 648 + MARGEN_FUERA:
		queue_free()

func _draw():
	var pulso = 0.5 + 0.5 * sin(t * 8.0)
	var R_ = 20.0
	# estela detrás de la perla
	var atras = -vel.normalized()
	for k in range(4):
		draw_circle(atras * (10.0 + k * 9.0), R_ * (0.7 - k * 0.14), Color(1, 0.35, 0.8, 0.25 - k * 0.05))
	draw_circle(Vector2.ZERO, R_ + 9.0 + 3.0 * pulso, Color(1, 0.3, 0.8, 0.18))
	draw_circle(Vector2.ZERO, R_ - 1.0, Color(0.85, 0.35, 0.75))
	draw_circle(Vector2(2.5, 3.5), R_ - 6.0, Color(0.65, 0.2, 0.6))
	draw_circle(Vector2(-3.5, -4.5), R_ - 10.0, Color(1, 0.6, 0.92))
	draw_circle(Vector2(-7, -8), 4.5, Color(1, 1, 1, 0.9))
	for k in range(4):
		var a = t * 3.0 + k * TAU / 4.0
		var p = Vector2.from_angle(a) * (R_ + 10.0)
		draw_line(p + Vector2(-3.5, 0), p + Vector2(3.5, 0), Color(1, 0.8, 1, 0.8), 1.4)
		draw_line(p + Vector2(0, -3.5), p + Vector2(0, 3.5), Color(1, 0.8, 1, 0.8), 1.4)

# La llama jugador.dar_cachetada() (grupo "destruibles")
func reventar():
	queue_free()

func _al_tocar(body):
	if is_queued_for_deletion():
		return
	if body.is_in_group("jugador"):
		body.vida -= dano
		body.empujar(vel.normalized() * empuje)
		queue_free()
	else:
		queue_free()   # sofás, macetas y límites
