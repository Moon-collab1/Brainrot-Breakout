extends Node

# Música global (autoload "MusicaGlobal"). Un solo reproductor que sobrevive a los cambios de
# escena, así la música no se corta ni se duplica al pasar del menú a una zona.
#   - menu.gd llama reproducir_menu()
#   - oleadas.gd (raíz de cada zona) llama reproducir_juego()
#   - transicion.gd llama detener() al empezar el fundido entre zonas
# Va por el bus "Musica", que crea ajustes.gd, para que el slider de volumen del menú funcione.

const PISTA_MENU = "res://assets/audio/musica_menu.mp3"
const PISTA_JUEGO = "res://assets/audio/musica_juego.mp3"

var audio_player: AudioStreamPlayer

func _ready() -> void:
	# Se crea de inmediato para que nunca sea null
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.bus = "Musica"

func reproducir_menu() -> void:
	_reproducir(PISTA_MENU)

func reproducir_juego() -> void:
	_reproducir(PISTA_JUEGO)

func detener() -> void:
	if audio_player:
		audio_player.stop()

# Pone "ruta" en bucle. Si ya está sonando esa misma pista no la reinicia.
func _reproducir(ruta: String) -> void:
	if not audio_player:
		return
	if audio_player.playing and audio_player.stream and audio_player.stream.resource_path == ruta:
		return
	if ResourceLoader.exists(ruta):
		var archivo = ResourceLoader.load(ruta)
		if archivo is AudioStreamMP3:
			archivo.loop = true
		audio_player.stream = archivo
		audio_player.play()
