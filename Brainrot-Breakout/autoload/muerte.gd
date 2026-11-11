extends CanvasLayer

# Pantalla de muerte (autoload "Muerte"). La llama jugador.gd en perder().
# Antes el juego se reiniciaba de golpe; ahora:
#   1. destello rojo + sonido de daño y el juego se congela
#   2. la pantalla se oscurece y aparece "¡TE MORISTE!" con la razón y los zombis liberados
#   3. el jugador elige REINTENTAR (misma zona, con fundido) o MENÚ
# Los botones se activan tras una pequeña espera para que nadie los pulse sin querer
# (por ejemplo, mientras seguía golpeando con la cachetada).

const COLOR_ACENTO = Color(1.0, 0.25, 0.65)
const COLOR_ACENTO2 = Color(0.25, 0.9, 1.0)
const ESPERA_BOTONES = 0.9   # segundos antes de poder pulsar los botones

var activa = false   # true mientras se ve la pantalla (la pausa y jugador.gd la consultan)
var raiz: Control    # contenedor de todo lo que se dibuja
var fondo: ColorRect
var caja_texto: VBoxContainer
var lbl_titulo: Label
var lbl_razon: Label
var lbl_libres: Label
var boton_reintentar: Button
var boton_menu: Button

func _ready():
	layer = 110   # sobre el HUD y la pausa (100), bajo el filtro de daltonismo (128)
	process_mode = Node.PROCESS_MODE_ALWAYS   # sigue funcionando con el juego congelado

	raiz = Control.new()
	add_child(raiz)
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP   # bloquea los clics hacia el juego
	raiz.visible = false

	# fondo rojo/oscuro: primero destella y luego se queda casi negro
	fondo = ColorRect.new()
	fondo.color = Color(0.8, 0.0, 0.1, 0.0)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# textos y botones centrados en una columna
	var centro = CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	caja_texto = VBoxContainer.new()
	caja_texto.add_theme_constant_override("separation", 14)
	caja_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(caja_texto)

	lbl_titulo = crear_texto("¡TE MORISTE!", 72, Color(1.0, 0.25, 0.3))
	lbl_titulo.add_theme_constant_override("outline_size", 10)
	lbl_titulo.add_theme_color_override("font_outline_color", Color(0.1, 0, 0.05))
	lbl_razon = crear_texto("", 28, Color(1, 0.9, 0.9))
	lbl_libres = crear_texto("", 24, COLOR_ACENTO2)
	caja_texto.add_child(lbl_titulo)
	caja_texto.add_child(lbl_razon)
	caja_texto.add_child(lbl_libres)

	var espacio = Control.new()
	espacio.custom_minimum_size = Vector2(0, 18)
	espacio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja_texto.add_child(espacio)

	boton_reintentar = crear_boton("REINTENTAR", reintentar)
	boton_menu = crear_boton("MENÚ PRINCIPAL", ir_al_menu)
	caja_texto.add_child(boton_reintentar)
	caja_texto.add_child(boton_menu)

func crear_texto(texto, tam, color):
	var l = Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func crear_boton(texto, accion):
	var b = Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(380, 56)
	b.add_theme_font_size_override("font_size", 24)
	# mismo estilo que el menú de pausa para que todo se vea igual
	b.add_theme_stylebox_override("normal", estilo(Color(0.08, 0.06, 0.18, 0.9), Color(0.45, 0.35, 0.8, 0.8)))
	b.add_theme_stylebox_override("hover", estilo(Color(0.2, 0.1, 0.35, 0.95), COLOR_ACENTO2))
	b.add_theme_stylebox_override("pressed", estilo(Color(0.35, 0.1, 0.4, 1.0), COLOR_ACENTO))
	b.add_theme_stylebox_override("disabled", estilo(Color(0.05, 0.05, 0.08, 0.7), Color(0.3, 0.3, 0.4, 0.5)))
	b.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.6))
	b.pressed.connect(accion)
	return b

func estilo(fondo_color, borde):
	var s = StyleBoxFlat.new()
	s.bg_color = fondo_color
	s.border_color = borde
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

# La llama jugador.gd: "razon" es el texto de por qué perdió y "libres" los zombis liberados
func mostrar(razon, libres):
	if activa:
		return   # perder() puede llamarse dos veces en el mismo cuadro (vida y dopamina)
	activa = true
	get_tree().paused = true   # congela zombis, jefe y jugador
	MusicaGlobal.detener()
	if MusicaGlobal.audio_dano:
		MusicaGlobal.audio_dano.play()   # el mismo sonido de "me hicieron daño"

	lbl_razon.text = razon
	lbl_libres.text = "Zombis liberados: %d" % libres
	boton_reintentar.disabled = true
	boton_menu.disabled = true
	caja_texto.modulate.a = 0.0
	caja_texto.scale = Vector2(0.8, 0.8)
	caja_texto.pivot_offset = caja_texto.size / 2.0
	fondo.color = Color(0.8, 0.0, 0.1, 0.0)
	raiz.visible = true

	var tw = create_tween()   # corre aunque el juego esté pausado (este nodo es ALWAYS)
	# 1. destello rojo fuerte
	tw.tween_property(fondo, "color:a", 0.65, 0.12)
	# 2. se oscurece hasta casi negro (rojo muy oscuro)
	tw.tween_property(fondo, "color", Color(0.06, 0.0, 0.03, 0.88), 0.6)
	# 3. el texto aparece haciéndose grande
	tw.tween_property(caja_texto, "modulate:a", 1.0, 0.4)
	tw.parallel().tween_property(caja_texto, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 4. un momento después se pueden pulsar los botones
	tw.tween_interval(max(ESPERA_BOTONES - 0.4, 0.0))
	tw.tween_callback(activar_botones)

func activar_botones():
	boton_reintentar.disabled = false
	boton_menu.disabled = false
	boton_reintentar.grab_focus()   # para jugar con teclado o mando

# REINTENTAR: fundido a negro, se recarga la zona y se vuelve a ver el juego
func reintentar():
	salir(func(): get_tree().reload_current_scene())

# MENÚ: se pierde el progreso de la partida (igual que "Salir al menú" de la pausa)
func ir_al_menu():
	Registro.libres_inicio = 0
	salir(func(): get_tree().change_scene_to_file(Registro.MENU))

# Fundido a negro -> hace el cambio de escena -> la pantalla de muerte se esconde
func salir(cambio: Callable):
	boton_reintentar.disabled = true
	boton_menu.disabled = true
	var tw = create_tween()
	tw.tween_property(fondo, "color", Color(0, 0, 0, 1.0), 0.35)
	tw.parallel().tween_property(caja_texto, "modulate:a", 0.0, 0.25)
	await tw.finished
	get_tree().paused = false
	activa = false
	cambio.call()
	await get_tree().process_frame   # espera a que la escena nueva exista
	var tw_in = create_tween()
	tw_in.tween_property(fondo, "color:a", 0.0, 0.4)
	await tw_in.finished
	raiz.visible = false
