extends Control

# Menú principal. La interfaz se arma por código para que sea fácil de cambiar.
# Pantallas: principal, arcade y ajustes (el leaderboard queda desactivado por ahora).
const NOMBRE_JUEGO = "BRAINROT BREAKOUT"
const ESCENA_ZONA = "res://zona_%d/zona_%d.tscn"
const COLOR_ACENTO = Color(1.0, 0.25, 0.65)
const COLOR_ACENTO2 = Color(0.25, 0.9, 1.0)

# [nombre de la zona, nombre del jefe] (los mismos que en cada zona_N.tscn)
const ZONAS = [
	["CALLE", "INFLUENCER"],
	["EDIFICIO SOCIAL", "ALGORITMO"],
	["ZONA DE CARGA", "CAPATAZ"],
	["ASCENSOR", "GEMELO"],
	["LABORATORIO", "DOPAMINA"],
	["SUPERCOMPUTADORAS", "NÚCLEO-∞"],
]

var pantallas = {}
var foco = {}          # primer botón de cada pantalla (para teclado y mando)
var actual = "principal"
var titulo
var eco
var t = 0.0

func _ready():
	var fondo = Control.new()
	fondo.set_script(load("res://menu/fondo_menu.gd"))
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	eco = crear_titulo(COLOR_ACENTO2, 5.0)
	titulo = crear_titulo(Color.WHITE, 0.0)

	var centro = CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.offset_top = 190.0   # deja libre la zona del título

	pantallas["principal"] = crear_principal()
	pantallas["arcade"] = crear_arcade()
	pantallas["ajustes"] = crear_ajustes()
	for p in pantallas.values():
		centro.add_child(p)
	ir_a("principal")

func _process(delta):
	t += delta
	eco.offset_left = 5.0 + sin(t * 2.5) * 3.0
	eco.offset_right = eco.offset_left
	titulo.pivot_offset = titulo.size / 2.0
	titulo.scale = Vector2.ONE * (1.0 + sin(t * 2.0) * 0.015)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and actual != "principal":
		ir_a("principal")
		get_viewport().set_input_as_handled()

func ir_a(nombre):
	actual = nombre
	for k in pantallas:
		pantallas[k].visible = (k == nombre)
	if foco.has(nombre):
		foco[nombre].grab_focus()

# ---------- acciones ----------
func jugar():
	Registro.libres_inicio = 0
	Registro.modo_arcade = false
	get_tree().change_scene_to_file(ESCENA_ZONA % [1, 1])   # sigue sola hasta la zona 6

func arcade(n):
	Registro.libres_inicio = 0
	Registro.modo_arcade = true   # al terminar la zona se vuelve a este menú
	get_tree().change_scene_to_file(ESCENA_ZONA % [n, n])

func salir():
	get_tree().quit()

# ---------- pantallas ----------
func crear_principal():
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	var b_jugar = crear_boton("JUGAR", jugar)
	v.add_child(b_jugar)
	v.add_child(crear_boton("ARCADE", func(): ir_a("arcade")))
	v.add_child(crear_boton("CONFIGURACIÓN", func(): ir_a("ajustes")))
	var b_lb = crear_boton("LEADERBOARD · PRONTO", func(): pass)
	b_lb.disabled = true   # pendiente
	v.add_child(b_lb)
	if not OS.has_feature("web"):   # en el navegador quit() no hace nada
		v.add_child(crear_boton("SALIR", salir))
	foco["principal"] = b_jugar
	return v

func crear_arcade():
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.add_child(crear_subtitulo("ARCADE · ELIGE UNA ZONA"))
	var g = GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 16)
	g.add_theme_constant_override("v_separation", 16)
	v.add_child(g)
	for i in range(ZONAS.size()):
		var n = i + 1
		var texto = "ZONA %d\n%s\nJefe: %s" % [n, ZONAS[i][0], ZONAS[i][1]]
		var b = crear_boton(texto, func(): arcade(n), Vector2(250, 104))
		b.add_theme_font_size_override("font_size", 18)
		g.add_child(b)
		if i == 0:
			foco["arcade"] = b
	var volver = crear_boton("VOLVER", func(): ir_a("principal"), Vector2(250, 50))
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(volver)
	return v

