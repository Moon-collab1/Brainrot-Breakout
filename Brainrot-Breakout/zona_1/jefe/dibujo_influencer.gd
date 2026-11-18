extends Node2D

# Diseño del Influencer (antes dibujado por código, ahora sprite assets/sprites/jefes/jefe_influencer.png): pelo morado, lentes, sudadera rosa
# y celular en la mano. Cabe dentro del aro del jefe (radio 70, se dibuja en jefe_influencer.gd).
# Va en un nodo hijo para que jefe_influencer.gd lo pueda teñir (aturdido) con su modulate.
const HOJA = preload("res://comun/jefe/hoja_jefe.gd")
const SPRITE = preload("res://assets/sprites/jefes/jefe_influencer.png")
const PIEL = Color(0.96, 0.74, 0.6)
const PIEL_SOMBRA = Color(0.83, 0.56, 0.44)
const ROSA = Color(0.97, 0.27, 0.63)
const ROSA_OSC = Color(0.68, 0.1, 0.4)
const PELO = Color(0.5, 0.25, 0.72)
const PELO_OSC = Color(0.32, 0.13, 0.48)
const CONTORNO = Color(0.14, 0.05, 0.2)

var caja_lente = StyleBoxFlat.new()
var caja_celular = StyleBoxFlat.new()

func _ready():
	caja_lente.bg_color = Color(0.1, 0.55, 0.8)
	caja_lente.border_color = CONTORNO
	caja_lente.set_border_width_all(2)
	caja_lente.set_corner_radius_all(4)
	caja_celular.bg_color = Color(0.07, 0.07, 0.15)
	caja_celular.border_color = Color(0.92, 0.92, 1.0)
	caja_celular.set_border_width_all(2)
	caja_celular.set_corner_radius_all(5)

func _process(_delta):
	# se balancea un poquito, como si respirara (no mueve las colisiones del jefe)
	position.y = sin(Time.get_ticks_msec() / 350.0) * 2.0
	queue_redraw()   # para que avance la animación del sprite

func _draw():
	# sombra en el piso
	draw_set_transform(Vector2(0, 64), 0.0, Vector2(1.0, 0.17))
	draw_circle(Vector2.ZERO, 54.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# el cuerpo es un sprite animado (pelo, sudadera, flash del celular y corazoncito)
	HOJA.dibujar(self, SPRITE, 4, 0, Vector2(200, 190), Vector2(100, 100), Color(1, 1, 1), 0.18)
