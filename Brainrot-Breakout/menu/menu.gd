extends Control

# Menú principal (escena de inicio, ver project.godot). La interfaz se arma por código para que
# sea fácil de cambiar. Cada "pantalla" es un VBoxContainer; ir_a(nombre) muestra una y oculta
# las demás. Pantallas: principal, arcade (elegir zona), ajustes, controles (elegir teclas),
# ranking (leaderboard) y ayuda.
#   JUGAR   -> empieza en la Zona 1 y sigue sola hasta la 6 (modo_arcade = false)
#   ARCADE  -> juega UNA zona y al terminar vuelve aquí (modo_arcade = true)
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
var cont_ranking   # aquí se dibujan las filas del ranking
var b_ayuda        # el botón "?" de la esquina
# Pantalla de controles
var botones_control = {}     # acción -> botón que muestra su tecla
var accion_esperando = ""    # acción que está esperando una tecla nueva ("" = ninguna)
var filas_ayuda = {}         # textos de la ayuda que dependen de las teclas elegidas

func _ready():
	MusicaGlobal.reproducir_menu()
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
	pantallas["controles"] = crear_controles()
	pantallas["ranking"] = crear_ranking()
	pantallas["ayuda"] = crear_ayuda()
	for p in pantallas.values():
		centro.add_child(p)
	crear_boton_ayuda()
	ir_a("principal")

func _process(delta):
	t += delta
	eco.offset_left = 5.0 + sin(t * 2.5) * 3.0
	eco.offset_right = eco.offset_left
	titulo.pivot_offset = titulo.size / 2.0
	titulo.scale = Vector2.ONE * (1.0 + sin(t * 2.0) * 0.015)

# _input recibe las teclas ANTES que los botones del menú. Solo se usa mientras una acción
# espera su tecla nueva: lo primero que se presione (tecla o botón del ratón) queda asignado.
func _input(event):
	if accion_esperando == "":
		return
	if event.is_action_pressed("ui_cancel"):
		terminar_espera()      # Esc cancela sin cambiar nada
		get_viewport().set_input_as_handled()
		return
	var par = Ajustes.par_de_evento(event)
	if par != null:
		Ajustes.set_control(accion_esperando, par)   # guarda y, si la tecla estaba en uso, intercambia
		terminar_espera()
		get_viewport().set_input_as_handled()   # que ese clic/tecla no active nada más

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and actual != "principal":
		if actual == "controles":
			ir_a("ajustes")    # de controles se vuelve a configuración
		else:
			ir_a("principal")
		get_viewport().set_input_as_handled()

func ir_a(nombre):
	actual = nombre
	if b_ayuda != null:
		b_ayuda.visible = (nombre == "principal")   # el "?" solo se ve en el menú principal
	terminar_espera()          # si se sale de la pantalla de controles, se cancela la espera
	refrescar_ayuda()          # la ayuda muestra las teclas que estén elegidas ahora
	for k in pantallas:
		pantallas[k].visible = (k == nombre)
	if foco.has(nombre):
		foco[nombre].grab_focus()

# ---------- acciones ----------
func jugar():
	Registro.libres_inicio = 0
	Registro.modo_arcade = false
	Registro.tiempo = 0.0
	get_tree().change_scene_to_file(ESCENA_ZONA % [1, 1])   # sigue sola hasta la zona 6

func arcade(n):
	Registro.libres_inicio = 0
	Registro.tiempo = 0.0
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
	v.add_child(crear_boton("LEADERBOARD", abrir_ranking))
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

	# Los ajustes van dentro de un recuadro con barra de desplazamiento (igual que la ayuda):
	# así los botones CONTROLES y VOLVER de abajo siempre se ven, aunque la lista sea larga.
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var lista = VBoxContainer.new()   # aquí adentro van todas las filas de ajustes
	lista.add_theme_constant_override("separation", 12)
	lista.custom_minimum_size = Vector2(570, 0)
	scroll.add_child(lista)

	lista.add_child(crear_seccion("Sonido"))
	lista.add_child(crear_fila_volumen("Volumen general", "Master"))
	lista.add_child(crear_fila_volumen("Música", "Musica"))
	lista.add_child(crear_fila_volumen("Efectos", "Efectos"))
	var nota = Label.new()
	nota.text = "Música: menú, juego y celular. Efectos: cuando te hacen daño y cuando tú haces daño."
	nota.add_theme_font_size_override("font_size", 14)
	nota.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(nota)

	lista.add_child(crear_seccion("Accesibilidad"))
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
	lista.add_child(fila)
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
	lista.add_child(muestra)

	lista.add_child(crear_seccion("Celular"))
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
	lista.add_child(fila_cel)

	# abajo: botón para elegir las teclas y botón de volver, uno al lado del otro
	var fila_botones = HBoxContainer.new()
	fila_botones.add_theme_constant_override("separation", 16)
	fila_botones.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_botones.add_child(crear_boton("CONTROLES", func(): ir_a("controles"), Vector2(250, 50)))
	fila_botones.add_child(crear_boton("VOLVER", func(): ir_a("principal"), Vector2(250, 50)))
	v.add_child(fila_botones)
	return v