func crear_ajustes():
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(560, 0)
	v.add_child(crear_subtitulo("CONFIGURACIÓN"))

	v.add_child(crear_seccion("Sonido"))
	v.add_child(crear_fila_volumen("Volumen general", "Master"))
	v.add_child(crear_fila_volumen("Música", "Musica"))
	v.add_child(crear_fila_volumen("Efectos", "Efectos"))
	var nota = Label.new()
	nota.text = "Todavía no hay sonido en el juego; los controles ya quedan listos."
	nota.add_theme_font_size_override("font_size", 14)
	nota.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nota)

	v.add_child(crear_seccion("Accesibilidad"))
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.add_child(crear_etiqueta("Daltonismo", 170))
	var op = OptionButton.new()
	for nombre in Ajustes.NOMBRES_DALTONISMO:
		op.add_item(nombre)
	op.select(Ajustes.daltonismo)
	op.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	op.custom_minimum_size = Vector2(0, 44)
	op.add_theme_font_size_override("font_size", 20)
	aplicar_estilo(op)
	op.item_selected.connect(func(i): Ajustes.set_daltonismo(i))
	fila.add_child(op)
	v.add_child(fila)
	foco["ajustes"] = op

	# Colores de muestra: el filtro es global, así se ve el efecto al instante
	var muestra = HBoxContainer.new()
	muestra.add_theme_constant_override("separation", 8)
	muestra.alignment = BoxContainer.ALIGNMENT_CENTER
	for c in [Color(0.9, 0.1, 0.1), Color(0.1, 0.8, 0.2), Color(0.1, 0.3, 0.95),
			Color(1.0, 0.9, 0.1), Color(1.0, 0.5, 0.0), Color(0.6, 0.2, 0.8)]:
		var r = ColorRect.new()
		r.color = c
		r.custom_minimum_size = Vector2(60, 26)
		muestra.add_child(r)
	v.add_child(muestra)

	v.add_child(crear_seccion("Celular"))
	var fila_cel = HBoxContainer.new()
	fila_cel.add_theme_constant_override("separation", 12)
	fila_cel.add_child(crear_etiqueta("Videos del celular", 170))
	var chk = CheckButton.new()
	chk.button_pressed = Ajustes.videos_celular
	chk.text = "Permitir" if chk.button_pressed else "Bloqueado"
	chk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chk.custom_minimum_size = Vector2(0, 44)
	chk.add_theme_font_size_override("font_size", 20)
	aplicar_estilo(chk)
	chk.toggled.connect(func(activo):
		chk.text = "Permitir" if activo else "Bloqueado"
		Ajustes.set_videos_celular(activo))
	fila_cel.add_child(chk)
	v.add_child(fila_cel)

	var volver = crear_boton("VOLVER", func(): ir_a("principal"), Vector2(250, 50))
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(volver)
	return v

func crear_fila_volumen(texto, bus):
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.add_child(crear_etiqueta(texto, 170))
	var s = HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.step = 1
	s.value = Ajustes.volumen[bus] * 100.0
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.custom_minimum_size = Vector2(240, 24)
	s.add_theme_stylebox_override("slider", caja(Color(0.15, 0.12, 0.3), Color(0, 0, 0, 0), 0, 4))
	s.add_theme_stylebox_override("grabber_area", caja(COLOR_ACENTO, Color(0, 0, 0, 0), 0, 4))
	s.add_theme_stylebox_override("grabber_area_highlight", caja(COLOR_ACENTO2, Color(0, 0, 0, 0), 0, 4))
	var p = crear_etiqueta("%d%%" % int(s.value), 56)
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	s.value_changed.connect(func(val):
		p.text = "%d%%" % int(val)
		Ajustes.set_volumen(bus, val / 100.0))
	fila.add_child(s)
	fila.add_child(p)
	return fila

# ---------- piezas de interfaz ----------
func crear_titulo(color, desplaz):
	var l = Label.new()
	l.text = NOMBRE_JUEGO
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 76)
	l.add_theme_color_override("font_color", color)
	if desplaz == 0.0:   # el título de arriba lleva borde; el eco de atrás no
		l.add_theme_color_override("font_outline_color", Color(0.4, 0.0, 0.3))
		l.add_theme_constant_override("outline_size", 12)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	l.offset_top = 50.0 + desplaz * 0.8
	l.offset_bottom = 160.0 + desplaz * 0.8
	l.offset_left = desplaz
	l.offset_right = desplaz
	return l

func crear_subtitulo(texto):
	var l = Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", COLOR_ACENTO2)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	return l

func crear_seccion(texto):
	var l = Label.new()
	l.text = texto.to_upper()
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", COLOR_ACENTO)
	return l

func crear_etiqueta(texto, ancho):
	var l = Label.new()
	l.text = texto
	l.custom_minimum_size = Vector2(ancho, 0)
	l.add_theme_font_size_override("font_size", 20)
	return l

func crear_boton(texto, accion, tam = Vector2(340, 56)):
	var b = Button.new()
	b.text = texto
	b.custom_minimum_size = tam
	b.add_theme_font_size_override("font_size", 24)
	aplicar_estilo(b)
	b.pressed.connect(accion)
	return b

func caja(fondo, borde, ancho_borde, radio):
	var s = StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = borde
	s.set_border_width_all(ancho_borde)
	s.set_corner_radius_all(radio)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func aplicar_estilo(b):
	b.add_theme_stylebox_override("normal", caja(Color(0.08, 0.06, 0.18, 0.85), Color(0.45, 0.35, 0.8, 0.8), 2, 10))
	b.add_theme_stylebox_override("hover", caja(Color(0.2, 0.1, 0.35, 0.95), COLOR_ACENTO2, 2, 10))
	b.add_theme_stylebox_override("pressed", caja(Color(0.35, 0.1, 0.4, 1.0), COLOR_ACENTO, 2, 10))
	b.add_theme_stylebox_override("disabled", caja(Color(0.06, 0.05, 0.12, 0.7), Color(0.25, 0.22, 0.4, 0.6), 2, 10))
	var foco_estilo = caja(Color(0, 0, 0, 0), COLOR_ACENTO2, 3, 10)
	foco_estilo.draw_center = false
	b.add_theme_stylebox_override("focus", foco_estilo)
	b.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.62))
