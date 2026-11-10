extends CanvasLayer

# Controles táctiles: joystick flotante (mitad izquierda) + botones CACHETADA y CELULAR.
# Solo se activan en pantallas táctiles (celular/tableta). No toca la lógica del juego:
# solo dispara las mismas acciones que el teclado (mover_izquierda/derecha/arriba/abajo, celular, cachetada; las crea autoload/ajustes.gd).

const FORZAR_TACTIL = false      # true = mostrarlos también en PC (para probar con emulate_touch_from_mouse)
const RADIO_BASE = 85.0          # radio del círculo del joystick
const RADIO_PERILLA = 36.0
const RADIO_BOTON_GOLPE = 62.0
const RADIO_BOTON_CEL = 46.0
const ZONA_MUERTA = 0.12
const MARGEN_JOY = Vector2(150, 150)   # dónde se dibuja el joystick en reposo (desde la esquina inferior izquierda)

var activo = false
var lienzo: Control

var dedo_joy = -1
var centro_joy = Vector2.ZERO
var pos_joy = Vector2.ZERO
var dedo_golpe = -1
var dedo_cel = -1

func _ready():
	activo = FORZAR_TACTIL or _es_tactil()
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS   # para seguir leyendo toques si el juego se pausa
	if not activo:
		set_process_input(false)
		set_process(false)
		visible = false
		return
	lienzo = Control.new()
	lienzo.set_anchors_preset(Control.PRESET_FULL_RECT)
	lienzo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.draw.connect(_dibujar)
	add_child(lienzo)
	centro_joy = _joy_reposo()
	pos_joy = centro_joy

func _exit_tree():
	# al recargar la escena (morir) no deben quedar teclas "pegadas"
	if activo:
		_mover(Vector2.ZERO)
		get_tree().paused = false

func _es_tactil() -> bool:
	if OS.has_feature("web"):
		# en el navegador DisplayServer no siempre lo detecta: se pregunta al navegador
		var r = JavaScriptBridge.eval("(navigator.maxTouchPoints > 0) || ('ontouchstart' in window)")
		return bool(r)
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")

# ---------- posiciones (se calculan según el tamaño real de la pantalla) ----------
func _tam() -> Vector2:
	return get_viewport().get_visible_rect().size

func _joy_reposo() -> Vector2:
	var t = _tam()
	return Vector2(MARGEN_JOY.x, t.y - MARGEN_JOY.y)

func _pos_golpe() -> Vector2:
	var t = _tam()
	return Vector2(t.x - 240.0, t.y - 100.0)

func _pos_cel() -> Vector2:
	var t = _tam()
	return Vector2(t.x - 340.0, t.y - 195.0)

func _vertical() -> bool:
	var t = _tam()
	return t.y > t.x

# ---------- entrada ----------
func _process(_delta):
	# si el celular está en vertical se pausa y se pide girarlo
	var debe_pausar = _vertical() or Pausa.abierta   # Pausa.abierta: menú de pausa abierto
	if get_tree().paused != debe_pausar:
		get_tree().paused = debe_pausar
	lienzo.queue_redraw()

func _input(event):
	if event is InputEventScreenTouch:
		var p = event.position
		if event.pressed:
			if dedo_golpe == -1 and p.distance_to(_pos_golpe()) <= RADIO_BOTON_GOLPE * 1.25:
				dedo_golpe = event.index
				_accion("cachetada", true)
			elif dedo_cel == -1 and p.distance_to(_pos_cel()) <= RADIO_BOTON_CEL * 1.3:
				dedo_cel = event.index
				_accion("celular", true)
			elif dedo_joy == -1 and p.x < _tam().x * 0.5:
				dedo_joy = event.index
				centro_joy = p
				pos_joy = p
		else:
			if event.index == dedo_golpe:
				dedo_golpe = -1
				_accion("cachetada", false)
			elif event.index == dedo_cel:
				dedo_cel = -1
				_accion("celular", false)
			elif event.index == dedo_joy:
				dedo_joy = -1
				centro_joy = _joy_reposo()
				pos_joy = centro_joy
				_mover(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == dedo_joy:
		var d = event.position - centro_joy
		if d.length() > RADIO_BASE:
			d = d.normalized() * RADIO_BASE
		pos_joy = centro_joy + d
		_mover(d / RADIO_BASE)

# Convierte el joystick en las 4 acciones de dirección
func _mover(dir: Vector2):
	var m = dir.length()
	if m < ZONA_MUERTA:
		dir = Vector2.ZERO
	else:
		# Input.get_vector ignora lo menor a 0.5 (zona muerta de las acciones mover_*); se reescala para que
		# empujar poco = ir lento y empujar todo = velocidad máxima
		dir = dir.normalized() * (0.5 + 0.5 * clamp((m - ZONA_MUERTA) / (1.0 - ZONA_MUERTA), 0.0, 1.0))
	_fuerza("mover_izquierda", max(-dir.x, 0.0))
	_fuerza("mover_derecha", max(dir.x, 0.0))
	_fuerza("mover_arriba", max(-dir.y, 0.0))
	_fuerza("mover_abajo", max(dir.y, 0.0))

func _fuerza(nombre: String, f: float):
	if f > 0.01:
		Input.action_press(nombre, f)
	else:
		Input.action_release(nombre)

func _accion(nombre: String, presionada: bool):
	var e = InputEventAction.new()
	e.action = nombre
	e.pressed = presionada
	Input.parse_input_event(e)

# ---------- dibujo ----------
func _dibujar():
	var fuente = ThemeDB.fallback_font

	# joystick
	var mas_claro = dedo_joy != -1
	var a = 0.45 if mas_claro else 0.22
	lienzo.draw_circle(centro_joy, RADIO_BASE, Color(0, 0, 0, a))
	lienzo.draw_arc(centro_joy, RADIO_BASE, 0.0, TAU, 48, Color(1, 1, 1, a + 0.2), 3.0)
	lienzo.draw_circle(pos_joy, RADIO_PERILLA, Color(1, 1, 1, 0.55 if mas_claro else 0.3))

	# botón cachetada
	_boton(_pos_golpe(), RADIO_BOTON_GOLPE, "CACHETADA", 15, Color(1, 0.3, 0.3), dedo_golpe != -1, fuente)
	# botón celular
	_boton(_pos_cel(), RADIO_BOTON_CEL, "CELULAR", 13, Color(0.5, 0.85, 1.0), dedo_cel != -1, fuente)

	# aviso para girar el celular
	if _vertical():
		var t = _tam()
		lienzo.draw_rect(Rect2(Vector2.ZERO, t), Color(0, 0, 0, 0.88))
		var msg = "Gira tu celular de lado"
		var tam = 44
		var ancho = fuente.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		lienzo.draw_string(fuente, Vector2((t.x - ancho) / 2.0, t.y / 2.0), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color.WHITE)

func _boton(c: Vector2, r: float, texto: String, tam: int, color: Color, pulsado: bool, fuente: Font):
	var a = 0.65 if pulsado else 0.32
	lienzo.draw_circle(c, r, Color(color.r, color.g, color.b, a))
	lienzo.draw_arc(c, r, 0.0, TAU, 48, Color(1, 1, 1, 0.8), 3.0)
	var ancho = fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	lienzo.draw_string(fuente, Vector2(c.x - ancho / 2.0, c.y + tam * 0.35), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color.WHITE)
