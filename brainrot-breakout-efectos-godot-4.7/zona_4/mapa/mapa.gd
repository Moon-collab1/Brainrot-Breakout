extends Node2D

# Mapa de la Zona 4 «Ascensor». La arena es SOLO el interior del ascensor: 650x440
# (x de 251 a 901, y de 110 a 550). El resto de la pantalla es el hueco del ascensor.
# Todo se dibuja con _draw() (placeholder): reemplaza cada bloque "REEMPLAZAR" por un
# Sprite2D en zona_4/assets/. Las colisiones NO se dibujan aquí: están en MapaZona4.tscn.

const ARENA = Rect2(251, 110, 650, 440)
const COLOR_HUECO = Color(0.05, 0.05, 0.08)
const COLOR_MARCO = Color(0.32, 0.33, 0.4)
const COLOR_PARED = Color(0.22, 0.24, 0.3)
const COLOR_BALDOSA_A = Color(0.62, 0.62, 0.66)
const COLOR_BALDOSA_B = Color(0.5, 0.5, 0.54)
const BALDOSA = 47.0

# Lo único que cambia entre cuadros son los pasamanos (se mueven en la «Sacudida de cables»).
# Se redibuja solo cuando uno cambia de posición: antes era cada cuadro (caro en celular).
const PASAMANOS = ["PasamanosIzq", "PasamanosDer"]
var pos_pasamanos = {}   # última posición dibujada de cada pasamanos

# --- Contador de pisos (arriba del ascensor) ---
# Normalmente el ascensor sube sin parar. El jefe cambia "modo_piso" en su Sacudida de cables:
#   "normal" sube despacio      "aviso" sube muy rápido      "caida" baja rapidísimo
const PISO_INICIAL = 13.0
const VEL_PISO = {"normal": 0.5, "aviso": 6.0, "caida": -8.0}   # pisos por segundo
var modo_piso = "normal"
var piso = PISO_INICIAL
var piso_mostrado = -1       # último número escrito (para no reescribir el texto cada cuadro)
var modo_mostrado = ""
var etiqueta_piso: Label     # el texto «▲ 13»; es un Label aparte para no redibujar todo el mapa

func _ready():
	etiqueta_piso = Label.new()
	etiqueta_piso.position = Vector2(542, 66)
	etiqueta_piso.size = Vector2(68, 28)
	etiqueta_piso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_piso.add_theme_font_size_override("font_size", 20)
	add_child(etiqueta_piso)
	actualizar_piso(0.0)

# Mueve el contador según el modo y actualiza el texto solo cuando cambia el número
func actualizar_piso(delta):
	piso = max(piso + VEL_PISO[modo_piso] * delta, 1.0)   # nunca baja del piso 1
	var numero = int(piso)
	if numero == piso_mostrado and modo_piso == modo_mostrado:
		return
	piso_mostrado = numero
	modo_mostrado = modo_piso
	if modo_piso == "caida":
		etiqueta_piso.text = "▼ " + str(numero)
		etiqueta_piso.add_theme_color_override("font_color", Color(1, 0.25, 0.25))   # rojo: cayendo
	elif modo_piso == "aviso":
		etiqueta_piso.text = "▲ " + str(numero)
		etiqueta_piso.add_theme_color_override("font_color", Color(1, 0.85, 0.2))    # amarillo: algo anda mal
	else:
		etiqueta_piso.text = "▲ " + str(numero)
		etiqueta_piso.add_theme_color_override("font_color", Color(0.4, 1, 0.5))     # verde: subiendo normal

func _process(delta):
	actualizar_piso(delta)
	var cambio = false
	for nombre in PASAMANOS:
		var barra = get_node_or_null(nombre)
		var pos = Vector2.ZERO
		if barra != null:
			pos = barra.position
		if not pos_pasamanos.has(nombre) or pos_pasamanos[nombre] != pos:
			pos_pasamanos[nombre] = pos
			cambio = true
	if cambio:
		queue_redraw()

func _draw():
	# REEMPLAZAR: hueco oscuro del ascensor (fondo de toda la pantalla)
	draw_rect(Rect2(0, 0, 1152, 648), COLOR_HUECO)
	for i in range(0, 1152, 96):
		draw_line(Vector2(i, 0), Vector2(i, 648), Color(0.09, 0.09, 0.13), 2.0)

	# REEMPLAZAR: marco metálico de la cabina
	draw_rect(Rect2(ARENA.position - Vector2(24, 24), ARENA.size + Vector2(48, 48)), COLOR_MARCO)

	# REEMPLAZAR: pared del fondo con tres ventanas de vidrio (arriba de la arena)
	draw_rect(Rect2(ARENA.position, Vector2(ARENA.size.x, 70)), COLOR_PARED)
	for i in range(3):
		draw_rect(Rect2(ARENA.position.x + 10 + i * 212.0, ARENA.position.y + 8, 196, 54), Color(0.55, 0.72, 0.82))
		draw_line(Vector2(ARENA.position.x + 30 + i * 212.0, ARENA.position.y + 58), Vector2(ARENA.position.x + 110 + i * 212.0, ARENA.position.y + 12), Color(1, 1, 1, 0.5), 3.0)

	# REEMPLAZAR: piso de baldosas en tablero de ajedrez
	var inicio_y = ARENA.position.y + 70
	var y = inicio_y
	var fila = 0
	while y < ARENA.end.y:
		var x = ARENA.position.x
		var col = 0
		while x < ARENA.end.x:
			var color = COLOR_BALDOSA_A
			if (fila + col) % 2 == 1:
				color = COLOR_BALDOSA_B
			var ancho = min(BALDOSA, ARENA.end.x - x)
			var alto = min(BALDOSA, ARENA.end.y - y)
			draw_rect(Rect2(x, y, ancho, alto), color)
			x += BALDOSA
			col += 1
		y += BALDOSA
		fila += 1

	# REEMPLAZAR: puertas del ascensor (rendija oscura abajo)
	draw_rect(Rect2(ARENA.position.x + 235, ARENA.end.y - 8, 180, 8), Color(0.1, 0.1, 0.12))

	# REEMPLAZAR: fondo del indicador de piso (el número lo escribe etiqueta_piso, ver arriba)
	# y panel de luces de la derecha
	draw_rect(Rect2(542, 68, 68, 26), Color(0.05, 0.05, 0.08))
	draw_rect(Rect2(930, 260, 50, 150), Color(0.1, 0.1, 0.14))
	for i in range(5):
		var luz = Color(0.25, 0.25, 0.3)
		if i == 2:
			luz = Color(1, 0.8, 0.2)
		draw_circle(Vector2(955, 285 + i * 30), 9.0, luz)

	# REEMPLAZAR: pasamanos (barras laterales). Se dibujan donde esté su cuerpo de colisión
	for nombre in PASAMANOS:
		var barra = get_node_or_null(nombre)
		if barra != null:
			draw_rect(Rect2(barra.position - Vector2(7, 90), Vector2(14, 180)), Color(0.55, 0.57, 0.62))
			draw_rect(Rect2(barra.position - Vector2(7, 90), Vector2(14, 180)), Color(0.2, 0.2, 0.24), false, 2.0)
