extends "res://comun/jefe/jefe_base.gd"

# Jefe FINAL de la Zona 6 «Núcleo-∞» (un chip gigante). No se mueve.
# La lógica común está en comun/jefe/jefe_base.gd. Aquí solo están sus ataques:
#   Rejilla láser      láseres ROJOS que barren la arena y hacen daño, y UN láser VERDE que
#                      sale por otro lado de la pantalla. Si tocas primero el verde, todos
#                      los rojos se vuelven verdes y ya no hacen daño. Así se esquiva.
#   Tormenta de datos  lluvia de ceros y unos que forma patrones tipo bullet-hell
#   Sobrecarga (fase 2) por debajo del 40 % de vida: todo va ×1.5 más rápido y sale un rojo más
# SIN CELULAR: mientras el núcleo ataca, el celular está bloqueado (no puedes curarte).
#              Solo se puede usar cuando el núcleo está expuesto.
# Cómo se le pega: cada 2 ataques el escudo se abre (aturdido 5 s, «NÚCLEO EXPUESTO»).

# --- Balance (todo se ajusta aquí) ---
const VIDA = 25
const FASE2_VIDA = 10            # 40 % de 25
const RADIO = 75.0
const DANO_CONTACTO = 20.0
const COOLDOWNS = {"rejilla": 8.0, "tormenta": 9.0}
const NOMBRES = {"rejilla": "Rejilla láser", "tormenta": "Tormenta de datos"}
const VENTANA_CADA = 2           # antes 3: ahora solo hay 2 ataques (el apagón ya no es un ataque)
const VENTANA_SEG = 5.0          # antes 4: es el único momento para pegarle Y para usar el celular
const MULT_SOBRECARGA = 1.5      # en fase 2 todo va ×1.5 más rápido
# Rejilla láser
const LASER_AVISO = 1.0
const LASER_ROJOS = 2            # láseres rojos (cada uno sale por un lado distinto)
const LASER_ROJOS_F2 = 3         # en fase 2 salen por los 3 lados que no usa el verde
const LASER_VEL_ROJO = 140.0     # px/s de los rojos
const LASER_VEL_VERDE = 260.0    # el verde es más rápido: llega antes que los rojos
const LASER_QUIETO_VERDE = 0.6   # segundos que el verde espera en su borde
const LASER_QUIETO_ROJO = 3.2     # los rojos esperan MÁS: da tiempo de rodear los racks y correr hasta el verde
const LASER_DANO = 15.0
# Los 4 lados por donde puede entrar un láser: [es vertical, posición inicial, dirección]
const LADOS = {
	"izquierda": [true, Vector2(60, 0), 1.0],
	"derecha": [true, Vector2(1092, 0), -1.0],
	"arriba": [false, Vector2(0, 140), 1.0],
	"abajo": [false, Vector2(0, 620), -1.0],
}
# Tormenta de datos
const TORMENTA_AVISO = 0.8
const TORMENTA_OLAS = 6
const TORMENTA_OLAS_F2 = 8
const TORMENTA_SEPARACION = 0.9
const DATO_VEL = 200.0
const DATO_DANO = 5.0
const DATO_DOPA = 4.0
const COLUMNAS_X0 = 60.0         # los datos caen en columnas con un hueco por donde pasar
const COLUMNAS_PASO = 100.0
const COLUMNAS_N = 11
const ANILLO_N = 14              # en cada ola par sale un anillo de datos desde el núcleo

var laser_script = preload("res://zona_6/jefe/ataques/laser.gd")
var dato_script = preload("res://zona_6/jefe/ataques/dato.gd")
var victoria_script = preload("res://zona_6/jefe/ataques/victoria.gd")

func configurar():
	vida_max = VIDA
	fase2_vida = FASE2_VIDA
	radio_cuerpo = RADIO
	dano_contacto = DANO_CONTACTO
	nombres = NOMBRES
	cooldowns = COOLDOWNS
	ataques_base = ["rejilla", "tormenta"]
	ventana_cada = VENTANA_CADA
	ventana_seg = VENTANA_SEG

