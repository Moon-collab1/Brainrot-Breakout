extends "res://comun/jefe/jefe_base.gd"

# Jefe de la Zona 3 «El Capataz Bot» (montacargas amarillo).
# La lógica común (estados, cola de ataques, vida, fase 2) está en comun/jefe/jefe_base.gd.
# Aquí solo están sus 4 ataques:
#   Embestida       carga en línea recta; si choca con caja, estante, pilar o pared se aturde 2 s
#   Lluvia de cajas círculos rojos «!» en el piso; 1 s después cae una caja y queda de obstáculo
#   Cintas aceleradas  dos cintas que invierten el sentido y aceleran, arrastrando a todos
#   Turno doble (fase 2)  dos embestidas seguidas y suelta cajas al terminar
# Cómo se le pega: SOLO mientras está aturdido (después de chocar).

# --- Balance (todo se ajusta aquí) ---
const VIDA = 20
const FASE2_VIDA = 10
const RADIO = 70.0
const DANO_CONTACTO = 25.0       # vida por segundo dentro del cuerpo
const COOLDOWNS = {"embestida": 8.0, "lluvia": 10.0, "cintas": 14.0, "doble": 12.0}
const NOMBRES = {"embestida": "Embestida", "lluvia": "Lluvia de cajas", "cintas": "Cintas aceleradas", "doble": "Turno doble"}
# Embestida
const EMB_AVISO = 1.0
const EMB_APUNTA = 0.6           # la marca sigue al jugador este tiempo; luego se bloquea
const EMB_VEL = 650.0            # px/s
const EMB_ATURDIDO = 2.0         # segundos aturdido tras chocar
const EMB_DANO = 20.0            # vida si te embiste
const EMB_EMPUJE = 180.0
const EMB_PAUSA_DOBLE = 0.4      # entre las dos embestidas del turno doble
# Lluvia de cajas
const LLUVIA_AVISO = 0.5
const LLUVIA_TANDAS = 3
const LLUVIA_CAJAS = 3           # por tanda
const LLUVIA_CAJAS_F2 = 5
const LLUVIA_SEPARACION = 0.9
const CAJA_AVISO = 1.0           # de la marca a la caída
const CAJA_DANO = 15.0
const MAX_CAJAS = 6              # si caen más, desaparece la más vieja (cola)
const CAJA_AREA = Rect2(80, 160, 992, 440)   # donde pueden caer
# Cintas aceleradas
const CINTAS_AVISO = 1.0
const CINTAS_ACTIVA = 8.0
const CINTAS_VEL_INI = 90.0
const CINTAS_VEL_FIN = 240.0
const CINTAS_ALTO = 100.0
const CINTAS_Y = [235.0, 440.0]
const CINTAS_INVIERTE_CADA = 2.6
# Turno doble: cuántas cajas suelta al terminar
const DOBLE_CAJAS = 3

var caja_script = preload("res://zona_3/jefe/ataques/caja_carga.gd")
var cinta_script = preload("res://zona_3/jefe/ataques/cinta_carga.gd")

var emb_ang = 0.0          # dirección de la embestida (radianes)
var emb_t = 0.0
var emb_aviso = false      # se está mostrando la marca de la embestida
var embistiendo = false    # true mientras corre
var emb_choco = false
var emb_golpeo = false     # ya le pegó al jugador en esta embestida
var cajas = Lista.new()    # cola de cajas que siguen en el piso (la más vieja sale primero)

func configurar():
	vida_max = VIDA
	fase2_vida = FASE2_VIDA
	radio_cuerpo = RADIO
	dano_contacto = DANO_CONTACTO
	nombres = NOMBRES
	cooldowns = COOLDOWNS
	ataques_base = ["embestida", "lluvia", "cintas"]
	ataques_fase2 = ["doble"]    # en fase 2 entra a la cola
	arena = Rect2(90, 195, 972, 380)

func ejecutar_ataque(nombre, mi_id):
	if nombre == "embestida":
		await ataque_embestida(mi_id)
	elif nombre == "lluvia":
		await ataque_lluvia(mi_id)
	elif nombre == "cintas":
		await ataque_cintas(mi_id)
	elif nombre == "doble":
		await ataque_doble(mi_id)

# Mientras embiste el daño lo hace la embestida, no el contacto normal
func contacto_activo():
	return not embistiendo

# Se llama al aturdirse o morir: apaga la embestida y borra las cajas de la cola al morir
func al_cancelar():
	emb_aviso = false
	embistiendo = false

func al_morir():
	while not cajas.esta_vacia():
		var c = cajas.quitar_primero()
		if is_instance_valid(c):
			c.queue_free()

# ---------------- Cada frame ----------------

func actualizar(delta):
	if emb_aviso:
		emb_t += delta
		if emb_t <= EMB_APUNTA:
			emb_ang = (jug.global_position - global_position).angle()   # sigue al jugador
	if embistiendo:
		mover_embestida(delta)

# ---------------- Embestida ----------------

func mover_embestida(delta):
	var dir = Vector2.from_angle(emb_ang)
	var nueva = global_position + dir * EMB_VEL * delta
	# ¿se sale de la arena o choca con caja, estante o pilar? Entonces termina.
	if not arena.has_point(nueva) or obstaculo_en(nueva, radio_cuerpo - 10.0):
		embistiendo = false
		emb_choco = true
		return
	global_position = nueva
	# golpe al jugador: una sola vez por embestida
	if not emb_golpeo and global_position.distance_to(jug.global_position) <= radio_cuerpo + 20.0:
		emb_golpeo = true
		jug.vida -= EMB_DANO
		jug.empujar(dir * EMB_EMPUJE)

