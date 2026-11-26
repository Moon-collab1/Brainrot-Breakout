extends Node

# Transición entre zonas (autoload "Transicion"): fundido a negro + sonido, cambio de escena
# y fundido de regreso (1 s en total). La usa oleadas.gd en pasar_de_zona().
# La capa negra se crea en la raíz del árbol para que no se borre al cambiar de escena.
# Cada escena que se carga arranca su propia música (oleadas.gd o menu.gd), aquí solo se calla.

const RUTA_SONIDO = "res://assets/audio/cambio_zona.wav"
const DURACION_FUNDIDO = 0.5   # segundos de cada fundido (entrada y salida)

var color_rect: ColorRect
var audio_player: AudioStreamPlayer

func _ready() -> void:
	call_deferred("_inicializar_transicion")   # la raíz está ocupada durante _ready

func _inicializar_transicion() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	get_tree().root.add_child(canvas)

	color_rect = ColorRect.new()
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(color_rect)

	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Efectos"
	canvas.add_child(audio_player)
	if ResourceLoader.exists(RUTA_SONIDO):
		audio_player.stream = load(RUTA_SONIDO)

# Cambia a la escena "ruta_siguiente" con fundido. Si la capa aún no existe, cambia directo.
func cambiar_escena(ruta_siguiente: String) -> void:
	if not color_rect:
		get_tree().change_scene_to_file(ruta_siguiente)
		return

	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP   # bloquea clics mientras dura
	MusicaGlobal.detener()
	if audio_player and audio_player.stream:
		audio_player.play()

	# 1. fundido a negro
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, DURACION_FUNDIDO)
	await tween.finished

	# 2. cambio de escena
	get_tree().change_scene_to_file(ruta_siguiente)

	# 3. aclarar la pantalla
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "color:a", 0.0, DURACION_FUNDIDO)
	await tween_in.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
