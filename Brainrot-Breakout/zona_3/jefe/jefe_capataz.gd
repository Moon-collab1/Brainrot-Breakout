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
const HOJA = preload("res://comun/jefe/hoja_jefe.gd")
const SPRITE = preload("res://assets/sprites/jefes/jefe_capataz.png")
const VIDA = 40                  # antes 20: ahora se le pega siempre, por eso tiene más
const FASE2_VIDA = 20
const RADIO = 70.0               # tamaño del cuerpo (daño por contacto)
const RADIO_CHOQUE = 50.0        # tamaño con el que choca contra cajas y paredes
const DANO_CONTACTO = 25.0       # vida por segundo si te metes dentro de su cuerpo
const ALCANCE_GOLPE = 140.0      # distancia máxima (golpe -> centro del jefe) para que cuente
const COOLDOWNS = {"lluvia": 5.0, "aceite": 9.0, "embestida": 3.0}
const NOMBRES = {"lluvia": "Lluvia de cajas", "aceite": "Charco de aceite", "embestida": "¡Embestida!"}
# Movimiento (el jugador va a 300 px/s)
const VEL_HUIR = 175.0
const VEL_HUIR_F2 = 205.0
const DIST_TRANQUILO = 380.0     # si estás más lejos que esto, deja de huir y vuelve al centro
const CENTRO = Vector2(576, 385)
# Escape: si queda arrinconado, sale disparado hacia el sitio más lejos de ti
const ESCAPE_TRAS = 0.25         # segundos arrinconado (sin poder moverse) antes de escapar
const ESCAPE_VEL = 330.0         # MÁS rápido que tú: no lo puedes seguir pegando mientras escapa
const ESCAPE_DURA = 1.3          # segundos que dura la carrera
const GOLPES_ANTES_DE_HUIR = 4   # tras 3 cachetadas seguidas se blinda y escapa
# Detector de «trabado»: si en este tiempo se movió menos que esto (y estás cerca), escapa
const TRABADO_CADA = 0.6
const TRABADO_MIN = 35.0
# Embestida: apunta hacia ti (línea roja) y arranca en línea recta muy rápido
const EMBESTIDA_AVISO = 0.75
const EMBESTIDA_VEL = 560.0
const EMBESTIDA_DURA = 0.9
const EMBESTIDA_DANO = 22.0      # daño de un solo golpe si te atropella
# Sitios a los que puede escapar (las 4 esquinas y el centro de la bodega)
# Ruta que recorre cuando estás lejos (para que siempre esté en movimiento)
const PATRULLA = [Vector2(300, 330), Vector2(576, 470), Vector2(860, 330), Vector2(576, 260)]
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
var patrulla_i = 0
var intentos_escape = 0   # cuántos sitios de escape probó (si uno está tapado, va al siguiente)
var golpes_seguidos = 0    # cachetadas desde el último escape
var trabado_t = 0.0
var trabado_pos = Vector2.ZERO
var emb_aviso = false      # mostrando la línea roja de la embestida
var emb_dir = Vector2.RIGHT
var emb_t = 0.0            # > 0 mientras embiste
var emb_pego = false       # ya te atropelló en esta embestida

func configurar():
	vida_max = VIDA
	fase2_vida = FASE2_VIDA
	radio_cuerpo = RADIO
	dano_contacto = DANO_CONTACTO
	nombres = NOMBRES
	cooldowns = COOLDOWNS
	ataques_base = ["embestida", "lluvia", "embestida", "aceite"]   # embiste cada cierto tiempo (cada 2 ataques)
	ataques_fase2 = []           # en fase 2 no hay ataques nuevos: los mismos, más fuertes
	arena = Rect2(90, 195, 972, 380)

func ejecutar_ataque(nombre, mi_id):
	if nombre == "lluvia":
		await ataque_lluvia(mi_id)
	elif nombre == "aceite":
		await ataque_aceite(mi_id)
	elif nombre == "embestida":
		await ataque_embestida(mi_id)

# Al morir se borran las cajas que quedaban en el piso
func al_morir():
	borrar_cajas()

