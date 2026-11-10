extends Node2D

signal vida_cambiada(valor, maximo)
signal murio

# --- Balance (se ajusta en la Parte 7) ---
const VIDA_MAX = 56
const FASE2_VIDA = 28            # fase 2 al bajar de este valor
const ANTENAS = [8, 8, 10, 10]   # vida de las antenas sucesivas
const ANTENA_REPETIDA = 10       # si se acaban, se repite este valor
const DANO_ANTENA = 4            # vida que pierde el jefe al romper una antena
const TIEMPO_INTRO = 2.0
const TIEMPO_ATURDIDO = 5.0
const PARPADEO_FINAL = 1.0
const ALCANCE_JUGADOR = 100.0    # igual a "alcance" de jugador.gd
const RADIO_CUERPO = 70.0
const RADIO_ANTENA = 25.0
# Posiciones de la antena: 0 arriba, 1 izquierda, 2 derecha
const POS_ANTENA = [Vector2(0, -95), Vector2(-95, 0), Vector2(95, 0)]
# Cola de rotación de ataques (Parte 5)
const PAUSA_ATAQUE = 1.5         # pausa entre ataques
const PAUSA_ATAQUE_F2 = 1.0      # pausa en fase 2
const ESPERA_COOLDOWN = 0.5      # si todos los ataques están en cooldown
const COOLDOWNS = {"flash": 7.0, "lluvia": 6.0, "lluvia_grande": 12.0, "directo": 14.0, "pulso": 4.0, "llamado": 12.0}
# Pulso del aro (Parte 5)
const PULSO_DIST = 130.0     # distancia al centro que activa el pulso
const PULSO_ESPERA = 1.2     # segundos cerca del jefe para que se active
const PULSO_BRILLO = 0.8     # el aro brilla este tiempo antes de la onda
const PULSO_RADIO = 140.0
const PULSO_DANO = 5.0
const PULSO_EMPUJE = 150.0
const PULSO_ANIM = 0.3       # duración del dibujo de la onda
# Contacto: si el jugador se mete dentro del cuerpo del jefe, recibe daño por segundo
const DANO_CONTACTO = 25.0

# Flash de selfie (Parte 5)
const FLASH_AVISO = 1.0        # duración del aviso (el cono amarillo)
const FLASH_APUNTA = 0.6       # sigue al jugador este tiempo; después bloquea el ángulo
const FLASH_ALCANCE = 450.0
const FLASH_SEMIANGULO = 16.0  # grados
const FLASH_BLANCO = 1.5       # segundos de pantalla blanca si te alcanza
# Lluvia de likes (Parte 5)
const LLUVIA_AVISO = 0.6       # aviso antes de la primera tanda
const LLUVIA_TANDAS = 2
const LLUVIA_CORAZONES = 5     # corazones por tanda
const LLUVIA_SEPARACION = 0.5  # segundos entre tandas
const LLUVIA_ABANICO = 50.0    # grados de apertura del abanico
const LLUVIA_VEL = 220.0       # px/s
const DANO_LIKE = 6.0          # bajar a 5 en la Parte 7 si el jugador muere mucho
# Lluvia grande de likes (Parte 5): corazones que caen desde la pared de arriba
const GRANDE_AVISO = 1.2
const GRANDE_OLAS = 6          # tandas de corazones
const GRANDE_SEPARACION = 0.5  # segundos entre tandas
const GRANDE_COLUMNAS = 12     # el ancho del mapa se divide en columnas
const GRANDE_POR_OLA = 8       # corazones por tanda (quedan 4 columnas libres para esquivar)
const GRANDE_VEL = 240.0       # px/s hacia abajo
const GRANDE_Y = 125.0         # justo debajo de la pared de arriba (que llega hasta y=112)
const GRANDE_X0 = 30.0
const GRANDE_X1 = 1122.0
const DANO_LIKE_GRANDE = 4.0   # más bajo que DANO_LIKE porque caen muchos
# Directo en vivo (Parte 5)
const DIRECTO_AVISO = 1.0
const DIRECTO_ACTIVA = 5.0
const DIRECTO_ANCHO = 90.0
const DIRECTO_DOPA = 15.0      # dopamina por segundo mientras estés dentro
# Llamado a los seguidores (Parte 6)
const LLAMADO_AVISO = 1.2        # el banner ¡SÍGUEME! sale este tiempo antes de los zombis
const LLAMADO_SI_MENOS_DE = 6    # solo se lanza si hay menos de estos zombis vivos
const LLAMADO_CANT = 6           # zombis que llama
const LLAMADO_CANT_F2 = 8        # en fase 2
const LLAMADO_SEPARACION = 0.4   # segundos entre un zombi y el siguiente
# Cambio de set (Parte 5)
const SETS = [Vector2(880, 300), Vector2(560, 324), Vector2(250, 324)]   # A, B, C
const CAMBIO_DESVANECE = 0.5
const CAMBIO_INVISIBLE = 0.5
const CAMBIO_APARECE = 0.5
const CAMBIO_MIN = 2           # se cambia de set cada 2-3 ataques (al azar)
const CAMBIO_MAX = 3
const COLOR_NORMAL = Color(1, 1, 1)   # sin tinte: el diseño ya trae sus colores
const COLOR_ATURDIDO = Color(0.5, 0.6, 1.0)

