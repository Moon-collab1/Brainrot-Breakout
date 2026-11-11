extends Node

# Pantalla de victoria: la crea el Núcleo-∞ al morir (es el jefe FINAL).
# Congela las oleadas, guarda el récord, muestra el mensaje y luego pide el nombre
# para el leaderboard. Es un nodo aparte porque el jefe se libera justo después de morir.
const SEG_ESPERA = 2.0   # cuánto se ve "¡GANASTE!" antes de pedir el nombre

var libres = 0
var tiempo = 0.0
var campo: LineEdit
var listo = false

func _ready():
	var zona = get_parent()
	var jug = zona.get_node("Jugador")
	zona.en_transicion = true   # oleadas.gd deja de lanzar oleadas
	jug.reg.guardar(jug.libres)
	libres = jug.libres
	tiempo = Registro.tiempo
	zona.get_node("HUD").mostrar_banner(true, "¡GANASTE!")
	mostrar_mensaje("Usaste el celular con cuidado")
	var t = Timer.new()
	t.one_shot = true
	add_child(t)
	t.timeout.connect(pedir_nombre)
	t.start(SEG_ESPERA)

func mostrar_mensaje(texto):
	var capa = CanvasLayer.new()   # capa propia: no depende del HUD ni del zoom de la cámara
	add_child(capa)
	var l = Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)   # centrado, bajo el Banner
	l.offset_left = -200.0
	l.offset_right = 200.0
	l.offset_top = 104.0
	l.offset_bottom = 134.0

func pedir_nombre():
	get_tree().paused = true   # se congela el juego mientras se escribe
	var capa = CanvasLayer.new()
	capa.layer = 110   # sobre la pausa (100)
	capa.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(capa)
	var fondo = ColorRect.new()
	fondo.color = Color(0.02, 0.01, 0.08, 0.85)
	capa.add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro = CenterContainer.new()
	capa.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	centro.add_child(v)
	v.add_child(crear_label("¡GANASTE!", 56))
	v.add_child(crear_label("Liberados: %d   Tiempo: %s" % [libres, Leaderboard.formato_tiempo(tiempo)], 24))
	v.add_child(crear_label("Escribe tu nombre para el ranking", 20))
	campo = LineEdit.new()
	campo.max_length = Leaderboard.MAX_NOMBRE
	campo.placeholder_text = "Tu nombre"
	campo.alignment = HORIZONTAL_ALIGNMENT_CENTER
	campo.custom_minimum_size = Vector2(380, 56)
	campo.add_theme_font_size_override("font_size", 24)
	campo.text_submitted.connect(guardar_nombre)   # Enter también guarda
	v.add_child(campo)
	v.add_child(crear_boton("GUARDAR", guardar_nombre))
	v.add_child(crear_boton("SALTAR", salir))
	campo.grab_focus()

func crear_label(texto, tam):
	var l = Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	l.add_theme_constant_override("outline_size", 6)
	return l

func crear_boton(texto, accion):
	var b = Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(380, 56)
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(accion)
	return b

func guardar_nombre(_texto = ""):
	if listo:
		return   # evita guardar dos veces si se toca el botón y Enter a la vez
	listo = true
	var lb = Leaderboard.new()
	lb.agregar(campo.text, libres, tiempo)   # si el nombre viene vacío, queda "ANONIMO"
	salir()

func salir():
	get_tree().paused = false
	Registro.libres_inicio = 0   # la próxima partida empieza de cero
	get_tree().change_scene_to_file(Registro.MENU)
