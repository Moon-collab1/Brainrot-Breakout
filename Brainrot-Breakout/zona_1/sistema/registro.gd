class_name Registro

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