enum Estado { INTRO, ATACANDO, CAMBIANDO, ATURDIDO }

var vida = VIDA_MAX
var fase = 1
var estado = Estado.INTRO
var antena_vida = 0
var antenas = Lista.new()
var id_ataque = 0        # sube al cancelar; las corrutinas de ataque lo comparan tras cada await
var muerto = false
var tw_aviso = null
var tw_parpadeo = null
var cola = Lista.new()   # cola de rotación: se saca el primero y se reinserta al final
var cooldown = {}        # segundos que le faltan a cada ataque para poder usarse
var t_pelea = 0.0        # duración de la pelea (para el balance)
var en_aviso = false     # true mientras otro ataque muestra su aviso (el pulso no se activa entonces)
var pulso_t = 0.0        # tiempo seguido que el jugador lleva cerca
var pulso_activo = false # true desde que empieza a brillar hasta que sale la onda
var id_pulso = 0         # sube al cancelar el pulso (aturdir)
var brillo = false
var onda_r = 0.0
var onda_a = 0.0
var cono_activo = false  # el cono del Flash se está mostrando
var cono_t = 0.0
var cono_ang = 0.0       # ángulo del cono (radianes)
var lluvia_aviso = false # se está mostrando el aviso de la Lluvia (el abanico apunta al jugador)
var lluvia_ang = 0.0     # ángulo central del abanico (radianes)
var grande_aviso = false # se está mostrando el aviso de la lluvia grande (barra arriba)

var set_actual = 0         # 0 = A, 1 = B, 2 = C (el jefe nace en A)
var ataques_hasta_cambio = 2   # ataques que faltan para el próximo cambio de set
var tw_cambio = null
var corazon_esc = preload("res://zona_1/jefe/ataques/corazon.tscn")
var franja_esc = preload("res://zona_1/jefe/ataques/franja.tscn")

@onready var antena = $Antena

func _ready():
	add_to_group("jefe")
	for v in ANTENAS:
		antenas.agregar_final(v)
	nueva_antena()
	cola.agregar_final("flash")
	cola.agregar_final("lluvia")
	cola.agregar_final("lluvia_grande")
	cola.agregar_final("llamado")
	ataques_hasta_cambio = randi_range(CAMBIO_MIN, CAMBIO_MAX)
	for nombre in COOLDOWNS:
		cooldown[nombre] = 0.0
	vida_cambiada.emit(vida, VIDA_MAX)
	# aparece con un fundido durante la intro
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.0)
	$TimerEstado.timeout.connect(_al_terminar_estado)
	cambiar_estado(Estado.INTRO)

func _process(delta):
	if muerto:
		return
	t_pelea += delta
	for nombre in cooldown:
		cooldown[nombre] = max(cooldown[nombre] - delta, 0.0)
	revisar_pulso(delta)
	dano_contacto(delta)
	actualizar_cono(delta)
	actualizar_aviso_lluvia()
	queue_redraw()

