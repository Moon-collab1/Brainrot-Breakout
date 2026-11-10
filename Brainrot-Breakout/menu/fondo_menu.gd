extends Control

# Fondo animado del menú: degradado, suelo de neón y celulares flotando (tema "doomscroll").
# Todo se dibuja con _draw(), sin imágenes.
const CANT = 26
const COLOR_ARRIBA = Color(0.16, 0.04, 0.30)
const COLOR_ABAJO = Color(0.02, 0.02, 0.09)
const COLORES = [
	Color(1.0, 0.25, 0.65),
	Color(0.25, 0.9, 1.0),
	Color(1.0, 0.85, 0.2),
	Color(0.65, 0.4, 1.0),
]

var items = []
var t = 0.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(CANT):
		items.append({
			"x": randf(),
			"y": randf(),
			"vel": randf_range(0.015, 0.05),   # fracción de pantalla por segundo
			"ancho": randf_range(26.0, 64.0),
			"rot": randf_range(-0.5, 0.5),
			"giro": randf_range(-0.2, 0.2),
			"color": COLORES[randi() % COLORES.size()],
		})

func _process(delta):
	t += delta
	for it in items:
		it.y -= it.vel * delta
		it.rot += it.giro * delta
		if it.y < -0.2:
			it.y = 1.2
			it.x = randf()
	queue_redraw()

func _draw():
	var tam = size
	# degradado vertical
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(tam.x, 0), tam, Vector2(0, tam.y)]),
		PackedColorArray([COLOR_ARRIBA, COLOR_ARRIBA, COLOR_ABAJO, COLOR_ABAJO]))
	# resplandor detrás del título
	for i in range(8):
		draw_circle(Vector2(tam.x * 0.5, tam.y * 0.25), 380.0 - i * 42.0, Color(1.0, 0.2, 0.65, 0.014))
	_dibujar_suelo(tam)
	for it in items:
		_dibujar_celular(it, tam)
	# líneas de escaneo (efecto pantalla vieja)
	for y in range(0, int(tam.y), 4):
		draw_line(Vector2(0, y), Vector2(tam.x, y), Color(0, 0, 0, 0.12))

func _dibujar_suelo(tam):
	var horizonte = tam.y * 0.68
	draw_rect(Rect2(0, horizonte, tam.x, tam.y - horizonte), Color(0.03, 0.02, 0.08, 0.6))
	var punto_fuga = Vector2(tam.x * 0.5, horizonte)
	var col = Color(0.25, 0.9, 1.0, 0.28)
	for i in range(-8, 9):
		draw_line(punto_fuga, Vector2(tam.x * 0.5 + i * 150.0, tam.y), col, 1.5)
	# líneas horizontales que avanzan hacia la cámara
	for k in range(10):
		var f = fmod(k + t * 0.5, 10.0) / 10.0
		var y = horizonte + (tam.y - horizonte) * f * f
		draw_line(Vector2(0, y), Vector2(tam.x, y), Color(1.0, 0.25, 0.65, 0.10 + 0.35 * f), 1.5)
	draw_line(Vector2(0, horizonte), Vector2(tam.x, horizonte), Color(1.0, 0.25, 0.65, 0.6), 2.0)

func _dibujar_celular(it, tam):
	var w = it.ancho
	var h = w * 1.9
	var c = it.color
	draw_set_transform(Vector2(it.x * tam.x, it.y * tam.y), it.rot, Vector2.ONE)
	var cuerpo = Rect2(-w / 2.0, -h / 2.0, w, h)
	draw_rect(cuerpo, Color(c.r, c.g, c.b, 0.07))
	draw_rect(cuerpo, Color(c.r, c.g, c.b, 0.45), false, 2.0)
	draw_rect(Rect2(-w * 0.38, -h * 0.38, w * 0.76, h * 0.7), Color(c.r, c.g, c.b, 0.08))
	draw_line(Vector2(-w * 0.15, -h * 0.45), Vector2(w * 0.15, -h * 0.45), Color(c.r, c.g, c.b, 0.5), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
