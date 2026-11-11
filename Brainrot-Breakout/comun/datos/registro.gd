class_name Registro

# Estado de la partida que sobrevive a los cambios de escena, y récord personal.
#
# Las variables "static" viven mientras el juego está abierto y se pueden leer desde
# cualquier script como Registro.libres_inicio, Registro.tiempo, etc. (sin instanciar).
# El récord (mayor cantidad de zombis liberados) se guarda en disco, en user://record.txt,
# y se maneja con una instancia: jugador.gd hace "var reg = Registro.new()".

# Libres con los que se entra a la zona actual (los guarda la raíz de la zona al avanzar)
static var libres_inicio = 0

# true cuando se entró por ARCADE: al terminar la zona se vuelve al menú principal
static var modo_arcade = false

# Segundos acumulados de la partida. jugador.gd lo suma cada frame de física, el menú lo
# pone en 0 al empezar y el Leaderboard lo guarda como desempate (gana el más rápido).
static var tiempo = 0.0

# Escena del menú principal (la usan la pausa, la transición y la pantalla de victoria)
const MENU = "res://menu/menu.tscn"

var ruta = "user://record.txt"

# Devuelve el récord guardado (0 si todavía no existe el archivo)
func leer():
	if not FileAccess.file_exists(ruta):
		return 0
	var arch = FileAccess.open(ruta, FileAccess.READ)
	if arch == null:
		return 0
	var texto = arch.get_as_text()
	arch.close()
	return int(texto)

# Guarda "puntos" solo si superan el récord actual
func guardar(puntos):
	if puntos > leer():
		var arch = FileAccess.open(ruta, FileAccess.WRITE)
		if arch == null:
			return
		arch.store_string(str(puntos))
		arch.close()