# El aro del jefe (se reemplaza por el sprite real)
func _draw():
	if brillo:
		draw_arc(Vector2.ZERO, RADIO_CUERPO, 0.0, TAU, 48, Color(1, 1, 1), 9.0)
	else:
		draw_arc(Vector2.ZERO, RADIO_CUERPO, 0.0, TAU, 48, Color(1, 0.9, 0.3), 4.0)
	if onda_a > 0.0:
		draw_arc(Vector2.ZERO, onda_r, 0.0, TAU, 64, Color(1, 1, 1, onda_a), 6.0)
	if lluvia_aviso:
		# 5 rayitas que muestran hacia dónde saldrán los corazones
		for i in range(LLUVIA_CORAZONES):
			draw_line(Vector2.from_angle(angulo_corazon(i, lluvia_ang)) * (RADIO_CUERPO + 5.0), Vector2.from_angle(angulo_corazon(i, lluvia_ang)) * (RADIO_CUERPO + 90.0), Color(1, 0.2, 0.4, 0.6), 3.0)
	if grande_aviso:
		# barra parpadeante pegada a la pared de arriba: de ahí caerán los corazones
		var alfa_b = 0.35 + 0.25 * sin(Time.get_ticks_msec() / 60.0)
		draw_rect(Rect2(to_local(Vector2(0, 112)), Vector2(1152, 14)), Color(1, 0.2, 0.4, alfa_b))
	if cono_activo:
		# más opaco cuando ya bloqueó el ángulo
		var alfa = 0.3
		if cono_t > FLASH_APUNTA:
			alfa = 0.55
		var semi = deg_to_rad(FLASH_SEMIANGULO)
		var puntos = PackedVector2Array([Vector2.ZERO])
		for i in range(13):
			var a = cono_ang - semi + (2.0 * semi) * i / 12.0
			puntos.append(Vector2.from_angle(a) * FLASH_ALCANCE)
		draw_colored_polygon(puntos, Color(1, 0.9, 0.1, alfa))

# ---------------- Estados ----------------

func cambiar_estado(nuevo):
	estado = nuevo
	$TimerEstado.stop()
	detener_parpadeo()
	$Visual.modulate = COLOR_NORMAL
	if nuevo == Estado.INTRO:
		$TimerEstado.start(TIEMPO_INTRO)
	elif nuevo == Estado.ATURDIDO:
		$Visual.modulate = COLOR_ATURDIDO
		$TimerEstado.start(TIEMPO_ATURDIDO)
		# el último segundo parpadea la antena nueva
		tw_aviso = create_tween()
		tw_aviso.tween_interval(TIEMPO_ATURDIDO - PARPADEO_FINAL)
		tw_aviso.tween_callback(parpadear_antena)
	print("Jefe: ", Estado.keys()[nuevo])

func _al_terminar_estado():
	if estado == Estado.INTRO or estado == Estado.ATURDIDO:
		cambiar_estado(Estado.ATACANDO)
		iniciar_ataques()

func aturdir():
	id_ataque += 1          # cancela el ataque en curso
	id_pulso += 1           # y el pulso, si estaba brillando
	pulso_activo = false
	pulso_t = 0.0
	brillo = false
	en_aviso = false
	cono_activo = false
	lluvia_aviso = false
	grande_aviso = false
	# si estaba cambiando de set: se corta el fundido y la antena vuelve
	if tw_cambio != null and tw_cambio.is_valid():
		tw_cambio.kill()
	modulate.a = 1.0
	mostrar_antena(true)
	limpiar_ataques()
	cambiar_estado(Estado.ATURDIDO)

func limpiar_ataques():
	# get_nodes_in_group devuelve una copia, es seguro liberar dentro del bucle
	for p in get_tree().get_nodes_in_group("proyectiles"):
		p.queue_free()
	for c in get_tree().get_nodes_in_group("corazones"):
		c.queue_free()
	for f in get_tree().get_nodes_in_group("franjas"):
		f.queue_free()
	get_parent().get_node("HUD").mostrar_banner(false)   # si estaba el aviso del Llamado
	# los zombis NO se borran

# ---------------- Cola de ataques ----------------

# Espera sin usar el árbol global: si el jefe se libera, la corrutina simplemente no continúa
func esperar(seg):
	var t = Timer.new()
	t.one_shot = true
	add_child(t)
	t.start(seg)
	await t.timeout
	t.queue_free()

func iniciar_ataques(directo = false):
	id_ataque += 1
	en_aviso = false
	cono_activo = false
	lluvia_aviso = false
	grande_aviso = false
	bucle_ataques(id_ataque, directo)

