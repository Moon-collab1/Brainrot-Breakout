extends Control

# Pantalla del celular del HUD: video aleatorio (Theora) o imagen de bloqueo.
# Se crea desde hud.gd y se añade dentro de SlotCelular/Pantalla.
# Respeta la pausa del juego: no usa PROCESS_MODE_ALWAYS.
const VIDEOS = [
	"res://comun/hud/assets/celular_1.ogv",
	"res://comun/hud/assets/celular_2.ogv",
	"res://comun/hud/assets/celular_3.ogv",
]
const RUTA_BLOQUEO = "res://comun/hud/assets/brainrot_bloqueado.png"
const VIDEO_TAM = Vector2(288, 512)   # tamaño real de los .ogv (9:16)

var jug   # jugador; lo asigna hud.gd antes de añadir el nodo
var reproductor
var imagen_bloqueo
var ultimo = -1
var encendido = false   # refleja jug.cel_abierto

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fondo = ColorRect.new()
	fondo.color = Color.BLACK
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	reproductor = VideoStreamPlayer.new()
	reproductor.expand = true
	reproductor.volume_db = -80.0
	reproductor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reproductor.finished.connect(reproducir_siguiente)
	add_child(reproductor)

	imagen_bloqueo = TextureRect.new()
	imagen_bloqueo.texture = load(RUTA_BLOQUEO)
	imagen_bloqueo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen_bloqueo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen_bloqueo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(imagen_bloqueo)
	imagen_bloqueo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	resized.connect(ajustar_video)
	ajustar_video()
	Ajustes.videos_celular_cambiado.connect(func(_p): actualizar())
	actualizar()

# Detecta cuándo se prende/apaga el celular (solo corre con el juego sin pausa)
func _process(_delta):
	var abierto = jug != null and jug.cel_abierto
	if abierto != encendido:
		encendido = abierto
		actualizar()

# Cubre todo el recuadro sin deformar: escala por el lado mayor y centra; clip_contents recorta
func ajustar_video():
	if reproductor == null:
		return
	var escala = maxf(size.x / VIDEO_TAM.x, size.y / VIDEO_TAM.y)
	var tam = VIDEO_TAM * escala
	reproductor.size = tam
	reproductor.position = (size - tam) / 2.0

# Apagado: todo en negro. Prendido: imagen de bloqueo o un video al azar (nuevo cada vez que se prende)
func actualizar():
	var permitido = Ajustes.videos_celular
	imagen_bloqueo.visible = encendido and not permitido
	reproductor.visible = encendido and permitido
	if encendido and permitido:
		reproducir_siguiente()
	else:
		reproductor.stop()
		reproductor.stream = null   # no se mantiene cargado mientras está apagado o bloqueado

# Elige un video distinto al anterior y lo reproduce con el mismo reproductor
func reproducir_siguiente():
	if not (encendido and Ajustes.videos_celular):
		return
	var i = randi() % VIDEOS.size()
	if VIDEOS.size() > 1:
		while i == ultimo:
			i = randi() % VIDEOS.size()
	ultimo = i
	reproductor.stream = load(VIDEOS[i])
	reproductor.play()
