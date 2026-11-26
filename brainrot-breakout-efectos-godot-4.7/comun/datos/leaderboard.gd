class_name Leaderboard

# Ranking de los 10 mejores puntajes, guardado en user://leaderboard.txt (una línea por
# jugador con el formato "nombre;libres;tiempo;nivel"). Las líneas viejas sin nivel se leen
# con nivel 1.
#   - Se ordena por zombis liberados (más es mejor); si empatan, gana el que tardó menos.
#   - Está guardado en una Lista enlazada (lista.gd) que siempre queda ordenada.
#   - Uso: var lb = Leaderboard.new()  (carga el archivo solo)  ->  lb.agregar(nombre, libres, tiempo)
#   - Lo muestra menu.gd (pantalla LEADERBOARD) y lo escribe victoria.gd al ganar el juego.

const RUTA = "user://leaderboard.txt"
const MAX = 10          # cuántos puestos guarda el ranking
const MAX_NOMBRE = 12   # largo máximo del nombre

class Entrada:
	var nombre = ""
	var libres = 0
	var tiempo = 0.0
	var nivel = 1      # nivel (skin) con el que terminó el juego

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

func agregar(nombre, libres, tiempo, nivel = 1):
	var ent = Entrada.new()
	ent.nivel = nivel
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
		arch.store_line(e.nombre + ";" + str(e.libres) + ";" + str(e.tiempo) + ";" + str(e.nivel))
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
		if partes.size() < 3 or not partes[1].is_valid_int() or not partes[2].is_valid_float():
			continue
		var e = Entrada.new()
		e.nombre = partes[0]
		e.libres = int(partes[1])
		e.tiempo = float(partes[2])
		if partes.size() >= 4 and partes[3].is_valid_int():
			e.nivel = clampi(int(partes[3]), 1, 12)
		lista.agregar_final(e)
	arch.close()

# Mini retrato de la skin de un nivel (primer cuadro de assets/sprites/jugador_N.png)
static func retrato(nivel):
	var hoja = load("res://assets/sprites/jugador_%d.png" % clampi(nivel, 1, 12))
	var at = AtlasTexture.new()
	at.atlas = hoja
	at.region = Rect2(42, 14, 84, 96)   # cuadro 0 (168x124), recortado al personaje
	return at

const NOMBRES_NIVEL = ["Novato", "Callejero", "Desconectado", "Leyenda", "Libre total", "Entrenado", "Boxeador", "Campeón", "Blindado", "Titán", "Coloso", "Leyenda Suprema"]

# 95.5 segundos -> "01:35"
static func formato_tiempo(seg):
	return "%02d:%02d" % [floori(seg / 60.0), int(seg) % 60]