# directo = true: ataca ya (sin pausa) e ignora los cooldowns (lo usa F3)
func bucle_ataques(mi_id, directo):
	var saltar_pausa = directo
	while mi_id == id_ataque and not muerto:
		if not saltar_pausa:
			if fase == 2:
				await esperar(PAUSA_ATAQUE_F2)
			else:
				await esperar(PAUSA_ATAQUE)
			if mi_id != id_ataque or muerto:
				return
		saltar_pausa = false
		var nombre = siguiente_ataque(directo)
		directo = false
		if nombre == null:
			# todos en cooldown: espera 0,5 s y vuelve a probar sin pausa extra
			await esperar(ESPERA_COOLDOWN)
			saltar_pausa = true
			continue
		print("Cola -> ", nombre)
		await ejecutar_ataque(nombre, mi_id)
		cooldown[nombre] = COOLDOWNS[nombre]   # el cooldown cuenta desde que termina (o se cancela)
		if mi_id != id_ataque or muerto:
			return   # se canceló: no cuenta para el cambio de set
		ataques_hasta_cambio -= 1
		if ataques_hasta_cambio <= 0:
			await cambiar_set(mi_id)
			if mi_id != id_ataque or muerto:
				return
			ataques_hasta_cambio = randi_range(CAMBIO_MIN, CAMBIO_MAX)

# Saca el primero y lo reinserta al final; si está en cooldown prueba el siguiente
func siguiente_ataque(ignorar_cooldown):
	for i in range(cola.tam):
		var nombre = cola.quitar_primero()
		cola.agregar_final(nombre)
		var libre = ignorar_cooldown or cooldown[nombre] <= 0.0
		# el Llamado solo se usa si hay pocos zombis (F3 lo fuerza igual)
		if libre and nombre == "llamado" and not ignorar_cooldown and zombis_vivos() >= LLAMADO_SI_MENOS_DE:
			libre = false
		if libre:
			return nombre
	return null

func ejecutar_ataque(nombre, mi_id):
	if nombre == "flash":
		await ataque_flash(mi_id)
	elif nombre == "lluvia":
		await ataque_lluvia(mi_id)
	elif nombre == "lluvia_grande":
		await ataque_lluvia_grande(mi_id)
	elif nombre == "directo":
		await ataque_directo(mi_id)
	elif nombre == "llamado":
		await ataque_llamado(mi_id)

# Los ataques usan esto para su aviso: mientras dura, el pulso no se activa
func avisar(mi_id, seg):
	en_aviso = true
	await esperar(seg)
	if mi_id == id_ataque:   # si se canceló, aturdir/iniciar_ataques ya lo pusieron en false
		en_aviso = false

# ---------------- Flash de selfie ----------------

func ataque_flash(mi_id):
	var jug = get_parent().get_node("Jugador")
	cono_ang = (jug.global_position - global_position).angle()
	cono_t = 0.0
	cono_activo = true
	await avisar(mi_id, FLASH_AVISO)
	if mi_id != id_ataque or muerto:
		return   # se canceló: aturdir() ya apagó el cono
	cono_activo = false
	if jugador_en_cono(jug):
		print("Flash: te alcanzó")
		get_parent().get_node("HUD").flash_blanco(FLASH_BLANCO)
	else:
		print("Flash: fallo")

# El cono sigue al jugador hasta FLASH_APUNTA y luego queda bloqueado
func actualizar_cono(delta):
	if not cono_activo:
		return
	cono_t += delta
	if cono_t <= FLASH_APUNTA:
		var jug = get_parent().get_node("Jugador")
		cono_ang = (jug.global_position - global_position).angle()

func jugador_en_cono(jug):
	var d = jug.global_position - global_position
	if d.length() > FLASH_ALCANCE:
		return false
	return abs(angle_difference(cono_ang, d.angle())) <= deg_to_rad(FLASH_SEMIANGULO)

# ---------------- Llamado a los seguidores ----------------
# Banner 1,2 s y luego llegan los zombis de a uno. Si se cancela (aturdir) los que ya salieron se quedan.

func zombis_vivos():
	return get_tree().get_nodes_in_group("zombis").size()

