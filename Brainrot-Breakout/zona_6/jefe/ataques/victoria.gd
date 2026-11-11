extends Node

# Pantalla de victoria: la crea el Núcleo-∞ al morir (es el jefe FINAL del juego).
# Es un nodo aparte porque el jefe se libera justo después de morir.
#   1. Congela las oleadas, detiene al jugador (y con él el cronómetro) y guarda el récord.
#   2. Muestra «¡GANASTE!» en el Banner del HUD y un mensaje propio.
#   3. Modo JUGAR: pide un nombre y guarda el puntaje en el Leaderboard (libres + tiempo).
#      Modo ARCADE: no hay ranking (solo se jugó una zona); vuelve solo al menú tras 6 s.
# Siempre termina volviendo al menú principal.
const SEG_ESPERA = 6.0   # solo en ARCADE: segundos antes de volver al menú

var campo_nombre: LineEdit
var jug

func _ready():
	var zona = get_parent()
	jug = zona.get_node("Jugador")
	zona.en_transicion = true   # oleadas.gd deja de lanzar oleadas
	jug.set_physics_process(false)   # detiene al jugador y el cronómetro de la partida
	jug.reg.guardar(jug.libres)
	# El Banner del HUD mide 282x86 (fuente 28): solo cabe "¡GANASTE!". El mensaje largo va en
	# un Label propio de esta escena (no se toca el HUD) y se borra solo al cambiar de escena.
	zona.get_node("HUD").mostrar_banner(true, "¡GANASTE!")
	mostrar_mensaje("Usaste el celular con cuidado")
	if Registro.modo_arcade:
		var t = Timer.new()
		t.one_shot = true
		add_child(t)
		t.timeout.connect(_reiniciar)
		t.start(SEG_ESPERA)
	else:
		pedir_nombre()

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

# Campo de texto + botón para guardar el nombre en el ranking (Enter también guarda)
func pedir_nombre():
	var capa = CanvasLayer.new()
	add_child(capa)
	var caja = VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	capa.add_child(caja)
	caja.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	caja.offset_left = -170.0
	caja.offset_right = 170.0
	caja.offset_top = -10.0
	caja.offset_bottom = 90.0

	campo_nombre = LineEdit.new()
	campo_nombre.placeholder_text = "Tu nombre"
	campo_nombre.max_length = Leaderboard.MAX_NOMBRE
	campo_nombre.alignment = HORIZONTAL_ALIGNMENT_CENTER
	campo_nombre.add_theme_font_size_override("font_size", 24)
	campo_nombre.text_submitted.connect(func(_t): guardar_puntaje())
	caja.add_child(campo_nombre)

	var boton = Button.new()
	boton.text = "GUARDAR PUNTAJE"
	boton.add_theme_font_size_override("font_size", 22)
	boton.pressed.connect(guardar_puntaje)
	caja.add_child(boton)
	campo_nombre.grab_focus()

func guardar_puntaje():
	var lb = Leaderboard.new()
	lb.agregar(campo_nombre.text, jug.libres, Registro.tiempo)
	_reiniciar()

func _reiniciar():
	Registro.libres_inicio = 0   # la próxima partida empieza de cero
	get_tree().change_scene_to_file(Registro.MENU)
