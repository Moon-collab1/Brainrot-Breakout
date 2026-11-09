extends Node2D

const RADIO_ZOMBI = 20.0   # mismo valor que RADIO en zombi.gd
const INTENTOS_SPAWN = 10

var zombi_esc = preload("res://zona_1/zombi/zombi.tscn")
var oleadas = Lista.new()
var n_ola = 0
var pausa = 3.0
var ult = 12

func _ready():
	oleadas.agregar_final(5)
	oleadas.agregar_final(8)
	oleadas.agregar_final(12)

func _process(delta):
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