func ejecutar_ataque(nombre, mi_id):
	if nombre == "rejilla":
		await ataque_rejilla(mi_id)
	elif nombre == "tormenta":
		await ataque_tormenta(mi_id)

# Cada frame: mientras el núcleo está atacando, el celular queda bloqueado.
# jugador.gd cierra el celular y no deja abrirlo mientras cel_bloqueado_t sea mayor que 0;
# aquí se renueva en cada frame, y se deja de renovar cuando el núcleo queda expuesto.
func actualizar(_delta):
	if estado == Estado.ATACANDO:
		jug.cel_bloqueado_t = 0.2

# Sobrecarga: en fase 2 todo es ×1.5 más rápido (también las pausas entre ataques)
func mult():
	if fase == 2:
		return MULT_SOBRECARGA
	return 1.0

func pausa_actual():
	return super.pausa_actual() / mult()

# Al morir es el final del juego: pantalla de victoria
func al_morir():
	var v = victoria_script.new()
	get_parent().add_child(v)

# ---------------- Rejilla láser ----------------

func ataque_rejilla(mi_id):
	await avisar(mi_id, LASER_AVISO / mult(), "rejilla")
	if mi_id != id_ataque or muerto:
		return
	# 1) se sortean los lados: el primero es para el VERDE y los demás para los ROJOS,
	#    así el verde nunca sale por el mismo lado que un rojo
	var lados = LADOS.keys()
	lados.shuffle()
	var rojos = LASER_ROJOS
	if fase == 2:
		rojos = LASER_ROJOS_F2
	var lasers = [crear_laser(lados[0], true)]
	for i in range(rojos):
		lasers.append(crear_laser(lados[i + 1], false))
	print("Rejilla: verde por ", lados[0], " y ", rojos, " rojos")
	# 2) el ataque dura hasta que desaparece el último láser (así no se mezcla con la tormenta)
	while quedan_lasers(lasers):
		await esperar(0.2)
		if mi_id != id_ataque or muerto:
			return   # se canceló: limpiar_ataques() ya borró los láseres (grupo "franjas")

func quedan_lasers(lasers):
	for l in lasers:
		if is_instance_valid(l):
			return true
	return false

# Crea un láser que entra por "lado". es_verde = true: el que neutraliza a los rojos
func crear_laser(lado, es_verde):
	var datos = LADOS[lado]
	var l = laser_script.new()
	l.vertical = datos[0]
	l.position = datos[1]
	l.dir = datos[2]
	l.verde = es_verde
	l.dano = LASER_DANO
	if es_verde:
		l.vel = LASER_VEL_VERDE * mult()
		l.aviso = LASER_QUIETO_VERDE
	else:
		l.vel = LASER_VEL_ROJO * mult()
		l.aviso = LASER_QUIETO_ROJO   # no se acorta en fase 2: siempre hay tiempo de llegar al verde
	get_parent().add_child(l)
	get_parent().move_child(l, 1)   # en el piso, justo encima del Mapa
	return l

# ---------------- Tormenta de datos ----------------

func ataque_tormenta(mi_id):
	await avisar(mi_id, TORMENTA_AVISO / mult(), "tormenta")
	if mi_id != id_ataque or muerto:
		return
	var olas = TORMENTA_OLAS
	if fase == 2:
		olas = TORMENTA_OLAS_F2
	for o in range(olas):
		lanzar_columnas()
		if o % 2 == 1:
			lanzar_anillo()
		await esperar(TORMENTA_SEPARACION / mult())
		if mi_id != id_ataque or muerto:
			return

