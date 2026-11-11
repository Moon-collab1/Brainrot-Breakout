extends CanvasLayer

# Menú de pausa (autoload "Pausa"). Funciona solo en las zonas (escenas que tienen Jugador y HUD),
# tanto en JUGAR como en ARCADE. Se abre con Esc / botón B del mando / botón "II" de la pantalla.
const COLOR_ACENTO = Color(1.0, 0.25, 0.65)
const COLOR_ACENTO2 = Color(0.25, 0.9, 1.0)

var abierta = false   # lo lee controles_tactiles.gd para no despausar el juego mientras esto está abierto
var boton_pausa
var panel
var boton_continuar

func _ready():
	layer = 100   # sobre el HUD y bajo el filtro de daltonismo (capa 128)
	process_mode = Node.PROCESS_MODE_ALWAYS   # sigue funcionando con el juego pausado

	# botón "II" (esquina superior derecha, debajo del panel de zona/jefe del HUD)
	boton_pausa = Button.new()
	boton_pausa.text = "II"
	boton_pausa.focus_mode = Control.FOCUS_NONE   # que Espacio/Enter no lo activen sin querer
	boton_pausa.add_theme_font_size_override("font_size", 22)
	aplicar_estilo(boton_pausa)
	boton_pausa.pressed.connect(abrir)
	add_child(boton_pausa)
	boton_pausa.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	boton_pausa.offset_left = -68.0
	boton_pausa.offset_right = -16.0
	boton_pausa.offset_top = 100.0
	boton_pausa.offset_bottom = 152.0
	boton_pausa.visible = false

	# panel de pausa: fondo oscuro que también bloquea los clics hacia el juego
	panel = Control.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var oscuro = ColorRect.new()
	oscuro.color = Color(0.02, 0.01, 0.08, 0.72)
	oscuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(oscuro)
	oscuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro = CenterContainer.new()
	panel.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	centro.add_child(v)

	var titulo = Label.new()
	titulo.text = "PAUSA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.add_theme_color_override("font_color", Color.WHITE)
	titulo.add_theme_color_override("font_outline_color", Color(0.4, 0.0, 0.3))
	titulo.add_theme_constant_override("outline_size", 12)
	v.add_child(titulo)

	boton_continuar = crear_boton("CONTINUAR", cerrar)
	v.add_child(boton_continuar)
	v.add_child(crear_boton("VOLVER AL MENÚ PRINCIPAL", al_menu))
	panel.visible = false

func _process(_delta):
	# el botón "II" solo aparece dentro de una zona y con la pausa cerrada
	boton_pausa.visible = en_zona() and not abierta
	if abierta and not en_zona():
		cerrar()   # por seguridad, si la escena cambió con la pausa abierta

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and en_zona():
		if abierta:
			cerrar()
		else:
			abrir()
		get_viewport().set_input_as_handled()

# Una zona es cualquier escena con Jugador y HUD (el menú principal no los tiene)
func en_zona():
	var esc = get_tree().current_scene
	return esc != null and esc.has_node("Jugador") and esc.has_node("HUD")

func abrir():
	if abierta or not en_zona():
		return
	abierta = true
	panel.visible = true
	get_tree().paused = true
	boton_continuar.grab_focus()

func cerrar():
	abierta = false
	panel.visible = false
	get_tree().paused = false

func al_menu():
	# se guarda el récord igual que al morir; el progreso de la partida se pierde
	var j = get_tree().get_first_node_in_group("jugador")
	if j != null:
		j.reg.guardar(j.libres)
	cerrar()
	Registro.libres_inicio = 0
	get_tree().change_scene_to_file(Registro.MENU)

# ---------- estilo (el mismo del menú principal) ----------
func crear_boton(texto, accion):
	var b = Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(380, 56)
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
	b.add_theme_stylebox_override("normal", caja(Color(0.08, 0.06, 0.18, 0.9), Color(0.45, 0.35, 0.8, 0.8), 2, 10))
	b.add_theme_stylebox_override("hover", caja(Color(0.2, 0.1, 0.35, 0.95), COLOR_ACENTO2, 2, 10))
	b.add_theme_stylebox_override("pressed", caja(Color(0.35, 0.1, 0.4, 1.0), COLOR_ACENTO, 2, 10))
	var foco = caja(Color(0, 0, 0, 0), COLOR_ACENTO2, 3, 10)
	foco.draw_center = false
	b.add_theme_stylebox_override("focus", foco)
	b.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