# ---------------- Daño: se le puede pegar SIEMPRE ----------------
# Reemplaza la función de jefe_base.gd (que solo deja pegar con el jefe aturdido).
# pos = centro del golpe de la cachetada (lo manda jugador.gd)
func recibir_golpe(pos):
	if muerto or estado == Estado.INTRO:
		return   # durante la aparición todavía no
	if escape_t > 0.0:
		# mientras escapa va blindado: la cachetada rebota
		Fx.chispas(global_position + Vector2(0, -20), Color(0.8, 0.85, 0.9), 6, 160.0, 0.3, 3.0)
		return
	if pos.distance_to(global_position) <= ALCANCE_GOLPE:
		t_destello = 0.12
		quitar_vida(dano_golpe)
		golpes_seguidos += 1
		if golpes_seguidos >= GOLPES_ANTES_DE_HUIR and not muerto:
			empezar_escape()

# Sale disparado (más rápido que tú) hacia el sitio más lejano, blindado
func empezar_escape():
	golpes_seguidos = 0
	t_quieto = 0.0
	escape_t = ESCAPE_DURA
	intentos_escape = 0
	escape_meta = sitio_mas_lejano()
	Fx.texto_flotante(global_position + Vector2(0, -120), "¡BLINDADO!", Color(0.85, 0.9, 1.0), 20)
	Fx.polvo(global_position + Vector2(0, 60))

# ---------------- Cada frame: huir del jugador ----------------

func actualizar(delta):
	t_destello = max(t_destello - delta, 0.0)
	if estado != Estado.ATACANDO:
		return   # en la aparición (y con la tecla de prueba F2) se queda quieto
	# --- Embestida en curso: línea recta muy rápido, para al chocar ---
	if emb_t > 0.0:
		emb_t -= delta
		var paso = emb_dir * EMBESTIDA_VEL * delta
		if puede_estar(global_position + paso):
			global_position += paso
		elif romper_cajas_cerca(true) and arena.has_point(global_position + paso):
			global_position += paso   # atraviesa la caja rompiéndola y sigue por la flecha
		else:
			emb_t = 0.0
			Fx.temblor(8.0, 0.25)
			Fx.chispas(global_position + emb_dir * 60.0, Color(1, 0.8, 0.3), 16, 240.0, 0.4, 5.0)
		if not emb_pego and jug.global_position.distance_to(global_position) < RADIO + 20.0:
			emb_pego = true
			jug.vida -= EMBESTIDA_DANO
			if jug.has_method("empujar"):
				jug.empujar(emb_dir * 90.0)
		return
	if emb_aviso:
		# apuntando: retrocede despacio acelerando el motor (nunca se queda quieto)
		avanzar(-emb_dir, 70.0 * delta)
		return
	# --- Detector de trabado: si casi no avanzó y estás cerca, escapa ---
	trabado_t += delta
	if trabado_t >= TRABADO_CADA:
		if escape_t <= 0.0 and global_position.distance_to(trabado_pos) < TRABADO_MIN and jug.global_position.distance_to(global_position) < 260.0:
			empezar_escape()
		trabado_t = 0.0
		trabado_pos = global_position
	# --- Escape: corre hacia el sitio elegido sin importar dónde esté el jugador ---
	if escape_t > 0.0:
		romper_cajas_cerca()   # al escapar se lleva por delante las cajas de la lluvia
		escape_t -= delta
		var falta = escape_meta - global_position
		if falta.length() < 20.0:
			escape_t = 0.0   # llegó: vuelve a huir normal
		elif not avanzar(falta.normalized(), ESCAPE_VEL * delta):
			# algo le tapa el camino: es un robot gigante, pasa por encima rompiendo lo que haya
			romper_cajas_cerca(true)
			var paso = falta.normalized() * ESCAPE_VEL * delta
			var nueva = global_position + paso
			nueva.x = clamp(nueva.x, arena.position.x, arena.end.x)
			nueva.y = clamp(nueva.y, arena.position.y, arena.end.y)
			global_position = nueva
		return
	# --- Huida normal ---
	var vel = VEL_HUIR
	if fase == 2:
		vel = VEL_HUIR_F2
	var dir = global_position - jug.global_position   # flecha que se ALEJA del jugador
	if dir.length() > DIST_TRANQUILO:
		# el jugador está lejos: patrulla la bodega de un punto a otro (nunca se queda quieto)
		t_quieto = 0.0
		dir = PATRULLA[patrulla_i] - global_position
		if dir.length() < 30.0:
			patrulla_i = (patrulla_i + 1) % PATRULLA.size()
			dir = PATRULLA[patrulla_i] - global_position
		vel *= 0.6
	if avanzar(dir.normalized(), vel * delta):
		t_quieto = 0.0
		return
	# No pudo moverse: primero intenta romper las cajas de la lluvia que lo tapan
	if romper_cajas_cerca():
		return
	# Sigue sin poder moverse: está arrinconado. Si pasa mucho tiempo así, escapa.
	t_quieto += delta
	if t_quieto >= ESCAPE_TRAS:
		empezar_escape()

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

