extends Node2D

# Mapa de la Zona 3 «Zona de Carga» (un almacén). El fondo es zona_3/assets/bodega.png
# (generado con las cajas, el estante y los pilares en las posiciones de abajo). Las colisiones NO se dibujan aquí: están en MapaZona3.tscn.

# --- Colores y medidas (todo se ajusta aquí) ---
const PISO_Y = 124.0          # el piso empieza aquí; arriba está la pared del fondo
const BALDOSA = 72.0          # tamaño de cada cuadro del piso
const COLOR_PARED = Color(0.16, 0.15, 0.14)
const COLOR_PISO = Color(0.2, 0.2, 0.21)
const COLOR_LINEA = Color(0.26, 0.26, 0.28)
const COLOR_AMARILLO = Color(0.95, 0.75, 0.15)   # franjas de seguridad
const COLOR_NEGRO = Color(0.08, 0.08, 0.09)
const COLOR_CAJA = Color(0.62, 0.42, 0.22)
const COLOR_ESTANTE = Color(0.3, 0.38, 0.55)
const COLOR_PILAR = Color(0.55, 0.55, 0.58)

# Centros de los objetos (deben coincidir con los StaticBody2D de MapaZona3.tscn)
const CAJAS = [Vector2(240, 250), Vector2(240, 480), Vector2(520, 560), Vector2(900, 200), Vector2(880, 490)]
const ESTANTES = [Vector2(600, 175)]
const PILARES = [Vector2(96, 200), Vector2(1056, 200)]

const FONDO = preload("res://zona_3/assets/bodega.png")   # bodega dibujada (pallets, estante y pilares)
const CAJA = preload("res://zona_3/assets/caja.png")      # las cajas van aparte: el Capataz las puede romper
const REAPARECE = 10.0   # segundos que tarda en volver una caja rota

var rotas = {}   # nombre del nodo de la caja -> segundos que faltan para que reaparezca
const LUCES = [Vector2(235, 14), Vector2(575, 14), Vector2(915, 14)]   # balizas naranjas sobre los muelles

func _process(delta):
	queue_redraw()   # las balizas giran
	for nombre in rotas.keys():
		rotas[nombre] -= delta
		if rotas[nombre] <= 0.0 and not hay_alguien_encima(get_node(nombre)):
			rotas.erase(nombre)
			var c = get_node(nombre)
			c.get_node("Colision").set_deferred("disabled", false)
			c.add_to_group("rebotables")

# El Capataz rompe una caja del mapa al escapar: deja el pallet y vuelve a aparecer después
func romper_caja(c):
	if rotas.has(String(c.name)):
		return
	rotas[String(c.name)] = REAPARECE
	c.get_node("Colision").set_deferred("disabled", true)
	c.remove_from_group("rebotables")
	Fx.chispas(c.global_position, Color(0.75, 0.52, 0.3), 18, 240.0, 0.5, 6.0)
	Fx.texto_flotante(c.global_position + Vector2(0, -40), "¡CRASH!", Color(1, 0.8, 0.4), 22)
	Fx.sonar("crash", 0.9)
	Fx.temblor(5.0, 0.15)

# Las cajas del mapa (nodos Caja1..Caja5) que todavía están enteras
func cajas_enteras():
	var lista = []
	for c in get_children():
		if String(c.name).begins_with("Caja") and not rotas.has(String(c.name)):
			lista.append(c)
	return lista

# No reaparece una caja encima del jugador, de un zombi o del jefe
func hay_alguien_encima(c):
	for grupo in ["jugador", "zombis", "jefe"]:
		for n in get_tree().get_nodes_in_group(grupo):
			if n.global_position.distance_to(c.global_position) < 90.0:
				return true
	return false

func _draw():
	draw_texture(FONDO, Vector2.ZERO)
	for c in cajas_enteras():
		draw_texture(CAJA, c.position - Vector2(48, 48))
	# balizas que giran (como en una bodega de verdad cuando se mueve un montacargas)
	var t = Time.get_ticks_msec() / 1000.0
	for i in range(LUCES.size()):
		var c = LUCES[i]
		var ang = t * 4.0 + i * 2.1
		var brillo = 0.5 + 0.5 * sin(ang)
		draw_circle(c + Vector2(0, 30), 46.0, Color(1, 0.55, 0.1, 0.10 * brillo))
		var haz = PackedVector2Array([c, c + Vector2.from_angle(ang) * 140.0 + Vector2(0, 60), c + Vector2.from_angle(ang + 0.5) * 140.0 + Vector2(0, 60)])
		draw_colored_polygon(haz, Color(1, 0.6, 0.15, 0.10 + 0.08 * brillo))
		draw_rect(Rect2(c - Vector2(9, 6), Vector2(18, 10)), Color(0.15, 0.15, 0.18))
		draw_circle(c, 7.0, Color(1, 0.45 + 0.3 * brillo, 0.1))
		draw_circle(c + Vector2(-2, -2), 2.0, Color(1, 1, 0.8, 0.9))
