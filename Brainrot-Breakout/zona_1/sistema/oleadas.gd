extends Node2D

const RADIO_ZOMBI = 20.0   # mismo valor que RADIO en zombi.gd
const INTENTOS_SPAWN = 10
const POS_JEFE_A = Vector2(880, 300)   # Set A del jefe

var zombi_esc = preload("res://zona_1/zombi/zombi.tscn")
var jefe_esc = preload("res://zona_1/jefe/JefeInfluencer.tscn")
var oleadas = Lista.new()
var n_ola = 0
var pausa = 3.0
var ult = 12
var jefe_activo = false   # mientras sea true no se lanzan oleadas nuevas

func _ready():
	oleadas.agregar_final(5)
	oleadas.agregar_final(8)
	oleadas.agregar_final(12)

func _process(delta):
	if jefe_activo:
		return   # con jefe no hay oleadas y la pausa queda congelada
	var vivos = get_tree().get_nodes_in_group("zombis").size()
	if vivos == 0:
		pausa -= delta
		if pausa <= 0.0:
			lanzar_oleada()
			pausa = 3.0

func lanzar_oleada():
	var cant = oleadas.quitar_primero()
	ult += 4
	oleadas.agregar_final(ult)
	n_ola += 1
	# cada 5 oleadas viene el jefe en vez de zombis (se consume igual la entrada de la Lista)
	if n_ola % 5 == 0:
		print("Oleada ", n_ola, ": JEFE")
		invocar_jefe()
		return
	print("Oleada ", n_ola, " con ", cant, " zombis")
	for i in range(cant):
		var z = zombi_esc.instantiate()
		z.position = posicion_segura()
		add_child(z)

# Spawn seguro: dentro del mapa, a 30 px del borde y sin tocar autos/basureros
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
		return Vector2(30, randf_range(130, 630))
	elif lado == 1:
		return Vector2(1122, randf_range(130, 630))
	return Vector2(randf_range(30, 1122), 618)

# Compara con el rectángulo de colisión de cada "rebotable", inflado por el radio del zombi
func choca_con_obstaculo(pos):
	for o in get_tree().get_nodes_in_group("rebotables"):
		var col = o.get_node("Colision")
		var tam = col.shape.size
		var rect = Rect2(col.global_position - tam / 2.0, tam).grow(RADIO_ZOMBI)
		if rect.has_point(pos):
			return true
	return false

# Crea el jefe en el Set A y lo conecta al HUD
func invocar_jefe():
	jefe_activo = true
	var jefe = jefe_esc.instantiate()
	jefe.position = POS_JEFE_A
	# se conecta antes de add_child para no perder la primera señal de vida
	jefe.vida_cambiada.connect($HUD.actualizar_jefe)
	jefe.murio.connect(_al_morir_jefe)
	$HUD.mostrar_jefe(true)
	add_child(jefe)
	move_child(jefe, $Jugador.get_index())   # el jugador se dibuja encima del jefe

func _al_morir_jefe():
	jefe_activo = false
	$HUD.mostrar_jefe(false)
	# se limpian zombis, corazones y franjas (sin sumar a libres)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	for p in get_tree().get_nodes_in_group("proyectiles"):
		p.queue_free()
	for f in get_tree().get_nodes_in_group("franjas"):
		f.queue_free()
	pausa = 3.0

# Tecla de debug (borrar al final): F1 invoca al jefe
func _unhandled_input(event):
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 and get_tree().get_nodes_in_group("jefe").size() == 0:
			invocar_jefe()
