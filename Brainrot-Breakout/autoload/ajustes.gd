extends Node

# Ajustes globales (autoload "Ajustes"): volumen y filtro de daltonismo.
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

var filtro_rect
var filtro_mat

func _ready():
	crear_buses()
	crear_filtro()
	cargar()
	aplicar_audio()
	aplicar_daltonismo()

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

func guardar():
	var cfg = ConfigFile.new()
	for bus in BUSES:
		cfg.set_value("audio", bus, volumen[bus])
	cfg.set_value("accesibilidad", "daltonismo", daltonismo)
	cfg.set_value("celular", "videos", videos_celular)
	cfg.save(RUTA)
