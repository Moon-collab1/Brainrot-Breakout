extends Node

# Ajustes globales (autoload "Ajustes"): volumen, filtro de daltonismo y CONTROLES.
# Se guardan en user://ajustes.cfg y se aplican al abrir el juego, en cualquier escena.
# Los buses "Musica" y "Efectos" se crean aquí; cuando haya sonido, cada AudioStreamPlayer
# solo debe poner su "bus" en "Musica" o "Efectos".
signal videos_celular_cambiado(permitido)

const RUTA = "user://ajustes.cfg"
const BUSES = ["Master", "Musica", "Efectos"]
# El índice es el "mode" de daltonismo.gdshader
const NOMBRES_DALTONISMO = [
	"Normal (sin filtro)",
	"Protanopía (rojo)",
	"Deuteranopía (verde)",
	"Tritanopía (azul)",
]

var volumen = {"Master": 1.0, "Musica": 1.0, "Efectos": 1.0}   # de 0.0 a 1.0
var daltonismo = 0
var videos_celular = true   # true = permitido, false = bloqueado

# ---------- Controles (teclas que elige el jugador) ----------
# El juego usa 6 "acciones". Cada acción tiene UNA tecla o botón del ratón, que se puede cambiar
# en CONFIGURACIÓN > CONTROLES. Se guarda en el mismo archivo que el volumen.
const ACCIONES = ["mover_arriba", "mover_abajo", "mover_izquierda", "mover_derecha", "celular", "cachetada"]
const NOMBRES_ACCION = {
	"mover_arriba": "Arriba", "mover_abajo": "Abajo",
	"mover_izquierda": "Izquierda", "mover_derecha": "Derecha",
	"celular": "Celular", "cachetada": "Cachetada",
}
# Cada control es un par [tipo, código]: tipo "tecla" (código de la tecla) o "raton" (número de botón)
# Dos modos ya armados (botones de la pantalla de controles):
const MODO_FLECHAS = {
	"mover_arriba": ["tecla", KEY_UP], "mover_abajo": ["tecla", KEY_DOWN],
	"mover_izquierda": ["tecla", KEY_LEFT], "mover_derecha": ["tecla", KEY_RIGHT],
	"celular": ["tecla", KEY_SPACE], "cachetada": ["tecla", KEY_X],
}
const MODO_WASD = {
	"mover_arriba": ["tecla", KEY_W], "mover_abajo": ["tecla", KEY_S],
	"mover_izquierda": ["tecla", KEY_A], "mover_derecha": ["tecla", KEY_D],
	"celular": ["tecla", KEY_SPACE], "cachetada": ["raton", MOUSE_BUTTON_RIGHT],
}
# Nombres en español de las teclas especiales (las demás usan el nombre que da Godot)
const NOMBRES_TECLA = {
	KEY_UP: "Flecha arriba", KEY_DOWN: "Flecha abajo", KEY_LEFT: "Flecha izq.", KEY_RIGHT: "Flecha der.",
	KEY_SPACE: "Espacio", KEY_ENTER: "Enter", KEY_SHIFT: "Shift", KEY_CTRL: "Ctrl",
	KEY_ALT: "Alt", KEY_TAB: "Tab", KEY_BACKSPACE: "Borrar",
}
const NOMBRES_RATON = {
	MOUSE_BUTTON_LEFT: "Clic izquierdo", MOUSE_BUTTON_RIGHT: "Clic derecho", MOUSE_BUTTON_MIDDLE: "Clic central",
}

var controles = {}   # acción -> [tipo, código] (lo que está en uso ahora)

var filtro_rect
var filtro_mat

func _ready():
	crear_buses()
	crear_filtro()
	controles = MODO_FLECHAS.duplicate(true)   # por defecto: flechas, Espacio y X
	cargar()
	aplicar_audio()
	aplicar_daltonismo()
	aplicar_controles()

func crear_buses():
	for nombre in ["Musica", "Efectos"]:
		if AudioServer.get_bus_index(nombre) == -1:
			AudioServer.add_bus()
			var idx = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, nombre)
			AudioServer.set_bus_send(idx, "Master")

# Una capa por encima de todo con el shader: así el filtro vale en el menú y en todas las zonas
func crear_filtro():
	var capa = CanvasLayer.new()
	capa.layer = 128
	add_child(capa)
	filtro_mat = ShaderMaterial.new()
	filtro_mat.shader = load("res://shaders/daltonismo.gdshader")
	filtro_rect = ColorRect.new()
	filtro_rect.material = filtro_mat
	filtro_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE   # que no bloquee los clics
	capa.add_child(filtro_rect)
	filtro_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_volumen(bus, valor):
	volumen[bus] = clampf(valor, 0.0, 1.0)
	aplicar_audio()
	guardar()

func set_daltonismo(modo):
	daltonismo = clampi(modo, 0, NOMBRES_DALTONISMO.size() - 1)
	aplicar_daltonismo()
	guardar()

func set_videos_celular(valor):
	videos_celular = bool(valor)
	guardar()
	videos_celular_cambiado.emit(videos_celular)

func aplicar_audio():
	for bus in BUSES:
		var idx = AudioServer.get_bus_index(bus)
		if idx == -1:
			continue
		AudioServer.set_bus_volume_db(idx, linear_to_db(volumen[bus]))
		AudioServer.set_bus_mute(idx, volumen[bus] <= 0.001)

