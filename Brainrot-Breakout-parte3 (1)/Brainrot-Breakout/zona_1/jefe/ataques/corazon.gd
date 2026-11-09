extends Area2D

# Corazón de la Lluvia de likes y de la Lluvia grande. Va en el grupo "corazones":
# la cachetada del jugador NO lo destruye (solo el jefe, al aturdirse, o la raíz, al morir).
# Capa 4 (proyectiles) = 8, máscara jugador(1) + obstáculos(4) = 5.
const MARGEN_FUERA = 150.0   # si se aleja tanto del mapa, se borra

var vel = Vector2.ZERO       # la pone el jefe al crearlo
var dano = 6.0               # la pone el jefe (DANO_LIKE)
var rebotes = 0
var max_rebotes = 1          # la Lluvia grande lo pone en 0: se destruye al primer obstáculo

func _ready():
	body_entered.connect(_al_tocar)

func _physics_process(delta):
	global_position += vel * delta
	var p = global_position
	if p.x < -MARGEN_FUERA or p.x > 1152 + MARGEN_FUERA or p.y < -MARGEN_FUERA or p.y > 648 + MARGEN_FUERA:
		queue_free()

# Placeholder dibujado: reemplazar por el PNG real del corazón
func _draw():
	var c = Color(1, 0.2, 0.4)
	draw_circle(Vector2(-5, -3), 6.0, c)
	draw_circle(Vector2(5, -3), 6.0, c)
	draw_colored_polygon(PackedVector2Array([Vector2(-10.5, 0), Vector2(10.5, 0), Vector2(0, 12)]), c)

func _al_tocar(body):
	if is_queued_for_deletion():
		return
	if body.is_in_group("jugador"):
		body.vida -= dano
		queue_free()
	elif body.is_in_group("rebotables") and rebotes < max_rebotes:
		rebotar(body)
	else:
		queue_free()   # límites, o segundo contacto con un obstáculo

# Invierte la componente del eje cuya cara golpeó (la de mayor distancia fuera del rectángulo)
func rebotar(obst):
	rebotes += 1
	var col = obst.get_node("Colision")
	var mitad = col.shape.size / 2.0
	var d = global_position - col.global_position
	var fuera_x = abs(d.x) - mitad.x
	var fuera_y = abs(d.y) - mitad.y
	if fuera_x > fuera_y:
		vel.x = -vel.x
	else:
		vel.y = -vel.y
