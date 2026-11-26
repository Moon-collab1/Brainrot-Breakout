extends CanvasLayer

# Pantalla que aparece al subir de nivel: 3 tarjetas con poderes al azar y se elige una.
# La crea jugador.gd (revisar_poderes), pausa el juego mientras está abierta y, al elegir,
# le avisa al jugador con poder_elegido(id). Se elige con el mouse, tocando la tarjeta,
# con las teclas 1 / 2 / 3, o con flechas/mando + aceptar.
const COLOR_ACENTO2 = Color(0.25, 0.9, 1.0)

var jug              # el Jugador (lo pone jugador.gd antes de añadirlo a la escena)
var opciones = []    # ids de los poderes que se ofrecen
var botones = []
var t_abierto = 0
var elegido = false

func _ready():
	layer = 110   # sobre la pausa (100) y bajo el filtro de daltonismo (128)
	process_mode = Node.PROCESS_MODE_ALWAYS
	Poderes.eligiendo = true
	get_tree().paused = true
	t_abierto = Time.get_ticks_msec()

	var oscuro = ColorRect.new()
	oscuro.color = Color(0.02, 0.01, 0.08, 0.82)
	oscuro.mouse_filter = Control.MOUSE_FILTER_STOP   # bloquea los clics hacia el juego
	add_child(oscuro)
	oscuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro = CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(v)

	var titulo = Label.new()
	titulo.text = "¡NIVEL %d!" % jug.nivel
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 52)
	titulo.add_theme_color_override("font_color", Color(0.55, 1.0, 1.0))
	titulo.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.15))
	titulo.add_theme_constant_override("outline_size", 10)
	v.add_child(titulo)

	var sub = Label.new()
	sub.text = "ELIGE UN PODER"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color.WHITE)
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	sub.add_theme_constant_override("outline_size", 6)
	v.add_child(sub)

	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 18)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(fila)
	for i in range(opciones.size()):
		var b = crear_tarjeta(opciones[i], i)
		botones.append(b)
		fila.add_child(b)

	var pista = Label.new()
	pista.text = "Toca una tarjeta  ·  o teclas 1 / 2 / 3"
	pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pista.add_theme_font_size_override("font_size", 16)
	pista.add_theme_color_override("font_color", Color(0.75, 0.75, 0.9))
	v.add_child(pista)

	# aparece con un fundido corto
	v.modulate.a = 0.0
	create_tween().tween_property(v, "modulate:a", 1.0, 0.25)

	if not botones.is_empty():
		botones[0].grab_focus()   # para jugar con teclado o mando

func _exit_tree():
	# por si la escena se cambia con el selector abierto: que no quede la pausa pegada
	if not elegido:
		Poderes.eligiendo = false
		if is_inside_tree():
			get_tree().paused = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()   # Esc no abre la pausa encima
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var n = -1
		if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			n = 0
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			n = 1
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			n = 2
		if n >= 0 and n < opciones.size():
			elegir(n)
			get_viewport().set_input_as_handled()

func elegir(i):
	# un instante de guarda para que un clic o tecla de la partida no elija sin querer
	if elegido or Time.get_ticks_msec() - t_abierto < 450:
		return
	elegido = true
	Poderes.eligiendo = false
	get_tree().paused = false
	jug.poder_elegido(opciones[i])
	queue_free()

# Una tarjeta es un botón con las etiquetas encima (ninguna recibe clics: el botón se lleva todos)
func crear_tarjeta(id, i):
	var actual = Poderes.cat(id)
	var nueva = actual + 1
	var color = Poderes.COLORES[id]

	var b = Button.new()
	b.custom_minimum_size = Vector2(310, 330)
	b.focus_mode = Control.FOCUS_ALL
	Pausa.aplicar_estilo(b)
	b.pressed.connect(elegir.bind(i))

	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(col)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 14.0
	col.offset_right = -14.0
	col.offset_top = 14.0
	col.offset_bottom = -12.0

	var franja = ColorRect.new()
	franja.color = color
	franja.custom_minimum_size = Vector2(0, 6)
	franja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(franja)

	col.add_child(etiqueta(Poderes.NOMBRES[id], 25, color, true))

	var estado = "NUEVO" if actual == 0 else "CATEGORÍA %d  >  %d" % [actual, nueva]
	col.add_child(etiqueta(estado, 15, Color(1.0, 0.95, 0.5), false))

	# cinco rectangulitos: llenos = ya los tienes, brillante = el que ganas, gris = vacíos
	var pips = HBoxContainer.new()
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	pips.add_theme_constant_override("separation", 6)
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in range(1, Poderes.MAX_CAT + 1):
		var p = ColorRect.new()
		p.custom_minimum_size = Vector2(30, 12)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if k < nueva:
			p.color = color
		elif k == nueva:
			p.color = Color(1.0, 0.95, 0.5)
		else:
			p.color = Color(0.2, 0.2, 0.28)
		pips.add_child(p)
	col.add_child(pips)

	var desc = etiqueta(Poderes.RESUMEN[id], 17, Color(0.92, 0.92, 1.0), false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(270, 60)
	col.add_child(desc)

	var efecto = etiqueta(Poderes.efecto(id, nueva), 18, COLOR_ACENTO2, false)
	efecto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	efecto.custom_minimum_size = Vector2(270, 50)
	col.add_child(efecto)

	col.add_child(etiqueta("[ %d ]" % (i + 1), 16, Color(0.6, 0.6, 0.8), false))
	return b

func etiqueta(texto, tam, color, borde):
	var l = Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	if borde:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		l.add_theme_constant_override("outline_size", 6)
	return l
