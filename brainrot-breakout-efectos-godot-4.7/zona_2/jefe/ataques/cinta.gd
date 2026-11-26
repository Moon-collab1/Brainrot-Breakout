extends Node2D

# Franja horizontal del «Scroll infinito». Va en el grupo "franjas" (la limpieza del jefe la borra)
# y NO en "proyectiles". No usa física: mide la distancia al jugador cada frame (como franja.gd).
# La crea el jefe en el aviso (quieta, sin efecto) y la activa después.
const ANCHO = 1152.0     # de borde a borde del mapa
const ESPACIO = 70.0     # separación entre chevrones

var alto = 110.0         # el jefe lo pone (SCROLL_ALTO)
var vel = 140.0          # px/s de arrastre (SCROLL_VEL)
var dopa_seg = 8.0       # dopamina por segundo dentro (SCROLL_DOPA)
var dir = 1              # 1 = derecha, -1 = izquierda
var activa = false       # false = aviso (no arrastra)
var t_activa = 0.0

func activar():
	activa = true

func _process(delta):
	if activa:
		t_activa += delta
		var jug = get_parent().get_node("Jugador")
		# position.y es el centro de la franja
		if abs(jug.global_position.y - global_position.y) <= alto / 2.0:
			jug.arrastre = Vector2(dir * vel, 0.0)
			jug.arrastre_t = 0.1   # jugador.gd lo apaga solo si la franja deja de renovarlo
			jug.dopa += dopa_seg * delta
	queue_redraw()

# Placeholder dibujado: reemplazar por el sprite real de la cinta
func _draw():
	var rect = Rect2(0.0, -alto / 2.0, ANCHO, alto)
	var color = Color(1, 0.55, 0.3, 0.14)
	var borde = Color(1, 0.7, 0.4, 0.5)
	var chev = Color(1, 0.8, 0.5, 0.45)
	if activa:
		color = Color(1, 0.55, 0.3, 0.3)
		borde = Color(1, 0.7, 0.4, 0.9)
		chev = Color(1, 0.9, 0.6, 0.9)
	draw_rect(rect, color)
	draw_rect(rect, borde, false, 3.0)
	# chevrones: quietos en el aviso, corren en la dirección del arrastre cuando está activa
	var corrimiento = fposmod(t_activa * vel * dir, ESPACIO)
	var n = int(ANCHO / ESPACIO) + 1
	for i in range(n):
		var x = i * ESPACIO + corrimiento
		if x < 0.0 or x > ANCHO:
			continue
		var pts = PackedVector2Array([Vector2(x - 12.0 * dir, -18.0), Vector2(x + 12.0 * dir, 0.0), Vector2(x - 12.0 * dir, 18.0)])
		draw_polyline(pts, chev, 4.0)