# Una embestida completa. Devuelve true si chocó (y no la cancelaron).
func embestir(mi_id):
	emb_ang = (jug.global_position - global_position).angle()
	emb_t = 0.0
	emb_aviso = true
	await avisar(mi_id, EMB_AVISO, "embestida")
	emb_aviso = false
	if mi_id != id_ataque or muerto:
		return false
	emb_choco = false
	emb_golpeo = false
	embistiendo = true
	# espera (en pasos cortos) a que termine de correr
	while embistiendo and mi_id == id_ataque and not muerto:
		await esperar(0.03)
	embistiendo = false
	return emb_choco and mi_id == id_ataque and not muerto

func ataque_embestida(mi_id):
	var choco = await embestir(mi_id)
	if choco:
		aturdir(EMB_ATURDIDO)   # aquí se le puede pegar

func ataque_doble(mi_id):
	for i in range(2):
		var choco = await embestir(mi_id)
		if not choco:
			return
		if i == 0:
			await esperar(EMB_PAUSA_DOBLE)
			if mi_id != id_ataque or muerto:
				return
	soltar_cajas(DOBLE_CAJAS, false)   # al terminar suelta cajas...
	aturdir(EMB_ATURDIDO)              # ...y queda aturdido

# ---------------- Lluvia de cajas ----------------

func ataque_lluvia(mi_id):
	await avisar(mi_id, LLUVIA_AVISO, "lluvia")
	if mi_id != id_ataque or muerto:
		return
	var cant = LLUVIA_CAJAS
	if fase == 2:
		cant = LLUVIA_CAJAS_F2
	for t in range(LLUVIA_TANDAS):
		soltar_cajas(cant, true)
		if t < LLUVIA_TANDAS - 1:
			await esperar(LLUVIA_SEPARACION)
			if mi_id != id_ataque or muerto:
				return

# Suelta "cant" cajas. Si apuntar es true, la primera cae sobre el jugador.
func soltar_cajas(cant, apuntar):
	for i in range(cant):
		var pos = Vector2(randf_range(CAJA_AREA.position.x, CAJA_AREA.end.x), randf_range(CAJA_AREA.position.y, CAJA_AREA.end.y))
		if i == 0 and apuntar:
			pos = Vector2(clamp(jug.global_position.x, CAJA_AREA.position.x, CAJA_AREA.end.x), clamp(jug.global_position.y, CAJA_AREA.position.y, CAJA_AREA.end.y))
		crear_caja(pos)

func crear_caja(pos):
	var c = caja_script.new()
	c.position = pos
	c.aviso = CAJA_AVISO
	c.dano = CAJA_DANO
	get_parent().add_child(c)
	get_parent().move_child(c, 1)   # justo encima del Mapa
	cajas.agregar_final(c)
	# si hay demasiadas, sale la más vieja (primero en entrar, primero en salir)
	if cajas.tam > MAX_CAJAS:
		var vieja = cajas.quitar_primero()
		if is_instance_valid(vieja):
			vieja.queue_free()

# ---------------- Cintas aceleradas ----------------

func ataque_cintas(mi_id):
	var lista = []
	var dir = 1
	if randf() < 0.5:
		dir = -1
	for y in CINTAS_Y:
		var c = cinta_script.new()
		c.position = Vector2(0, y)
		c.alto = CINTAS_ALTO
		c.dir = dir
		c.vel_ini = CINTAS_VEL_INI
		c.vel_fin = CINTAS_VEL_FIN
		c.duracion = CINTAS_ACTIVA
		get_parent().add_child(c)
		get_parent().move_child(c, 1)
		lista.append(c)
		dir = -dir   # la segunda cinta va al revés
	await avisar(mi_id, CINTAS_AVISO, "cintas")
	if mi_id != id_ataque or muerto:
		return   # se canceló: aturdir() ya borró las cintas (grupo "franjas")
	for c in lista:
		if is_instance_valid(c):
			c.activar()
	# durante el ataque las cintas invierten su sentido varias veces
	var restante = CINTAS_ACTIVA
	while restante > 0.0:
		await esperar(CINTAS_INVIERTE_CADA)
		if mi_id != id_ataque or muerto:
			return
		restante -= CINTAS_INVIERTE_CADA
		for c in lista:
			if is_instance_valid(c):
				c.invertir()
	for c in lista:
		if is_instance_valid(c):
			c.queue_free()

# ---------------- Dibujo placeholder ----------------
# Montacargas amarillo. Reemplazar por el PNG real del Capataz.

func _draw():
	var aturdido = estado == Estado.ATURDIDO
	var amarillo = Color(0.98, 0.78, 0.12)
	if aturdido:
		amarillo = Color(0.7, 0.7, 0.75)   # gris: «apagado»
	# marca de la embestida: rectángulo rojo en el piso desde el jefe hasta el borde
	if emb_aviso:
		var dir = Vector2.from_angle(emb_ang)
		var lado = dir.orthogonal() * (radio_cuerpo - 10.0)
		var fin = dir * 1400.0
		var alfa = 0.18
		if emb_t > EMB_APUNTA:
			alfa = 0.4   # ya bloqueó el ángulo
		draw_colored_polygon(PackedVector2Array([lado, lado + fin, -lado + fin, -lado]), Color(1, 0.15, 0.15, alfa))
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
	if aturdido:
		draw_string(ThemeDB.fallback_font, Vector2(-40, -105), "¡ATURDIDO!", HORIZONTAL_ALIGNMENT_CENTER, 80, 16, Color(1, 1, 0.4))
