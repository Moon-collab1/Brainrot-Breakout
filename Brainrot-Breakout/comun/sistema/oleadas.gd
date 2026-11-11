extends Node2D

# Raíz de cada zona: lanza oleadas, invoca al jefe y pasa a la zona siguiente.
# Los @export tienen los valores de la Zona 1; cada zona los cambia en su .tscn.
const RADIO_ZOMBI = 20.0   # mismo valor que RADIO en zombi.gd
const INTENTOS_SPAWN = 10

@export var numero_zona = 1
@export var nombre_zona = "CALLE"
@export var nombre_jefe = "INFLUENCER"
@export var jefe_esc: PackedScene          # la zona lo asigna en su .tscn
@export var pos_jefe = Vector2(880, 300)   # Set A del jefe
@export var ola_inicial = 0
@export var tamanos_iniciales: Array = [5, 8, 12]
@export var paso_oleada = 4                # cuánto sube "ult" en cada oleada
@export var spawn_y_min = 130.0
# Bordes por donde salen los zombis (los valores por defecto son los de siempre).
# La Zona 4 (ascensor) los cambia porque su arena es más pequeña.
@export var spawn_x_min = 30.0
@export var spawn_x_max = 1122.0
@export var spawn_y_max = 630.0
@export var spawn_y_fondo = 618.0
@export var escena_siguiente = ""          # vacío = siguen las oleadas

var zombi_esc = preload("res://comun/zombi/zombi.tscn")
var oleadas = Lista.new()
var n_ola = 0
var pausa = 3.0
var ult = 12
var jefe_activo = false   # mientras sea true no se lanzan oleadas nuevas
var en_transicion = false # esperando para cambiar de zona

func _ready():
	MusicaGlobal.reproducir_juego()
	n_ola = ola_inicial
	for t in tamanos_iniciales:
		oleadas.agregar_final(t)
		ult = t   # al final queda el último tamaño de la lista

func _process(delta):
	if jefe_activo or en_transicion:
		return   # con jefe no hay oleadas y la pausa queda congelada
	var vivos = get_tree().get_nodes_in_group("zombis").size()
	if vivos == 0:
		pausa -= delta
		if pausa <= 0.0:
			lanzar_oleada()
			pausa = 3.0

func lanzar_oleada():
	var cant = oleadas.quitar_primero()
	ult += paso_oleada
	oleadas.agregar_final(ult)
	n_ola += 1
	# cada 5 oleadas viene el jefe en vez de zombis (se consume igual la entrada de la Lista)
	if n_ola % 5 == 0:
		print("Oleada ", n_ola, ": JEFE")
		invocar_jefe()
		return
	print("Oleada ", n_ola, " con ", cant, " zombis")
	for i in range(cant):
		crear_zombi()

# Crea un zombi en una posición segura (lo usan las oleadas y el Llamado del jefe)
func crear_zombi():
	var z = zombi_esc.instantiate()
	z.position = posicion_segura()
	add_child(z)
	return z

# Spawn seguro: dentro del mapa, a 30 px del borde y sin tocar obstáculos
func posicion_segura():
	var pos = punto_borde()
	for i in range(INTENTOS_SPAWN):
		if not choca_con_obstaculo(pos):
			return pos
		pos = punto_borde()
	return pos

func punto_borde():
	var lado = randi() % 3
	if lado == 0:
		return Vector2(spawn_x_min, randf_range(spawn_y_min, spawn_y_max))
	elif lado == 1:
		return Vector2(spawn_x_max, randf_range(spawn_y_min, spawn_y_max))
	return Vector2(randf_range(spawn_x_min, spawn_x_max), spawn_y_fondo)

# "rebotables" = rectángulos; "obstaculos" = círculos o rectángulos
func choca_con_obstaculo(pos):
	for o in get_tree().get_nodes_in_group("rebotables"):
		if choca_con_forma(o, pos):
			return true
	for o in get_tree().get_nodes_in_group("obstaculos"):
		if choca_con_forma(o, pos):
			return true
	return false

# Compara con la forma de colisión inflada por el radio del zombi
func choca_con_forma(o, pos):
	var col = o.get_node("Colision")
	var forma = col.shape
	if forma is RectangleShape2D:
		var rect = Rect2(col.global_position - forma.size / 2.0, forma.size).grow(RADIO_ZOMBI)
		return rect.has_point(pos)
	if forma is CircleShape2D:
		return col.global_position.distance_to(pos) < forma.radius + RADIO_ZOMBI
	return false

# Crea el jefe en el Set A y lo conecta al HUD
func invocar_jefe():
	if jefe_esc == null:
		push_warning("Esta zona no tiene jefe_esc asignado")
		return
	jefe_activo = true
	var jefe = jefe_esc.instantiate()
	jefe.position = pos_jefe
	# se conecta antes de add_child para no perder la primera señal de vida
	jefe.vida_cambiada.connect($HUD.actualizar_jefe)
	jefe.murio.connect(_al_morir_jefe)
	$HUD.mostrar_jefe(true)
	add_child(jefe)
	move_child(jefe, $Jugador.get_index())   # el jugador se dibuja encima del jefe

func _al_morir_jefe():
	jefe_activo = false
	$HUD.mostrar_jefe(false)
	$HUD.mostrar_banner(false)   # por si murió durante el aviso del Llamado
	# se limpian zombis, proyectiles, corazones y franjas (sin sumar a libres)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	for p in get_tree().get_nodes_in_group("proyectiles"):
		p.queue_free()
	for c in get_tree().get_nodes_in_group("corazones"):
		c.queue_free()
	for f in get_tree().get_nodes_in_group("franjas"):
		f.queue_free()
	pausa = 3.0
	if escena_siguiente != "":
		pasar_de_zona()

# Guarda los libres, ejecuta la transición visual/sonora y carga la zona siguiente (en ARCADE vuelve al menú)
func pasar_de_zona():
	en_transicion = true
	Registro.libres_inicio = $Jugador.libres
	
	# Determina a dónde se va a dirigir (siguiente zona o menú en arcade)
	var destino = Registro.MENU if Registro.modo_arcade else escena_siguiente
	
	if destino != "":
		# Llama al autoload global de transición (asegúrate de haberlo registrado como Transicion)
		if Engine.has_singleton("Transicion") or get_node_or_null("/root/Transicion"):
			Transicion.cambiar_escena(destino)
		else:
			# Respaldo por si el autoload no está cargado todavía
			await get_tree().create_timer(2.5).timeout
			get_tree().change_scene_to_file(destino)
	else:
		en_transicion = false

# Tecla de debug (borrar al final): F1 invoca al jefe
func _unhandled_input(event):
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 and get_tree().get_nodes_in_group("jefe").size() == 0:
			invocar_jefe()
