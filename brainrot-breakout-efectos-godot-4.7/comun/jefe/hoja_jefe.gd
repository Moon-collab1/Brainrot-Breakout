extends RefCounted

# Dibuja el cuadro animado de una hoja de sprites de jefe (assets/sprites/jefes/*.png).
# Columnas = cuadros de la animación, filas = estados (0 normal, 1 aturdido / expuesto...).
# Se llama desde el _draw() del jefe: HOJA.dibujar(self, textura, cuadros, fila, tamaño, origen)
# «origen» es dónde cae el (0,0) del jefe dentro del cuadro, así las colisiones no cambian.
static func dibujar(nodo, tex, cuadros, fila, tam, origen, color = Color(1, 1, 1), seg_por_cuadro = 0.15):
	var f = int(Time.get_ticks_msec() / 1000.0 / seg_por_cuadro) % cuadros
	nodo.draw_texture_rect_region(tex, Rect2(-origen, tam), Rect2(Vector2(f * tam.x, fila * tam.y), tam), color)
