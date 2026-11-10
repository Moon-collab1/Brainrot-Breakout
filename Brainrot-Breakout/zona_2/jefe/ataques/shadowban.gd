extends Node2D

# Zona circular del «Shadowban». Va en el grupo "franjas" (la limpieza del jefe la borra) y NO en
# "proyectiles". Sin física: mide la distancia al jugador cada frame. No se mueve.
# Mientras el jugador está dentro: mult_vel = mult (se multiplica con el ×0,6 del celular).

var radio = 100.0   # el jefe lo pone (SHADOW_RADIO)
var mult = 0.6      # el jefe lo pone (SHADOW_MULT)
var dopa_seg = 6.0  # dopamina por segundo dentro (SHADOW_DOPA)
var activa = false  # false = aviso (sin efecto)
var t = 0.0

func activar():
	activa = true

func _process(delta):
	t += delta
	if activa:
		var jug = get_parent().get_node("Jugador")
		if jug.global_position.distance_to(global_position) <= radio:
			jug.mult_vel = mult
			jug.lento_t = 0.1   # jugador.gd lo apaga solo si la zona deja de renovarlo
			jug.dopa += dopa_seg * delta
	queue_redraw()

# Placeholder dibujado: reemplazar por el sprite real de la zona
func _draw():
	if activa:
		var alfa = 0.32 + 0.06 * sin(t * 4.0)
		draw_circle(Vector2.ZERO, radio, Color(0.45, 0.38, 0.62, alfa))
		draw_arc(Vector2.ZERO, radio, 0.0, TAU, 48, Color(0.7, 0.6, 0.9, 0.9), 3.0)
	else:
		# aviso: relleno muy tenue y borde punteado
		draw_circle(Vector2.ZERO, radio, Color(0.45, 0.38, 0.62, 0.1))
		for i in range(24):
			var a = TAU * i / 24.0
			draw_arc(Vector2.ZERO, radio, a, a + TAU / 48.0, 4, Color(0.8, 0.7, 1, 0.8), 3.0)
