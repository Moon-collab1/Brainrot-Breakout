extends Node2D

# Cinta transportadora de «Cintas aceleradas». Va en el grupo "franjas" (la limpieza del
# jefe la borra). No usa física: cada frame mide la distancia y arrastra directamente.
# Arrastra al jugador (usa "arrastre" de jugador.gd) y también a los zombis.
const ANCHO = 1152.0
const ESPACIO = 70.0     # separación entre chevrones

var alto = 100.0         # el jefe lo pone
var dir = 1              # 1 = derecha, -1 = izquierda
var vel_ini = 90.0       # velocidad al empezar (el jefe lo pone)
var vel_fin = 240.0      # velocidad al final (el jefe lo pone)
var duracion = 8.0       # segundos hasta llegar a vel_fin (el jefe lo pone)
var activa = false       # false = aviso (no arrastra)
var t_activa = 0.0

func activar():
	activa = true

# Cambia el sentido de la cinta (el jefe la invierte varias veces)
func invertir():
	dir = -dir

# La velocidad sube poco a poco entre vel_ini y vel_fin
func vel_actual():
	var f = clamp(t_activa / duracion, 0.0, 1.0)
	return lerp(vel_ini, vel_fin, f)

func _process(delta):
	if activa:
		t_activa += delta
		var v = vel_actual() * dir
		var jug = get_parent().get_node("Jugador")
		# position.y es el centro de la cinta
		if abs(jug.global_position.y - global_position.y) <= alto / 2.0:
			jug.arrastre = Vector2(v, 0.0)
			jug.arrastre_t = 0.1   # jugador.gd lo apaga solo si la cinta deja de renovarlo
		# los zombis también se van con la cinta (move_and_collide respeta los obstáculos)
		for z in get_tree().get_nodes_in_group("zombis"):
			if abs(z.global_position.y - global_position.y) <= alto / 2.0:
				z.move_and_collide(Vector2(v * delta, 0.0))
	queue_redraw()

# Placeholder dibujado: reemplazar por el sprite real de la cinta
func _draw():
	var rect = Rect2(0.0, -alto / 2.0, ANCHO, alto)
	var color = Color(0.95, 0.75, 0.15, 0.12)
	var borde = Color(0.95, 0.75, 0.15, 0.5)
	var chev = Color(0.95, 0.75, 0.15, 0.4)
	if activa:
		color = Color(0.95, 0.75, 0.15, 0.28)
		borde = Color(1, 0.85, 0.3, 0.95)
		chev = Color(1, 0.9, 0.4, 0.9)
	draw_rect(rect, color)
	draw_rect(rect, borde, false, 3.0)
	# chevrones: quietos en el aviso; corren en el sentido de la cinta cuando está activa
	var corrimiento = fposmod(t_activa * vel_actual() * dir, ESPACIO)
	var n = int(ANCHO / ESPACIO) + 1
	for i in range(n):
		var x = i * ESPACIO + corrimiento
		if x < 0.0 or x > ANCHO:
			continue
		var pts = PackedVector2Array([Vector2(x - 12.0 * dir, -18.0), Vector2(x + 12.0 * dir, 0.0), Vector2(x - 12.0 * dir, 18.0)])
		draw_polyline(pts, chev, 4.0)
