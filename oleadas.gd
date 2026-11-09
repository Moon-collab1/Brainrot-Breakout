extends Node2D

var zombi_esc = preload("res://zombi.tscn")
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
		var lado = randi() % 2
		var x = 0
		if lado == 1:
			x = 1152
		z.position = Vector2(x, randf_range(0, 648))
		add_child(z)
