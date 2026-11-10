extends "res://comun/jefe/jefe_base.gd"

# Jefe FINAL de la Zona 6 «Núcleo-∞» (un chip gigante). No se mueve.
# La lógica común está en comun/jefe/jefe_base.gd. Aquí solo están sus ataques:
#   Rejilla láser      líneas rosas y cian que barren la arena; se telegrafían 1 s antes
#   Tormenta de datos  lluvia de ceros y unos que forma patrones tipo bullet-hell
#   Apagón del celular el celular se bloquea 6 s: no puedes curarte (pero la dopamina baja)
#   Sobrecarga (fase 2) por debajo del 40 % de vida: ×1.5 de velocidad y combina láser + datos
# Cómo se le pega: cada 3 ataques el escudo se abre (aturdido 4 s, «NÚCLEO EXPUESTO»).

# --- Balance (todo se ajusta aquí) ---
const VIDA = 25
const FASE2_VIDA = 10            # 40 % de 25
const RADIO = 75.0
const DANO_CONTACTO = 20.0
const COOLDOWNS = {"rejilla": 8.0, "tormenta": 9.0, "apagon": 15.0}
const NOMBRES = {"rejilla": "Rejilla láser", "tormenta": "Tormenta de datos", "apagon": "Apagón del celular"}
const VENTANA_CADA = 3
const VENTANA_SEG = 4.0
const MULT_SOBRECARGA = 1.5      # en fase 2 todo va ×1.5 más rápido
# Rejilla láser
const LASER_AVISO = 1.0
const LASER_CANT = 3
const LASER_CANT_F2 = 5
const LASER_VEL = 140.0
const LASER_DANO = 15.0
const LASER_COLORES = [Color(1.0, 0.25, 0.75), Color(0.2, 0.9, 1.0)]   # rosa y cian
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
# Apagón del celular
const APAGON_AVISO = 0.8
const APAGON_SEG = 6.0

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
	ataques_base = ["rejilla", "tormenta", "apagon"]
	ventana_cada = VENTANA_CADA
	ventana_seg = VENTANA_SEG

func ejecutar_ataque(nombre, mi_id):
	if nombre == "rejilla":
		await ataque_rejilla(mi_id)
	elif nombre == "tormenta":
		await ataque_tormenta(mi_id)
	elif nombre == "apagon":
		await ataque_apagon(mi_id)

# El apagón del celular solo tiene sentido si el jugador se está curando o está herido
func cumple_condicion(nombre):
	if nombre == "apagon":
		return jug.cel_abierto or jug.vida < 85.0
	return true

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
	lanzar_rejilla()
	# en fase 2 (sobrecarga) el láser viene combinado con datos
	if fase == 2:
		await esperar(0.6)
		if mi_id != id_ataque or muerto:
			return
		lanzar_columnas()

func lanzar_rejilla():
	var cant = LASER_CANT
	if fase == 2:
		cant = LASER_CANT_F2
	for i in range(cant):
		var l = laser_script.new()
		l.vertical = randf() < 0.5
		l.color = LASER_COLORES[i % LASER_COLORES.size()]
		l.vel = LASER_VEL * mult()
		l.dano = LASER_DANO
		l.aviso = 0.0   # el aviso ya pasó (avisar); desde aquí el láser está activo
		# arranca en un borde y barre hacia el otro
		if l.vertical:
			l.dir = 1.0 if randf() < 0.5 else -1.0
			l.position = Vector2(100.0 if l.dir > 0 else 1050.0, 0.0)
			l.position.x += randf_range(-40.0, 40.0)
		else:
			l.dir = 1.0 if randf() < 0.5 else -1.0
			l.position = Vector2(0.0, 150.0 if l.dir > 0 else 600.0)
			l.position.y += randf_range(-20.0, 20.0)
		get_parent().add_child(l)
		get_parent().move_child(l, 1)
	print("Rejilla: ", cant, " láseres")

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

# ---------------- Apagón del celular ----------------

func ataque_apagon(mi_id):
	await avisar(mi_id, APAGON_AVISO / mult(), "apagon")
	if mi_id != id_ataque or muerto:
		return
	jug.cel_bloqueado_t = APAGON_SEG   # jugador.gd cierra el celular y no deja abrirlo
	var hud = get_parent().get_node("HUD")
	hud.mostrar_banner(true, "¡SIN CELULAR!")
	await esperar(APAGON_SEG)
	hud.mostrar_banner(false)

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
