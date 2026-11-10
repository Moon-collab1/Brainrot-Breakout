extends Node

# Pantalla de victoria: la crea el Núcleo-∞ al morir (es el jefe FINAL).
# Congela las oleadas, guarda el récord, muestra el mensaje y a los 6 s vuelve al menú principal. Es un nodo aparte porque el jefe se libera justo después de morir.
const SEG_ESPERA = 6.0

func _ready():
	var zona = get_parent()
	var jug = zona.get_node("Jugador")
	zona.en_transicion = true   # oleadas.gd deja de lanzar oleadas
	jug.reg.guardar(jug.libres)
	# El Banner del HUD mide 282x86 (fuente 28): solo cabe "¡GANASTE!". El mensaje largo va en
	# un Label propio de esta escena (no se toca el HUD) y se borra solo al cambiar de escena.
	zona.get_node("HUD").mostrar_banner(true, "¡GANASTE!")
	mostrar_mensaje("Usaste el celular con cuidado")
	var t = Timer.new()
	t.one_shot = true
	add_child(t)
	t.timeout.connect(_reiniciar)
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

func _reiniciar():
	Registro.libres_inicio = 0   # la próxima partida empieza de cero
	get_tree().change_scene_to_file(Registro.MENU)
