class_name Lista

class Nodo:
	var dato
	var sig = null

var cab = null
var tam = 0

func agregar_final(dato):
	var nuevo = Nodo.new()
	nuevo.dato = dato
	if cab == null:
		cab = nuevo
	else:
		var act = cab
		while act.sig != null:
			act = act.sig
		act.sig = nuevo
	tam += 1

func quitar_primero():
	if cab == null:
		return null
	var dato = cab.dato
	cab = cab.sig
	tam -= 1
	return dato

func obtener(pos):
	if pos < 0 or pos >= tam:
		return null
	var act = cab
	for i in range(pos):
		act = act.sig
	return act.dato

func esta_vacia():
	return cab == null
