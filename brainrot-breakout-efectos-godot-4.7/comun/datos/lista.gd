class_name Lista

# Lista enlazada simple, hecha a mano (no se usa Array a propósito: es una estructura de datos
# propia del proyecto). La usan:
#   - oleadas.gd      -> cola con los tamaños de las próximas oleadas
#   - jefe_base.gd    -> cola de rotación de ataques del jefe
#   - leaderboard.gd  -> ranking ordenado del mejor al peor
#
# Cada elemento vive en un Nodo que apunta al siguiente. "cab" es el primero y "tam" cuenta
# cuántos hay. Como en una cola: se agrega por el final y se quita por el principio.

class Nodo:
	var dato        # lo que guarda este nodo (número, texto, objeto...)
	var sig = null  # el nodo que sigue (null si es el último)

var cab = null   # primer nodo (null = lista vacía)
var tam = 0      # cantidad de elementos

# Agrega "dato" al final de la lista
func agregar_final(dato):
	var nuevo = Nodo.new()
	nuevo.dato = dato
	if cab == null:
		cab = nuevo
	else:
		var act = cab
		while act.sig != null:   # recorre hasta el último nodo
			act = act.sig
		act.sig = nuevo
	tam += 1

# Saca y devuelve el primer dato (null si la lista está vacía)
func quitar_primero():
	if cab == null:
		return null
	var dato = cab.dato
	cab = cab.sig
	tam -= 1
	return dato

# Devuelve el dato de la posición "pos" (0 = primero) sin quitarlo; null si no existe
func obtener(pos):
	if pos < 0 or pos >= tam:
		return null
	var act = cab
	for i in range(pos):
		act = act.sig
	return act.dato

func esta_vacia():
	return cab == null