# ---------- pantalla de controles ----------
# Una fila por acción: nombre + botón con la tecla actual. Al pulsar el botón queda
# «esperando»: la próxima tecla o botón del ratón que se presione se asigna a esa acción.
func crear_controles():
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(640, 0)
	v.add_child(crear_subtitulo("CONTROLES"))
	var nota = Label.new()
	nota.text = "Pulsa un botón y luego la tecla (o botón del ratón) que quieras. Esc cancela."
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nota.add_theme_font_size_override("font_size", 16)
	nota.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	v.add_child(nota)

	# cuadrícula de 2 columnas: cada celda es «nombre de la acción + botón»
	var g = GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 24)
	g.add_theme_constant_override("v_separation", 10)
	v.add_child(g)
	for accion in Ajustes.ACCIONES:
		var celda = HBoxContainer.new()
		celda.add_theme_constant_override("separation", 10)
		celda.add_child(crear_etiqueta(Ajustes.NOMBRES_ACCION[accion], 110))
		var b = crear_boton("", func(): esperar_tecla(accion), Vector2(190, 44))
		b.add_theme_font_size_override("font_size", 20)
		celda.add_child(b)
		g.add_child(celda)
		botones_control[accion] = b
		if not foco.has("controles"):
			foco["controles"] = b

	# los dos modos ya armados
	v.add_child(crear_seccion("Modos rápidos"))
	var modos = HBoxContainer.new()
	modos.add_theme_constant_override("separation", 16)
	modos.alignment = BoxContainer.ALIGNMENT_CENTER
	var b1 = crear_boton("FLECHAS · ESPACIO · X", func(): poner_modo(Ajustes.MODO_FLECHAS), Vector2(300, 46))
	b1.add_theme_font_size_override("font_size", 18)
	var b2 = crear_boton("WASD · ESPACIO · CLIC DERECHO", func(): poner_modo(Ajustes.MODO_WASD), Vector2(300, 46))
	b2.add_theme_font_size_override("font_size", 18)
	modos.add_child(b1)
	modos.add_child(b2)
	v.add_child(modos)

	var volver = crear_boton("VOLVER", func(): ir_a("ajustes"), Vector2(250, 50))
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(volver)
	refrescar_controles()
	return v

# Escribe en cada botón la tecla que tiene ahora su acción
func refrescar_controles():
	for accion in botones_control:
		botones_control[accion].text = Ajustes.nombre_control(accion)

# El botón de esa acción queda esperando la tecla nueva (la recibe _input, arriba)
func esperar_tecla(accion):
	refrescar_controles()
	accion_esperando = accion
	botones_control[accion].text = "Pulsa una tecla…"

func terminar_espera():
	accion_esperando = ""
	refrescar_controles()

func poner_modo(modo):
	Ajustes.usar_modo(modo)
	terminar_espera()

# La pantalla de ayuda muestra las teclas que estén elegidas en este momento
func refrescar_ayuda():
	if filas_ayuda.is_empty():
		return
	# si las 4 direcciones son las flechas se escribe corto: "Flechas"
	var son_flechas = true
	var teclas = []
	for accion in ["mover_arriba", "mover_abajo", "mover_izquierda", "mover_derecha"]:
		teclas.append(Ajustes.nombre_control(accion))
		if Ajustes.controles[accion] != Ajustes.MODO_FLECHAS[accion]:
			son_flechas = false
	if son_flechas:
		filas_ayuda["mover"].text = "Flechas"
	else:
		filas_ayuda["mover"].text = " ".join(teclas)
	filas_ayuda["cachetada"].text = Ajustes.nombre_control("cachetada")
	filas_ayuda["celular"].text = Ajustes.nombre_control("celular")

func abrir_ranking():
	llenar_ranking()   # se vuelve a leer el archivo cada vez que se abre
	ir_a("ranking")

func crear_ranking():
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(560, 0)
	v.add_child(crear_subtitulo("LEADERBOARD · TOP 10"))
	cont_ranking = VBoxContainer.new()
	cont_ranking.add_theme_constant_override("separation", 2)
	v.add_child(cont_ranking)
	var volver = crear_boton("VOLVER", func(): ir_a("principal"), Vector2(250, 50))
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(volver)
	foco["ranking"] = volver
	return v

func llenar_ranking():
	for hijo in cont_ranking.get_children():
		hijo.queue_free()
	var lb = Leaderboard.new()
	if lb.lista.tam == 0:
		var vacio = crear_etiqueta("Todavía no hay puntajes. ¡Sé el primero en ganar!", 0)
		vacio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cont_ranking.add_child(vacio)
		return
	cont_ranking.add_child(crear_fila_ranking("#", "NOMBRE", "LIBERADOS", "TIEMPO", COLOR_ACENTO))
	for i in range(lb.lista.tam):
		var e = lb.lista.obtener(i)
		cont_ranking.add_child(crear_fila_ranking(str(i + 1), e.nombre, str(e.libres), Leaderboard.formato_tiempo(e.tiempo), Color.WHITE))

