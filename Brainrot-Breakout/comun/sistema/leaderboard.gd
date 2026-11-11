class_name Leaderboard

const RUTA = "user://leaderboard.txt"
const MAX = 10          # cuántos puestos guarda el ranking
const MAX_NOMBRE = 12   # largo máximo del nombre

class Entrada:
	var nombre = ""
	var libres = 0
	var tiempo = 0.0

var lista = Lista.new()   # la lista enlazada siempre queda ordenada del mejor al peor

func _init():
	cargar()

# a es mejor que b si liberó más; si empatan, gana el que tardó menos
func mejor_que(a, b):
	if a.libres != b.libres:
		return a.libres > b.libres
	return a.tiempo < b.tiempo

# quita lo que daña el archivo (;) y deja un nombre por defecto si viene vacío
func limpiar_nombre(texto):
	var n = texto.strip_edges().replace(";", "").replace("\n", "")
	n = n.substr(0, MAX_NOMBRE)
	if n == "":
		n = "ANONIMO"
	return n

func agregar(nombre, libres, tiempo):
	var ent = Entrada.new()
	ent.nombre = limpiar_nombre(nombre)
	ent.libres = libres
	ent.tiempo = tiempo
	# se arma una lista nueva metiendo la entrada en su lugar
	var nueva = Lista.new()
	var puesta = false
	for i in range(lista.tam):
		var e = lista.obtener(i)
		if not puesta and mejor_que(ent, e):
			nueva.agregar_final(ent)
			puesta = true
		nueva.agregar_final(e)
	if not puesta:
		nueva.agregar_final(ent)
	# solo se quedan los mejores MAX
	var top = Lista.new()
	for i in range(min(nueva.tam, MAX)):
		top.agregar_final(nueva.obtener(i))
	lista = top
	guardar()

func vaciar():
	lista = Lista.new()
	guardar()

func guardar():
	var arch = FileAccess.open(RUTA, FileAccess.WRITE)
	if arch == null:
		return
	for i in range(lista.tam):
		var e = lista.obtener(i)
		arch.store_line(e.nombre + ";" + str(e.libres) + ";" + str(e.tiempo))
	arch.close()

func cargar():
	lista = Lista.new()
	if not FileAccess.file_exists(RUTA):
		return
	var arch = FileAccess.open(RUTA, FileAccess.READ)
	if arch == null:
		return
	while not arch.eof_reached():
		var linea = arch.get_line().strip_edges()
		var partes = linea.split(";")
		# si una línea está dañada, se salta y el juego sigue
		if partes.size() != 3 or not partes[1].is_valid_int() or not partes[2].is_valid_float():
			continue
		var e = Entrada.new()
		e.nombre = partes[0]
		e.libres = int(partes[1])
		e.tiempo = float(partes[2])
		lista.agregar_final(e)
	arch.close()

# 95.5 segundos -> "01:35"
static func formato_tiempo(seg):
	return "%02d:%02d" % [floori(seg / 60.0), int(seg) % 60]