# Rompe las cajas pegadas a su cuerpo: las de la lluvia y también las del mapa (vuelven a
# aparecer después). Devuelve true si rompió alguna.
func romper_cajas_cerca(solo_cerca = false):
	var alcance = RADIO_CHOQUE + (50.0 if solo_cerca else 62.0)
	var rompio = false
	for c in get_tree().get_nodes_in_group("rebotables"):
		if c.has_method("romper") and c.global_position.distance_to(global_position) < alcance:
			c.romper()
			rompio = true
	var mapa = get_parent().get_node_or_null("Mapa")
	if mapa != null and mapa.has_method("cajas_enteras"):
		for c in mapa.cajas_enteras():
			if c.global_position.distance_to(global_position) < alcance:
				mapa.romper_caja(c)
				rompio = true
	return rompio

# De los sitios de escape, elige el más lejano del jugador (n = 1 el segundo más lejano, etc.)
func sitio_mas_lejano(n = 0):
	var orden = ESCAPE_SITIOS.duplicate()
	orden.sort_custom(func(x, y): return x.distance_to(jug.global_position) > y.distance_to(jug.global_position))
	return orden[min(n, orden.size() - 1)]

# ¿Puede el jefe pararse en "pos"? Dentro de la arena y sin tocar cajas, estantes ni pilares
func puede_estar(pos):
	return arena.has_point(pos) and not obstaculo_en(pos, RADIO_CHOQUE)

# ---------------- Embestida ----------------

func ataque_embestida(mi_id):
	emb_dir = (jug.global_position - global_position).normalized()
	emb_aviso = true
	Fx.sonar("alarma")
	await avisar(mi_id, EMBESTIDA_AVISO, "embestida")
	emb_aviso = false
	if mi_id != id_ataque or muerto:
		return
	emb_pego = false   # sale EXACTAMENTE por donde marcó la flecha (no se reajusta)
	emb_t = EMBESTIDA_DURA
	Fx.temblor(4.0, 0.15)
	await esperar(EMBESTIDA_DURA)

func al_cancelar():
	emb_aviso = false
	emb_t = 0.0

# Solo hace daño por contacto cuando EMBISTE (y ese golpe ya se cobra una sola vez).
# Mientras huye o escapa no te hace daño aunque te pase cerca o por encima.
func contacto_activo():
	return false

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
# Montacargas amarillo (sprite assets/sprites/jefes/jefe_capataz.png).

func _draw():
	var aturdido = estado == Estado.ATURDIDO   # solo pasa con la tecla de prueba F2
	# montacargas: sprite animado (ruedas girando, luz y humo). Fila 1 = apagado (gris)
	var mod = Color(1, 1, 1)
	if t_destello > 0.0:
		mod = Color(2.5, 2.5, 2.5)   # destello blanco: le acabas de pegar
	if escape_t > 0.0:
		mod = Color(0.75, 0.85, 1.0)   # blindado (azulado) mientras escapa
	if emb_aviso:
		# línea roja: por ahí va a embestir
		var alfa = 0.35 + 0.3 * sin(Time.get_ticks_msec() / 50.0)
		var fin = emb_dir * EMBESTIDA_VEL * EMBESTIDA_DURA
		draw_line(Vector2.ZERO, fin, Color(1, 0.15, 0.1, alfa), 26.0)
		var lado = emb_dir.orthogonal() * 34.0
		draw_colored_polygon(PackedVector2Array([fin + emb_dir * 40.0, fin + lado, fin - lado]), Color(1, 0.15, 0.1, alfa + 0.2))   # punta de flecha
	HOJA.dibujar(self, SPRITE, 4, 1 if aturdido else 0, Vector2(250, 225), Vector2(125, 110), mod, 0.1)