func aplicar_daltonismo():
	filtro_mat.set_shader_parameter("mode", daltonismo)
	filtro_rect.visible = daltonismo != 0   # en modo normal no se dibuja nada

func cargar():
	var cfg = ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return
	for bus in BUSES:
		volumen[bus] = clampf(float(cfg.get_value("audio", bus, 1.0)), 0.0, 1.0)
	daltonismo = clampi(int(cfg.get_value("accesibilidad", "daltonismo", 0)), 0, NOMBRES_DALTONISMO.size() - 1)
	videos_celular = bool(cfg.get_value("celular", "videos", true))
	# controles: solo se aceptan pares bien formados; si falta alguno queda el de por defecto
	for accion in ACCIONES:
		var par = cfg.get_value("controles", accion, null)
		if par is Array and par.size() == 2 and (par[0] == "tecla" or par[0] == "raton"):
			controles[accion] = [par[0], int(par[1])]

func guardar():
	var cfg = ConfigFile.new()
	for bus in BUSES:
		cfg.set_value("audio", bus, volumen[bus])
	cfg.set_value("accesibilidad", "daltonismo", daltonismo)
	cfg.set_value("celular", "videos", videos_celular)
	for accion in ACCIONES:
		cfg.set_value("controles", accion, controles[accion])
	cfg.save(RUTA)

# ---------- Controles: funciones ----------

# Crea el evento de Godot (tecla o botón del ratón) que corresponde a un par [tipo, código]
func evento_de(par):
	if par[0] == "raton":
		var raton = InputEventMouseButton.new()
		raton.button_index = par[1]
		return raton
	var tecla = InputEventKey.new()
	tecla.physical_keycode = par[1]   # "física" = la posición de la tecla, no depende del idioma del teclado
	return tecla

# Pone en el InputMap de Godot las teclas elegidas. Se llama al abrir el juego y cada vez que cambian.
func aplicar_controles():
	for accion in ACCIONES:
		if not InputMap.has_action(accion):
			InputMap.add_action(accion, 0.5)   # 0.5 = zona muerta (igual que las acciones ui_* de Godot)
		InputMap.action_erase_events(accion)   # se borra lo anterior
		InputMap.action_add_event(accion, evento_de(controles[accion]))
	agregar_mando()

# El mando (control de consola) siempre funciona igual; no se puede cambiar desde el menú
func agregar_mando():
	var ejes = {"mover_izquierda": [JOY_AXIS_LEFT_X, -1.0], "mover_derecha": [JOY_AXIS_LEFT_X, 1.0],
		"mover_arriba": [JOY_AXIS_LEFT_Y, -1.0], "mover_abajo": [JOY_AXIS_LEFT_Y, 1.0]}
	var botones = {"mover_izquierda": JOY_BUTTON_DPAD_LEFT, "mover_derecha": JOY_BUTTON_DPAD_RIGHT,
		"mover_arriba": JOY_BUTTON_DPAD_UP, "mover_abajo": JOY_BUTTON_DPAD_DOWN,
		"celular": JOY_BUTTON_A, "cachetada": JOY_BUTTON_X}
	for accion in ejes:
		var palanca = InputEventJoypadMotion.new()
		palanca.axis = ejes[accion][0]
		palanca.axis_value = ejes[accion][1]
		InputMap.action_add_event(accion, palanca)
	for accion in botones:
		var boton = InputEventJoypadButton.new()
		boton.button_index = botones[accion]
		InputMap.action_add_event(accion, boton)

# Cambia el control de una acción. Si esa tecla ya la usaba otra acción, se INTERCAMBIAN
# (así nunca quedan dos acciones con la misma tecla ni una acción sin tecla).
func set_control(accion, par):
	for otra in ACCIONES:
		if otra != accion and controles[otra] == par:
			controles[otra] = controles[accion]
	controles[accion] = par
	aplicar_controles()
	guardar()

# Pone uno de los dos modos ya armados (MODO_FLECHAS o MODO_WASD)
func usar_modo(modo):
	controles = modo.duplicate(true)
	aplicar_controles()
	guardar()

# Convierte lo que el jugador presionó en un par [tipo, código]. Devuelve null si no sirve
# (por ejemplo Esc, que es la pausa, o soltar una tecla).
func par_de_evento(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.physical_keycode == KEY_NONE:
			return null
		return ["tecla", int(event.physical_keycode)]
	if event is InputEventMouseButton and event.pressed:
		if event.button_index >= MOUSE_BUTTON_WHEEL_UP and event.button_index <= MOUSE_BUTTON_WHEEL_RIGHT:
			return null   # la rueda del ratón no sirve como botón
		return ["raton", int(event.button_index)]
	return null

# Nombre para mostrar en pantalla: "Flecha arriba", "Espacio", "W", "Clic derecho"...
func nombre_control(accion):
	var par = controles[accion]
	if par[0] == "raton":
		return NOMBRES_RATON.get(par[1], "Ratón botón %d" % par[1])
	if NOMBRES_TECLA.has(par[1]):
		return NOMBRES_TECLA[par[1]]
	return OS.get_keycode_string(par[1])