func ataque_llamado(mi_id):
	var hud = get_parent().get_node("HUD")
	var cant = LLAMADO_CANT
	if fase == 2:
		cant = LLAMADO_CANT_F2
	hud.mostrar_banner(true)
	await avisar(mi_id, LLAMADO_AVISO)
	if mi_id != id_ataque or muerto:
		return   # se canceló: limpiar_ataques() ya escondió el banner
	hud.mostrar_banner(false)
	for i in range(cant):
		get_parent().crear_zombi()   # usa el spawn seguro de oleadas.gd
		if i < cant - 1:
			await esperar(LLAMADO_SEPARACION)
			if mi_id != id_ataque or muerto:
				return
	print("Llamado: ", cant, " zombis")

# ---------------- Contacto ----------------

func dano_contacto(delta):
	if estado == Estado.INTRO or estado == Estado.CAMBIANDO:
		return
	var jug = get_parent().get_node("Jugador")
	if jug.global_position.distance_to(global_position) <= RADIO_CUERPO:
		jug.vida -= DANO_CONTACTO * delta

# ---------------- Cambio de set ----------------
# Fuera de la cola: lo dispara el contador ataques_hasta_cambio. Intangible mientras dura.

func cambiar_set(mi_id):
	cambiar_estado(Estado.CAMBIANDO)
	mostrar_antena(false)
	tw_cambio = create_tween()
	tw_cambio.tween_property(self, "modulate:a", 0.0, CAMBIO_DESVANECE)
	await esperar(CAMBIO_DESVANECE)
	if mi_id != id_ataque or muerto:
		return   # aturdir() ya restauró todo
	# ahora es invisible: se mueve a otro set distinto del actual
	var nuevo = (set_actual + 1 + randi() % (SETS.size() - 1)) % SETS.size()
	set_actual = nuevo
	position = SETS[nuevo]
	print("Cambio de set -> ", ["A", "B", "C"][nuevo])
	await esperar(CAMBIO_INVISIBLE)
	if mi_id != id_ataque or muerto:
		return
	tw_cambio = create_tween()
	tw_cambio.tween_property(self, "modulate:a", 1.0, CAMBIO_APARECE)
	await esperar(CAMBIO_APARECE)
	if mi_id != id_ataque or muerto:
		return
	mostrar_antena(true)
	cambiar_estado(Estado.ATACANDO)   # el bucle de ataques sigue solo

# ---------------- Lluvia de likes ----------------

func ataque_lluvia(mi_id):
	var jug = get_parent().get_node("Jugador")
	lluvia_ang = (jug.global_position - global_position).angle()
	lluvia_aviso = true
	await avisar(mi_id, LLUVIA_AVISO)
	lluvia_aviso = false
	if mi_id != id_ataque or muerto:
		return   # se canceló: aturdir() ya limpió todo
	for t in range(LLUVIA_TANDAS):
		disparar_tanda(jug)
		if t < LLUVIA_TANDAS - 1:
			await esperar(LLUVIA_SEPARACION)
			if mi_id != id_ataque or muerto:
				return

# ---------------- Lluvia grande de likes ----------------

func ataque_lluvia_grande(mi_id):
	grande_aviso = true
	await avisar(mi_id, GRANDE_AVISO)
	grande_aviso = false
	if mi_id != id_ataque or muerto:
		return   # se canceló: aturdir() ya borró los corazones
	for k in range(GRANDE_OLAS):
		disparar_ola_grande()
		if k < GRANDE_OLAS - 1:
			await esperar(GRANDE_SEPARACION)
			if mi_id != id_ataque or muerto:
				return

# Cada tanda llena GRANDE_POR_OLA de las columnas (al azar) y deja el resto libre
func disparar_ola_grande():
	var columnas = []
	for i in range(GRANDE_COLUMNAS):
		columnas.append(i)
	columnas.shuffle()
	var ancho_col = (GRANDE_X1 - GRANDE_X0) / GRANDE_COLUMNAS
	for k in range(GRANDE_POR_OLA):
		var c = corazon_esc.instantiate()
		c.position = Vector2(GRANDE_X0 + ancho_col * (columnas[k] + 0.5) + randf_range(-12.0, 12.0), GRANDE_Y)
		c.vel = Vector2(0, GRANDE_VEL)
		c.dano = DANO_LIKE_GRANDE
		c.max_rebotes = 0   # no rebotan: al tocar un auto o basurero se destruyen
		get_parent().add_child(c)