func crear_fila_ranking(puesto, nombre, libres, tiempo, color):
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	var datos = [[puesto, 40], [nombre, 220], [libres, 110], [tiempo, 90]]
	for d in datos:
		var l = crear_etiqueta(d[0], d[1])
		l.add_theme_font_size_override("font_size", 16)
		l.add_theme_color_override("font_color", color)
		fila.add_child(l)
	return fila

func crear_boton_ayuda():
	b_ayuda = Button.new()
	b_ayuda.text = "?"
	b_ayuda.tooltip_text = "Ayuda"
	b_ayuda.custom_minimum_size = Vector2(56, 56)
	b_ayuda.add_theme_font_size_override("font_size", 30)
	aplicar_estilo(b_ayuda)
	b_ayuda.pressed.connect(func(): ir_a("ayuda"))
	add_child(b_ayuda)
	b_ayuda.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)   # pegado a la esquina superior derecha
	b_ayuda.offset_left = -76.0
	b_ayuda.offset_right = -20.0
	b_ayuda.offset_top = 20.0
	b_ayuda.offset_bottom = 76.0

func crear_ayuda():
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(crear_subtitulo("AYUDA · CÓMO JUGAR"))
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 290)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var c = VBoxContainer.new()
	c.add_theme_constant_override("separation", 6)
	c.custom_minimum_size = Vector2(610, 0)
	scroll.add_child(c)

	c.add_child(crear_seccion("Objetivo"))
	c.add_child(crear_parrafo("Estás rodeado de zombis del scroll. Libéralos con tu cachetada de realidad y derrota al jefe de cada zona, sin perder la cabeza con el celular."))

	c.add_child(crear_seccion("Controles · teclado"))
	# las tres primeras filas muestran las teclas elegidas en CONFIGURACIÓN > CONTROLES
	# (refrescar_ayuda() las escribe; get_child(0) es el texto de la tecla de cada fila)
	var f_mover = crear_fila_control("", "Moverte")
	var f_golpe = crear_fila_control("", "Cachetada: golpea hacia donde miras")
	var f_cel = crear_fila_control("", "Abrir o cerrar el celular")
	filas_ayuda = {"mover": f_mover.get_child(0), "cachetada": f_golpe.get_child(0), "celular": f_cel.get_child(0)}
	c.add_child(f_mover)
	c.add_child(f_golpe)
	c.add_child(f_cel)
	c.add_child(crear_fila_control("Esc", "Pausa"))
	c.add_child(crear_parrafo("Puedes cambiar las teclas en CONFIGURACIÓN > CONTROLES."))

	c.add_child(crear_seccion("Controles · celular o tablet"))
	c.add_child(crear_fila_control("Joystick", "Moverte (lado izquierdo)"))
	c.add_child(crear_fila_control("CACHETADA", "Golpear hacia donde miras"))
	c.add_child(crear_fila_control("CELULAR", "Abrir o cerrar el celular"))
	c.add_child(crear_fila_control("Botón II", "Pausa"))

	c.add_child(crear_seccion("El celular"))
	c.add_child(crear_parrafo("Con el celular abierto recuperas vida, pero la barra de dopamina sube más rápido, te mueves más lento y la pantalla se ve borrosa alrededor de ti. Con el celular cerrado, la dopamina baja poco a poco."))

	c.add_child(crear_seccion("Cómo se pierde"))
	c.add_child(crear_parrafo("Si la dopamina llega al máximo o tu vida llega a cero, pierdes y reinicias la zona. La clave es abrir el celular solo cuando lo necesitas y cerrarlo a tiempo."))

	c.add_child(crear_seccion("Jefes"))
	c.add_child(crear_parrafo("Cada 5 oleadas aparece un jefe. Cada uno tiene su propio punto débil: observa sus ataques y busca cómo golpearlo."))

	c.add_child(crear_seccion("Ranking"))
	c.add_child(crear_parrafo("Al vencer al jefe final escribes tu nombre. El ranking ordena por zombis liberados y, si hay empate, gana quien tardó menos."))

	c.add_child(crear_seccion("Accesibilidad y ajustes"))
	c.add_child(crear_parrafo("En Ajustes puedes cambiar el volumen, elegir un filtro de color para daltonismo y decidir si el celular muestra videos cortos."))

	var volver = crear_boton("VOLVER", func(): ir_a("principal"), Vector2(250, 50))
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(volver)
	foco["ayuda"] = volver
	return v

func crear_parrafo(texto):
	var l = Label.new()
	l.text = texto
	l.custom_minimum_size = Vector2(600, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 18)
	return l

func crear_fila_control(tecla, desc):
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	var k = crear_etiqueta(tecla, 190)
	k.add_theme_color_override("font_color", COLOR_ACENTO2)
	fila.add_child(k)
	var d = crear_etiqueta(desc, 400)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(d)
	return fila

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
