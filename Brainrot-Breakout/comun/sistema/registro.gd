class_name Registro

# Libres con los que se entra a la zona actual (los guarda la raíz al pasar de zona)
static var libres_inicio = 0

# true cuando se entró por ARCADE: al terminar la zona se vuelve al menú principal
static var modo_arcade = false

# Segundos de juego acumulados en el modo historia (pasan de una zona a otra)
static var tiempo = 0.0

const MENU = "res://menu/menu.tscn"

var ruta = "user://record.txt"

func leer():
	if not FileAccess.file_exists(ruta):
		return 0
	var arch = FileAccess.open(ruta, FileAccess.READ)
	var texto = arch.get_as_text()
	arch.close()
	return int(texto)

func guardar(puntos):
	if puntos > leer():
		var arch = FileAccess.open(ruta, FileAccess.WRITE)
		arch.store_string(str(puntos))
		arch.close()