# Durante el aviso el abanico sigue al jugador; al disparar se calcula de nuevo
func actualizar_aviso_lluvia():
	if not lluvia_aviso:
		return
	var jug = get_parent().get_node("Jugador")
	lluvia_ang = (jug.global_position - global_position).angle()

# Ángulo del corazón número i dentro del abanico centrado en "centro"
func angulo_corazon(i, centro):
	var abanico = deg_to_rad(LLUVIA_ABANICO)
	return centro - abanico / 2.0 + abanico * i / (LLUVIA_CORAZONES - 1)

func disparar_tanda(jug):
	var centro = (jug.global_position - global_position).angle()
	for i in range(LLUVIA_CORAZONES):
		var c = corazon_esc.instantiate()
		c.position = position   # el jefe y los corazones son hijos de la misma raíz
		c.vel = Vector2.from_angle(angulo_corazon(i, centro)) * LLUVIA_VEL
		c.dano = DANO_LIKE
		get_parent().add_child(c)
	print("Lluvia: tanda de ", LLUVIA_CORAZONES, " corazones")

# ---------------- Directo en vivo (fase 2) ----------------

func ataque_directo(mi_id):
	var jug = get_parent().get_node("Jugador")
	# la franja se centra en la x del jugador al empezar el aviso y ya no se mueve
	var f = franja_esc.instantiate()
	f.position = Vector2(jug.global_position.x, 0)
	f.ancho = DIRECTO_ANCHO
	f.dopa_seg = DIRECTO_DOPA
	get_parent().add_child(f)
	get_parent().move_child(f, 1)   # justo encima del Mapa, debajo de jugador, zombis y jefe
	await avisar(mi_id, DIRECTO_AVISO)
	if mi_id != id_ataque or muerto:
		return   # se canceló: aturdir() ya borró la franja (grupo "franjas")
	f.activar()
	print("Directo: franja activa")
	await esperar(DIRECTO_ACTIVA)
	if mi_id != id_ataque or muerto:
		return
	if is_instance_valid(f):
		f.queue_free()

# ---------------- Pulso del aro ----------------
# Es reactivo: no está en la cola. Solo en ATACANDO y sin cortar el aviso de otro ataque.

func revisar_pulso(delta):
	if estado != Estado.ATACANDO or pulso_activo or cooldown["pulso"] > 0.0:
		pulso_t = 0.0
		return
	if en_aviso:
		return   # no acumula mientras otro ataque avisa, pero conserva lo ya acumulado
	var jug = get_parent().get_node("Jugador")
	if jug.global_position.distance_to(global_position) <= PULSO_DIST:
		pulso_t += delta
		if pulso_t >= PULSO_ESPERA:
			pulso_t = 0.0
			lanzar_pulso()
	else:
		pulso_t = 0.0   # si se aleja, empieza de cero

func lanzar_pulso():
	var mi_id = id_pulso
	pulso_activo = true
	brillo = true
	print("Pulso: brilla")
	await esperar(PULSO_BRILLO)
	if mi_id != id_pulso or muerto:
		return   # se aturdió: aturdir() ya limpió las banderas
	if estado != Estado.ATACANDO:
		brillo = false
		pulso_activo = false
		return
	brillo = false
	pulso_activo = false
	disparar_onda()
	cooldown["pulso"] = COOLDOWNS["pulso"]

func disparar_onda():
	var jug = get_parent().get_node("Jugador")
	var d = jug.global_position - global_position
	if d.length() <= PULSO_RADIO:
		jug.vida -= PULSO_DANO
		var dir = Vector2.RIGHT
		if d.length() > 0.1:
			dir = d.normalized()
		jug.empujar(dir * PULSO_EMPUJE)
		print("Pulso: golpea al jugador")
	# dibujo de la onda que se abre y se desvanece
	onda_r = 0.0
	onda_a = 1.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "onda_r", PULSO_RADIO, PULSO_ANIM)
	tw.tween_property(self, "onda_a", 0.0, PULSO_ANIM)

# ---------------- Antena ----------------

func nueva_antena():
	var v = antenas.quitar_primero()
	if v == null:
		v = ANTENA_REPETIDA
	antena_vida = v
	if fase == 2:
		antena.position = POS_ANTENA[randi() % 3]
	else:
		antena.position = POS_ANTENA[0]
	mostrar_antena(true)