# Una fila de datos que cae, con un hueco de 2 columnas por donde pasar
func lanzar_columnas():
	var hueco = randi() % (COLUMNAS_N - 1)
	for i in range(COLUMNAS_N):
		if i == hueco or i == hueco + 1:
			continue
		crear_dato(Vector2(COLUMNAS_X0 + i * COLUMNAS_PASO, 100.0), Vector2(0, DATO_VEL * mult()))

# Un anillo de datos que sale desde el núcleo hacia todos lados
func lanzar_anillo():
	var desfase = randf() * TAU
	for i in range(ANILLO_N):
		var ang = desfase + TAU * i / ANILLO_N
		crear_dato(global_position + Vector2.from_angle(ang) * (RADIO + 10.0), Vector2.from_angle(ang) * DATO_VEL * 0.8 * mult())

func crear_dato(pos, velocidad):
	var d = dato_script.new()
	d.position = pos
	d.vel = velocidad
	d.dano = DATO_DANO
	d.dopa = DATO_DOPA
	if randf() < 0.5:
		d.texto = "0"
	get_parent().add_child(d)

# ---------------- Dibujo placeholder ----------------
# Chip con anillo magenta. Reemplazar por el PNG real del Núcleo.

func _draw():
	var expuesto = estado == Estado.ATURDIDO
	var t = Time.get_ticks_msec() / 1000.0
	# aura
	draw_circle(Vector2.ZERO, 105.0, Color(1, 0.2, 0.7, 0.08 + 0.04 * sin(t * 3.0)))
	# patitas del chip
	for i in range(5):
		var o = -60.0 + i * 30.0
		draw_line(Vector2(o, -82), Vector2(o, -96), Color(0.3, 0.35, 0.8), 4.0)
		draw_line(Vector2(o, 82), Vector2(o, 96), Color(0.3, 0.35, 0.8), 4.0)
		draw_line(Vector2(-82, o), Vector2(-96, o), Color(0.3, 0.35, 0.8), 4.0)
		draw_line(Vector2(82, o), Vector2(96, o), Color(0.3, 0.35, 0.8), 4.0)
	# cuerpo
	draw_rect(Rect2(-75, -75, 150, 150), Color(0.08, 0.1, 0.28))
	draw_rect(Rect2(-75, -75, 150, 150), Color(0.35, 0.4, 1.0), false, 5.0)
	draw_rect(Rect2(-60, -60, 120, 120), Color(0.03, 0.04, 0.12))
	# núcleo: anillo magenta con centro blanco (se abre cuando está expuesto)
	var anillo = Color(1, 0.2, 0.75)
	var centro = Color(1, 1, 1)
	if expuesto:
		anillo = Color(1, 0.9, 0.3)
		centro = Color(1, 0.9, 0.3)
		draw_circle(Vector2.ZERO, 44.0, Color(1, 0.9, 0.3, 0.25))
	draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 40, anillo, 8.0)
	draw_circle(Vector2.ZERO, 18.0, centro)
	draw_line(Vector2(-60, 0), Vector2(-40, 0), anillo, 3.0)
	draw_line(Vector2(40, 0), Vector2(60, 0), anillo, 3.0)
	draw_line(Vector2(0, -60), Vector2(0, -40), anillo, 3.0)
	draw_line(Vector2(0, 40), Vector2(0, 60), anillo, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(-45, 70), "∞ CORE", HORIZONTAL_ALIGNMENT_CENTER, 90, 14, Color(0.7, 0.75, 1.0))
	if expuesto:
		draw_string(ThemeDB.fallback_font, Vector2(-80, -110), "¡NÚCLEO EXPUESTO!", HORIZONTAL_ALIGNMENT_CENTER, 160, 16, Color(1, 1, 0.4))
	elif estado == Estado.ATACANDO:
		# aviso fijo mientras ataca: el celular está bloqueado
		draw_string(ThemeDB.fallback_font, Vector2(-80, -110), "SIN CELULAR", HORIZONTAL_ALIGNMENT_CENTER, 160, 16, Color(1, 0.45, 0.45))
