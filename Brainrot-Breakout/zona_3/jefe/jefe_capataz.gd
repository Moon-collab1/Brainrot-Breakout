extends "res://comun/jefe/jefe_base.gd"

# Jefe de la Zona 3 «El Capataz Bot» (montacargas amarillo).
# La lógica común (cola de ataques, vida, fase 2) está en comun/jefe/jefe_base.gd.
#
# IDEA DE LA PELEA: el Capataz no te persigue, HUYE de ti por la bodega (más lento que tú)
# mientras te tira cajas. Tú lo persigues esquivando y le pegas siempre que lo alcances.
#   - Se le puede pegar SIEMPRE (no hay que esperar ningún mensaje ni aturdirlo).
#   - Las cajas, estantes, pilares y paredes lo bloquean igual que a ti: si lo arrinconas,
#     tienes 1 segundo para pegarle a gusto; después ESCAPA corriendo al otro lado de la bodega.
#   - Si te pegas demasiado a su cuerpo te hace daño por contacto: pégale desde el borde.
# Sus 2 ataques:
#   Lluvia de cajas   borra las cajas viejas y marca círculos rojos «!»; 1 s después cae una caja.
#                     Si te cae encima te hace daño y se rompe; si no, queda de obstáculo.
#   Charco de aceite  manchas en el piso que te frenan (no quitan vida).
# Fase 2 (mitad de la vida): más cajas, más charcos y huye un poco más rápido.

# --- Balance (todo se ajusta aquí) ---
const VIDA = 50                  # antes 20: ahora se le pega siempre, por eso tiene más
const FASE2_VIDA = 25
const RADIO = 70.0               # tamaño del cuerpo (daño por contacto)
const RADIO_CHOQUE = 50.0        # tamaño con el que choca contra cajas y paredes
const DANO_CONTACTO = 25.0       # vida por segundo si te metes dentro de su cuerpo
const ALCANCE_GOLPE = 140.0      # distancia máxima (golpe -> centro del jefe) para que cuente
const COOLDOWNS = {"lluvia": 5.0, "aceite": 9.0}
const NOMBRES = {"lluvia": "Lluvia de cajas", "aceite": "Charco de aceite"}
# Movimiento (el jugador va a 300 px/s)
const VEL_HUIR = 150.0
const VEL_HUIR_F2 = 180.0
const DIST_TRANQUILO = 380.0     # si estás más lejos que esto, deja de huir y vuelve al centro
const CENTRO = Vector2(576, 385)
# Escape: si queda arrinconado, sale disparado hacia el sitio más lejos de ti
const ESCAPE_TRAS = 1.0          # segundos arrinconado (sin poder moverse) antes de escapar
const ESCAPE_VEL = 270.0         # más rápido que cuando huye, pero menos que tú
const ESCAPE_DURA = 1.6          # segundos que dura la carrera
# Sitios a los que puede escapar (las 4 esquinas y el centro de la bodega)
const ESCAPE_SITIOS = [Vector2(170, 260), Vector2(980, 260), Vector2(170, 520), Vector2(980, 520), Vector2(576, 385)]
# Lluvia de cajas
const LLUVIA_AVISO = 0.5
const LLUVIA_TANDAS = 2
const LLUVIA_CAJAS = 4           # por tanda
const LLUVIA_CAJAS_F2 = 5
const LLUVIA_SEPARACION = 0.9    # segundos entre tandas
const CAJA_AVISO = 1.0           # de la marca roja a la caída
const CAJA_DANO = 15.0
const CAJA_AREA = Rect2(80, 160, 992, 440)   # donde pueden caer
const CAJA_INTENTOS = 10         # veces que busca un sitio libre para cada caja
# Charco de aceite
const ACEITE_AVISO = 0.8
const ACEITE_CHARCOS = 3
const ACEITE_CHARCOS_F2 = 4
const ACEITE_RADIO = 90.0
const ACEITE_DURA = 6.0
const ACEITE_MULT = 0.5          # tu velocidad dentro del charco (la mitad)

var caja_script = preload("res://zona_3/jefe/ataques/caja_carga.gd")
var aceite_script = preload("res://zona_3/jefe/ataques/charco_aceite.gd")

var radio_choque = RADIO_CHOQUE   # lo lee caja_carga.gd para saber si le cayó encima
var cajas = Lista.new()    # cola con las cajas que tiró (se vacía antes de tirar las nuevas)
var lado = 1.0             # hacia qué lado esquiva cuando algo le tapa el paso (1 o -1)
var t_destello = 0.0       # tiempo que le queda al destello blanco de «te pegaron»
var t_quieto = 0.0         # segundos que lleva arrinconado sin poder moverse
var escape_t = 0.0         # si es mayor que 0, está escapando (segundos que faltan)
var escape_meta = Vector2.ZERO   # hacia dónde escapa