func mostrar_antena(valor):
	antena.visible = valor
	$Antena/Forma.set_deferred("disabled", not valor)

func parpadear_antena():
	tw_parpadeo = create_tween()
	tw_parpadeo.set_loops(5)   # 5 x 0,2 s = 1 s
	tw_parpadeo.tween_property(antena, "modulate:a", 0.2, 0.1)
	tw_parpadeo.tween_property(antena, "modulate:a", 1.0, 0.1)

func detener_parpadeo():
	if tw_aviso != null and tw_aviso.is_valid():
		tw_aviso.kill()
	if tw_parpadeo != null and tw_parpadeo.is_valid():
		tw_parpadeo.kill()
	antena.modulate.a = 1.0

# ---------------- Daño ----------------

# pos = posición del jugador al dar la cachetada
func recibir_golpe(pos):
	if muerto or estado == Estado.INTRO or estado == Estado.CAMBIANDO:
		return
	var en_cuerpo = pos.distance_to(global_position) <= ALCANCE_JUGADOR + RADIO_CUERPO
	var en_antena = antena.visible and pos.distance_to(antena.global_position) <= ALCANCE_JUGADOR + RADIO_ANTENA
	if estado == Estado.ATURDIDO:
		if en_cuerpo or en_antena:
			quitar_vida(1)
	elif en_antena:
		golpear_antena()
	# si solo alcanza el cuerpo estando bloqueado: no pasa nada

func golpear_antena():
	antena_vida -= 1
	if antena_vida <= 0:
		romper_antena()

func romper_antena():
	quitar_vida(DANO_ANTENA)
	if muerto:
		return
	aturdir()
	nueva_antena()   # la antena nueva ya está, pero no cuenta hasta que termine el aturdimiento

func quitar_vida(n):
	vida = max(vida - n, 0)
	vida_cambiada.emit(vida, VIDA_MAX)
	if vida <= 0:
		morir()
	elif fase == 1 and vida < FASE2_VIDA:
		entrar_fase_2()

func entrar_fase_2():
	fase = 2
	antena.position = POS_ANTENA[randi() % 3]   # la antena actual se reubica
	cola.agregar_final("directo")   # entra "Directo en vivo" a la cola
	print("Jefe: FASE 2")

func morir():
	muerto = true
	print("Pelea terminada en ", snappedf(t_pelea, 0.1), " s")
	murio.emit()
	queue_free()

# ---------------- Teclas de debug (borrar al final) ----------------

func _unhandled_input(event):
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			aturdir()
		elif event.keycode == KEY_F3 and estado == Estado.ATACANDO:
			limpiar_ataques()
			iniciar_ataques(true)   # fuerza el siguiente ataque de la cola, sin pausa ni cooldown
		elif event.keycode == KEY_F5:
			print("Duración de la pelea: ", snappedf(t_pelea, 0.1), " s")
		elif event.keycode == KEY_F4 and fase == 1:
			quitar_vida(vida - FASE2_VIDA + 1)
		elif event.keycode == KEY_F8 and estado == Estado.ATACANDO:
			# fuerza un cambio de set ya (cancela el ataque en curso y reanuda la cola al terminar)
			limpiar_ataques()
			id_ataque += 1
			en_aviso = false
			cono_activo = false
			lluvia_aviso = false
			grande_aviso = false
			var mi_id = id_ataque
			await cambiar_set(mi_id)
			if mi_id == id_ataque and not muerto:
				iniciar_ataques()
		elif event.keycode == KEY_F9 and estado == Estado.ATACANDO:
			# fuerza el Llamado ya (cancela el ataque en curso y reanuda la cola al terminar)
			limpiar_ataques()
			id_ataque += 1
			en_aviso = false
			cono_activo = false
			lluvia_aviso = false
			grande_aviso = false
			var mi_id = id_ataque
			await ataque_llamado(mi_id)
			if mi_id == id_ataque and not muerto:
				cooldown["llamado"] = COOLDOWNS["llamado"]
				iniciar_ataques()
		elif event.keycode == KEY_F6:
			recibir_golpe(antena.global_position)   # golpe de prueba a la antena
		elif event.keycode == KEY_F7:
			recibir_golpe(global_position)          # golpe de prueba al cuerpo
