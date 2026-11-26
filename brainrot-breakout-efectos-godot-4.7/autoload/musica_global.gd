extends Node

# Música global (autoload "MusicaGlobal"). Un solo reproductor que sobrevive a los cambios de
# escena, así la música no se corta ni se duplica al pasar del menú a una zona.
#   - menu.gd llama reproducir_menu()
#   - oleadas.gd (raíz de cada zona) llama reproducir_juego()
#   - transicion.gd llama detener() al empezar el fundido entre zonas
# Va por el bus "Musica", que crea ajustes.gd, para que el slider de volumen del menú funcione.
#
# NUEVO: también vigila la partida (jugador y jefe) y pone tres sonidos sin tocar sus scripts:
#   - Daño al jugador: suena cada vez que baja la vida del jugador.
#   - Golpe (hice daño): suena cada vez que baja la vida del jefe, y también cuando el jugador
#     libera un zombi o revienta una burbuja/clon (eso lo avisa jugador.gd con sonar_golpe()).
#   - Música del celular: con el celular abierto se pausa la música del juego y suena
#     una música pegajosa; al cerrarlo, la música del juego sigue donde iba.
# Los efectos van por el bus "Efectos" (su slider de volumen también funciona).

const PISTA_MENU = "res://assets/audio/musica_menu.mp3"
const PISTA_JUEGO = "res://assets/audio/musica_juego.mp3"

const SONIDO_DANO = "res://assets/audio/dano_jugador.wav"
const SONIDO_GOLPE = "res://assets/audio/golpe_jefe.wav"
const PISTA_CELULAR = "res://assets/audio/musica_celular.wav"
const PAUSA_DANO = 0.3    # segundos mínimos entre dos sonidos de daño (el daño continuo no debe sonar 60 veces por segundo)
const PAUSA_GOLPE = 0.08  # igual para el golpe al jefe

var audio_player: AudioStreamPlayer
var audio_dano: AudioStreamPlayer      # efecto: me hicieron daño
var audio_golpe: AudioStreamPlayer     # efecto: le hice daño al jefe
var audio_celular: AudioStreamPlayer   # música mientras el celular está abierto

var jug_visto = null       # jugador que se está vigilando (cambia al recargar la zona)
var vida_jug = 0.0         # vida del jugador en el cuadro anterior
var jefe_visto = null      # jefe que se está vigilando
var vida_jefe = 0.0        # vida del jefe en el cuadro anterior
var t_dano = 0.0           # tiempo que falta para poder repetir el sonido de daño
var t_golpe = 0.0
var celular_sonando = false

func _ready() -> void:
	# Se crea de inmediato para que nunca sea null
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.bus = "Musica"
	# reproductores nuevos: dos efectos y la música del celular
	audio_dano = crear_reproductor(SONIDO_DANO, "Efectos")
	audio_golpe = crear_reproductor(SONIDO_GOLPE, "Efectos")
	audio_celular = crear_reproductor(PISTA_CELULAR, "Musica")
	# la música del celular se repite sola: al terminar vuelve a empezar
	audio_celular.finished.connect(func():
		if celular_sonando:
			audio_celular.play())

# Crea un reproductor con su sonido ya cargado (si el archivo no existe, queda mudo y no falla)
func crear_reproductor(ruta: String, bus: String) -> AudioStreamPlayer:
	var r = AudioStreamPlayer.new()
	r.bus = bus
	if ResourceLoader.exists(ruta):
		r.stream = load(ruta)
	add_child(r)
	return r

# Cada cuadro mira la vida del jugador, la vida del jefe y si el celular está abierto
func _process(delta: float) -> void:
	t_dano = max(t_dano - delta, 0.0)
	t_golpe = max(t_golpe - delta, 0.0)
	vigilar_jugador()
	vigilar_jefe()

func vigilar_jugador() -> void:
	var jug = get_tree().get_first_node_in_group("jugador")
	if jug == null:
		jug_visto = null
		poner_celular(false)   # en el menú no hay jugador: nunca suena la música del celular
		return
	if jug != jug_visto:
		# jugador nuevo (empezó o se recargó la zona): se empieza a comparar desde su vida actual
		jug_visto = jug
		vida_jug = jug.vida
	if jug.vida < vida_jug - 0.01 and t_dano <= 0.0:
		audio_dano.play()      # bajó la vida: ¡te hicieron daño!
		t_dano = PAUSA_DANO
	vida_jug = jug.vida
	poner_celular(jug.cel_abierto)

func vigilar_jefe() -> void:
	var jefe = get_tree().get_first_node_in_group("jefe")
	if jefe == null:
		jefe_visto = null
		return
	if jefe != jefe_visto:
		jefe_visto = jefe
		vida_jefe = jefe.vida
	if jefe.vida < vida_jefe:
		sonar_golpe()          # bajó la vida del jefe: el golpe entró
	vida_jefe = jefe.vida

# Sonido de «hice daño». Lo llaman: vigilar_jefe() (bajó la vida del jefe), jugador.gd
# (liberó un zombi o reventó una burbuja/clon) y el jefe 2 (golpe a una bolita).
# Si se llama muchas veces seguidas, suena una sola vez (PAUSA_GOLPE).
func sonar_golpe() -> void:
	if t_golpe <= 0.0:
		audio_golpe.play()
		t_golpe = PAUSA_GOLPE

# Celular abierto: se pausa la música del juego y suena la del celular. Cerrado: al revés.
func poner_celular(abierto: bool) -> void:
	if abierto == celular_sonando:
		return   # nada cambió
	celular_sonando = abierto
	audio_player.stream_paused = abierto   # la música del juego se pausa (no se reinicia)
	if abierto:
		audio_celular.play()
	else:
		audio_celular.stop()

func reproducir_menu() -> void:
	_reproducir(PISTA_MENU)

func reproducir_juego() -> void:
	_reproducir(PISTA_JUEGO)

func detener() -> void:
	if audio_player:
		audio_player.stop()
	poner_celular(false)   # al cambiar de zona también se calla la música del celular

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