func configurar():
	vida_max = VIDA
	fase2_vida = FASE2_VIDA
	radio_cuerpo = RADIO
	dano_contacto = DANO_CONTACTO
	nombres = NOMBRES
	cooldowns = COOLDOWNS
	ataques_base = ["lluvia", "aceite"]
	ataques_fase2 = []           # en fase 2 no hay ataques nuevos: los mismos, más fuertes
	arena = Rect2(90, 195, 972, 380)

func ejecutar_ataque(nombre, mi_id):
	if nombre == "lluvia":
		await ataque_lluvia(mi_id)
	elif nombre == "aceite":
		await ataque_aceite(mi_id)

# Al morir se borran las cajas que quedaban en el piso
func al_morir():
	borrar_cajas()

# ---------------- Daño: se le puede pegar SIEMPRE ----------------
# Reemplaza la función de jefe_base.gd (que solo deja pegar con el jefe aturdido).
# pos = centro del golpe de la cachetada (lo manda jugador.gd)
func recibir_golpe(pos):
	if muerto or estado == Estado.INTRO:
		return   # durante la aparición todavía no
	if pos.distance_to(global_position) <= ALCANCE_GOLPE:
		t_destello = 0.12
		quitar_vida(dano_golpe)

# ---------------- Cada frame: huir del jugador ----------------

func actualizar(delta):
	t_destello = max(t_destello - delta, 0.0)
	if estado != Estado.ATACANDO:
		return   # en la aparición (y con la tecla de prueba F2) se queda quieto
	# --- Escape: corre hacia el sitio elegido sin importar dónde esté el jugador ---
	if escape_t > 0.0:
		escape_t -= delta
		var falta = escape_meta - global_position
		if falta.length() < 20.0 or not avanzar(falta.normalized(), ESCAPE_VEL * delta):
			escape_t = 0.0   # llegó o se trabó: vuelve a huir normal
		return
	# --- Huida normal ---
	var vel = VEL_HUIR
	if fase == 2:
		vel = VEL_HUIR_F2
	var dir = global_position - jug.global_position   # flecha que se ALEJA del jugador
	if dir.length() > DIST_TRANQUILO:
		# el jugador está lejos: vuelve despacio hacia el centro de la bodega
		t_quieto = 0.0
		dir = CENTRO - global_position
		if dir.length() < 20.0:
			return   # ya está en el centro
		vel *= 0.5
	if avanzar(dir.normalized(), vel * delta):
		t_quieto = 0.0
		return
	# No pudo moverse: está arrinconado. Si pasa mucho tiempo así, escapa.
	t_quieto += delta
	if t_quieto >= ESCAPE_TRAS:
		t_quieto = 0.0
		escape_t = ESCAPE_DURA
		escape_meta = sitio_mas_lejano()

# Intenta dar un paso en la dirección "dir". Si algo la tapa, prueba girando 45° y 90°
# a cada lado: así «resbala» por las paredes y rodea las cajas.
# Devuelve true si se movió y false si quedó arrinconado.
func avanzar(dir, distancia):
	for giro in [0.0, 45.0 * lado, 90.0 * lado, -45.0 * lado, -90.0 * lado]:
		var paso = dir.rotated(deg_to_rad(giro)) * distancia
		if puede_estar(global_position + paso):
			global_position += paso
			if giro * lado < 0.0:
				lado = -lado   # tuvo que girar al otro lado: lo recuerda para no temblar
			return true
	return false

# De los sitios de escape, elige el que queda más lejos del jugador
func sitio_mas_lejano():
	var mejor = CENTRO
	var mejor_d = 0.0
	for sitio in ESCAPE_SITIOS:
		var d = sitio.distance_to(jug.global_position)
		if d > mejor_d:
			mejor_d = d
			mejor = sitio
	return mejor

# ¿Puede el jefe pararse en "pos"? Dentro de la arena y sin tocar cajas, estantes ni pilares
func puede_estar(pos):
	return arena.has_point(pos) and not obstaculo_en(pos, RADIO_CHOQUE)

# ---------------- Lluvia de cajas ----------------

func ataque_lluvia(mi_id):
	await avisar(mi_id, LLUVIA_AVISO, "lluvia")
	if mi_id != id_ataque or muerto:
		return
	borrar_cajas()   # las cajas viejas se quitan antes de tirar las nuevas
	var cant = LLUVIA_CAJAS
	if fase == 2:
		cant = LLUVIA_CAJAS_F2
	for t in range(LLUVIA_TANDAS):
		soltar_cajas(cant)
		if t < LLUVIA_TANDAS - 1:
			await esperar(LLUVIA_SEPARACION)
			if mi_id != id_ataque or muerto:
				return
	# espera a que caiga la última tanda antes de dar el ataque por terminado
	await esperar(CAJA_AVISO)

