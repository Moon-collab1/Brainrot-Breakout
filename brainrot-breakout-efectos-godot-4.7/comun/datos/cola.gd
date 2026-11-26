class_name Cola

# TAD Cola (fila): el primero que entra es el primero que sale (FIFO).
# Se arma con nodos enlazados: "frente" es el primero y "fin" el último.

class Nodo:
	var dato
	var sig = null

var frente = null
var fin = null
var tam = 0

func encolar(dato):
	var nuevo = Nodo.new()
	nuevo.dato = dato
	if fin == null:
		frente = nuevo
		fin = nuevo
	else:
		fin.sig = nuevo
		fin = nuevo
	tam += 1

func desencolar():
	if frente == null:
		return null
	var dato = frente.dato
	frente = frente.sig
	if frente == null:
		fin = null
	tam -= 1
	return dato

func ver_frente():
	if frente == null:
		return null
	return frente.dato

func esta_vacia():
	return tam == 0
