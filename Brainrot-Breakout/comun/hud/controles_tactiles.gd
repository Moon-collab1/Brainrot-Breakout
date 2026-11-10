extends Node2D
# "extends Node2D" significa: este script es un nodo 2D.
# Lo elegimos porque el botón táctil de Godot (TouchScreenButton) también es un
# Node2D, así que nuestros botones pueden colgar de este nodo como hijos.

# =====================================================================
# CONSTANTES: valores fijos que puedes ajustar aquí arriba sin tocar el resto
# =====================================================================

# true  = los botones se ven siempre (sirve para probar en el computador).
# false = solo se ven en pantallas táctiles (celular y tablet). Es el valor final.
const PROBAR_EN_PC = false
const TAM = 90.0       # ancho y alto de cada botón, en píxeles
const SEP = 100.0      # distancia entre el centro de la cruceta y cada flecha
const MARGEN = 24.0    # espacio entre los botones y el borde de la pantalla

# =====================================================================
# VARIABLES: aquí guardamos cada botón para poder moverlo después
# (en GDScript una variable sin valor empieza en null y se llena en _ready)
# =====================================================================
var b_arriba
var b_abajo
var b_izq
var b_der
var b_cachetada
var b_celular

# _ready() la llama Godot UNA sola vez, cuando este nodo entra a la escena.
# Aquí construimos todos los botones.
func _ready():
	# Las flechas: cada una recibe la acción del teclado que va a "presionar"
	# y los grados que se gira el triángulo (0 arriba, 90 derecha, 180 abajo, 270 izquierda).
	# Usamos las mismas acciones que ya lee jugador.gd, por eso no hay que cambiarlo.
	b_arriba = crear_flecha("ui_up", 0)
	b_der = crear_flecha("ui_right", 90)
	b_abajo = crear_flecha("ui_down", 180)
	b_izq = crear_flecha("ui_left", 270)
	# Botón de la cachetada: dispara la acción "cachetada" (la misma tecla X)
	b_cachetada = crear_boton("cachetada", "X", Color(0.9, 0.3, 0.3))
	# Botón del celular: dispara "ui_accept" (la misma tecla Enter o Espacio)
	b_celular = crear_boton("ui_accept", "CEL", Color(0.3, 0.6, 0.95))
	# Los ponemos en su lugar según el tamaño actual de la pantalla
	colocar()
	# size_changed es una SEÑAL: Godot la emite cuando cambia el tamaño de la ventana.
	# connect() dice "cuando pase eso, llama a colocar()". Así los botones siguen
	# bien ubicados si el celular se gira o la ventana cambia de tamaño.
	get_viewport().size_changed.connect(colocar)

# Calcula la posición de cada botón según el tamaño de la pantalla
func colocar():
	# Tamaño de la parte visible de la pantalla (ancho, alto)
	var pant = get_viewport().get_visible_rect().size
	# "cruz" es el centro de la cruceta: abajo a la izquierda, dejando margen
	var cruz = Vector2(MARGEN + SEP + TAM / 2.0, pant.y - MARGEN - SEP - TAM / 2.0)
	# Cada flecha queda a una distancia SEP del centro, en su dirección
	centrar(b_arriba, cruz + Vector2(0, -SEP))   # arriba: y menor
	centrar(b_abajo, cruz + Vector2(0, SEP))     # abajo: y mayor
	centrar(b_izq, cruz + Vector2(-SEP, 0))      # izquierda: x menor
	centrar(b_der, cruz + Vector2(SEP, 0))       # derecha: x mayor
	# Los botones de acción van abajo a la derecha, a la izquierda del recuadro
	# del celular del HUD (ese recuadro mide 160 px de ancho)
	centrar(b_cachetada, Vector2(pant.x - 270, pant.y - 70))
	centrar(b_celular, Vector2(pant.x - 270, pant.y - 175))

# En Godot la posición de un botón es su esquina superior izquierda.
# Esta función permite darle el CENTRO que queremos: resta la mitad del tamaño.
func centrar(boton, centro):
	boton.position = centro - Vector2(TAM, TAM) / 2.0

# Crea un botón redondo con un texto adentro y lo devuelve
func crear_boton(accion, texto, color):
	# TouchScreenButton es el nodo de Godot hecho para pantallas táctiles.
	# A diferencia de un Button normal, atiende VARIOS dedos a la vez
	# (por ejemplo, moverte y pegar al mismo tiempo).
	var b = TouchScreenButton.new()
	# La imagen del botón: un círculo de color hecho por la función circulo()
	b.texture_normal = circulo(color)
	# "action" es el nombre de una acción del Mapa de entrada. Al tocar el botón,
	# Godot hace como si se presionara esa tecla; por eso jugador.gd funciona igual.
	b.action = accion
	# passby_press: si deslizas el dedo hasta este botón, también se activa
	b.passby_press = true
	# modulate cambia el color; el último número (0.6) es la opacidad: 60 % visible
	b.modulate = Color(1, 1, 1, 0.6)
	# Decide cuándo se muestra el botón
	if PROBAR_EN_PC:
		b.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	else:
		b.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	# Label = texto. Lo hacemos del mismo tamaño del botón y lo centramos
	var l = Label.new()
	l.text = texto
	l.size = Vector2(TAM, TAM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 28)   # tamaño de la letra
	# add_child() lo cuelga como hijo: el texto se mueve junto con el botón
	b.add_child(l)
	# Y el botón se cuelga de este nodo para que entre al juego
	add_child(b)
	return b

# Crea un botón redondo con un triángulo adentro (para la cruceta)
func crear_flecha(accion, grados):
	# Primero un botón normal, sin texto
	var b = crear_boton(accion, "", Color(0.8, 0.8, 0.8))
	# Polygon2D dibuja una figura a partir de sus puntos. Usamos triángulos en vez
	# de los caracteres ▲▼ porque algunas fuentes no los traen y en la versión
	# web saldrían como cuadritos.
	var tri = Polygon2D.new()
	# Tres puntos (x, y) centrados en (0, 0): la punta arriba y la base abajo
	tri.polygon = PackedVector2Array([Vector2(0, -20), Vector2(18, 14), Vector2(-18, 14)])
	tri.color = Color(0.1, 0.1, 0.12)               # casi negro
	tri.position = Vector2(TAM, TAM) / 2.0          # al centro del botón
	tri.rotation_degrees = grados                   # lo giramos hacia donde apunta
	b.add_child(tri)
	return b

# Dibuja un círculo de color sin necesitar ninguna imagen (los assets no existen aún)
func circulo(color):
	# Un Gradient es un degradado: una lista de colores con su posición de 0.0 a 1.0.
	# Centro y hasta el 90 % del radio: color sólido; el último 10 %: se vuelve
	# transparente (alpha 0.0), lo que da un borde suave.
	var g = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.9, 1.0])
	g.colors = PackedColorArray([color, color, Color(color.r, color.g, color.b, 0.0)])
	# GradientTexture2D convierte el degradado en una imagen cuadrada
	var t = GradientTexture2D.new()
	t.gradient = g
	t.width = int(TAM)
	t.height = int(TAM)
	# FILL_RADIAL = el degradado va del centro hacia afuera (en forma de círculo)
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)   # empieza en el centro de la imagen
	t.fill_to = Vector2(1.0, 0.5)     # termina en el borde: ese es el radio
	return t