# Saca todas las cajas de la cola y las borra del piso
func borrar_cajas():
	while not cajas.esta_vacia():
		var c = cajas.quitar_primero()
		if is_instance_valid(c):   # las que se rompieron ya no existen
			c.queue_free()

# Suelta "cant" cajas: la primera apunta al jugador, las demás caen al azar
func soltar_cajas(cant):
	for i in range(cant):
		var pos = jug.global_position
		if i > 0:
			pos = sitio_libre()
		pos.x = clamp(pos.x, CAJA_AREA.position.x, CAJA_AREA.end.x)
		pos.y = clamp(pos.y, CAJA_AREA.position.y, CAJA_AREA.end.y)
		crear_caja(pos)

# Busca un punto al azar que no esté encima de otra caja/estante/pilar ni pegado al jefe
func sitio_libre():
	var pos = Vector2.ZERO
	for i in range(CAJA_INTENTOS):
		pos = Vector2(randf_range(CAJA_AREA.position.x, CAJA_AREA.end.x), randf_range(CAJA_AREA.position.y, CAJA_AREA.end.y))
		if not obstaculo_en(pos, 45.0) and pos.distance_to(global_position) > 130.0:
			return pos
	return pos   # no encontró: usa el último (si cae sobre el jefe, la caja se rompe sola)

func crear_caja(pos):
	var c = caja_script.new()
	c.position = pos
	c.aviso = CAJA_AVISO
	c.dano = CAJA_DANO
	get_parent().add_child(c)
	get_parent().move_child(c, 1)   # justo encima del Mapa
	cajas.agregar_final(c)

# ---------------- Charco de aceite ----------------

func ataque_aceite(mi_id):
	await avisar(mi_id, ACEITE_AVISO, "aceite")
	if mi_id != id_ataque or muerto:
		return
	var cant = ACEITE_CHARCOS
	if fase == 2:
		cant = ACEITE_CHARCOS_F2
	for i in range(cant):
		# el primero sale entre el jugador y el jefe (te estorba el camino); los demás al azar
		var pos = (jug.global_position + global_position) / 2.0
		if i > 0:
			pos = Vector2(randf_range(CAJA_AREA.position.x, CAJA_AREA.end.x), randf_range(CAJA_AREA.position.y, CAJA_AREA.end.y))
		var c = aceite_script.new()
		c.position = pos
		c.radio = ACEITE_RADIO
		c.aviso = ACEITE_AVISO
		c.duracion = ACEITE_DURA
		c.mult = ACEITE_MULT
		get_parent().add_child(c)
		get_parent().move_child(c, 1)   # en el piso, debajo de cajas y personajes

# ---------------- Dibujo placeholder ----------------
# Montacargas amarillo. Reemplazar por el PNG real del Capataz.

func _draw():
	var aturdido = estado == Estado.ATURDIDO   # solo pasa con la tecla de prueba F2
	var amarillo = Color(0.98, 0.78, 0.12)
	if aturdido:
		amarillo = Color(0.7, 0.7, 0.75)   # gris: «apagado»
	if t_destello > 0.0:
		amarillo = Color(1, 1, 1)          # destello blanco: le acabas de pegar
	# horquillas (los dos fierros grises)
	draw_rect(Rect2(-95, -85, 20, 130), Color(0.55, 0.57, 0.6))
	draw_rect(Rect2(75, -85, 20, 130), Color(0.55, 0.57, 0.6))
	# cuerpo
	draw_rect(Rect2(-70, -25, 140, 80), amarillo)
	draw_rect(Rect2(-60, 5, 40, 12), Color(0.1, 0.1, 0.12))
	draw_rect(Rect2(20, 5, 40, 12), Color(0.1, 0.1, 0.12))
	# cabina y casco naranja
	draw_rect(Rect2(-35, -75, 70, 55), amarillo)
	draw_rect(Rect2(-35, -75, 70, 55), Color(0.4, 0.3, 0.05), false, 3.0)
	draw_rect(Rect2(-27, -60, 54, 16), Color(0.1, 0.1, 0.12))
	var ojo = Color(1, 0.2, 0.2)
	if aturdido:
		ojo = Color(0.4, 0.4, 0.4)
	draw_circle(Vector2(-12, -52), 6.0, ojo)
	draw_circle(Vector2(12, -52), 6.0, ojo)
	draw_colored_polygon(PackedVector2Array([Vector2(-40, -75), Vector2(-25, -92), Vector2(25, -92), Vector2(40, -75)]), Color(1, 0.55, 0.1))
	# ruedas
	draw_circle(Vector2(-42, 58), 20.0, Color(0.12, 0.12, 0.14))
	draw_circle(Vector2(42, 58), 20.0, Color(0.12, 0.12, 0.14))
	draw_circle(Vector2(-42, 58), 8.0, Color(0.5, 0.5, 0.55))
	draw_circle(Vector2(42, 58), 8.0, Color(0.5, 0.5, 0.55))
