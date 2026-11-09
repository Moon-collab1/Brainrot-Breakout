extends Node2D

# Jefe de la Zona 2 «El Algoritmo» (Partes 2 y 4: base + cola de ataques).
# Referencia de patrones: zona_1/jefe/jefe_influencer.gd (no depende de él).

signal vida_cambiada(valor, maximo)
signal murio

# --- Balance (todo se ajusta aquí) ---
const VIDA_MAX = 60
const FASE2_VIDA = 30            # fase 2 al bajar de este valor
const RADIO_CUERPO = 100.0
const DANO_CONTACTO = 25.0       # vida por segundo dentro del cuerpo
const ALCANCE_JUGADOR = 100.0    # igual a "alcance" de jugador.gd
const TIEMPO_INTRO = 2.0
const TIEMPO_ATURDIDO = 5.0
const PARPADEO_FINAL = 1.0       # el último segundo parpadean las insignias nuevas
# Insignias de notificación (su vida = golpes que le faltan)
const RADIO_ORBITA = 140.0
const RADIO_INSIGNIA = 22.0
const VEL_ORBITA = 40.0          # grados por segundo
const MULT_ORBITA_F2 = 1.6       # fase 2: giran más rápido
const DANO_INSIGNIA = 1          # vida del jefe al reventar una insignia
const DANO_ATURDIDO = 1          # vida del jefe por cachetada estando aturdido
const TANDAS = [[3, 4, 5], [3, 4, 5], [4, 5, 6]]
const TANDA_REPETIDA = [4, 5, 6] # cuando se acaban las tandas
const ALFA_ESPERA = 0.3          # alfa de las insignias nuevas mientras no cuentan
# Cola de rotación de ataques (Parte 4)
const PAUSA_ATAQUE = 1.5         # pausa entre ataques
const PAUSA_ATAQUE_F2 = 1.0      # pausa en fase 2
const ESPERA_COOLDOWN = 0.5      # si ningún ataque sirve, reintenta tras este tiempo
const COOLDOWNS = {"spam": 9.0, "scroll": 10.0, "shadowban": 9.0, "recomendado": 11.0, "suscriptores": 14.0}
const NOMBRES = {"spam": "Spam de notificaciones", "scroll": "Scroll infinito", "shadowban": "Shadowban", "recomendado": "Recomendado para ti", "suscriptores": "Suscriptores"}
const RADIO_SALIDA = 110.0       # burbujas y clon salen del borde del orbe (así no nacen dentro de un sofá)
# Spam de notificaciones
const SPAM_AVISO = 0.8
const SPAM_TANDAS = 2
const SPAM_BURBUJAS = 4          # por tanda
const SPAM_BURBUJAS_F2 = 5       # en fase 2
const SPAM_SEPARACION = 0.9      # segundos entre tandas
const SPAM_ABANICO = 60.0        # grados de apertura
const SPAM_VEL = 170.0           # px/s
const SPAM_GIRO = 1.4            # rad/s máximos hacia el jugador
const SPAM_VIDA_UTIL = 6.0       # segundos
const SPAM_DOPA = 6.0            # dopamina al tocar (sin daño de vida)
# Scroll infinito
const SCROLL_AVISO = 1.0
const SCROLL_ACTIVA = 5.0
const SCROLL_ALTO = 110.0        # alto de la franja
const SCROLL_VEL = 140.0         # px/s de arrastre
const SCROLL_Y_MIN = 180.0       # la franja se centra en la y del jugador, dentro de este rango
const SCROLL_Y_MAX = 590.0
const SCROLL_DOPA = 8.0          # dopamina por segundo mientras estés en la franja
# Shadowban
const SHADOW_AVISO = 0.8
const SHADOW_ACTIVA = 6.0
const SHADOW_RADIO = 100.0
const SHADOW_MULT = 0.6          # velocidad ×0,6 dentro (se multiplica con el celular)
const SHADOW_DOPA = 6.0          # dopamina por segundo mientras estés dentro
const SHADOW_X0 = 120.0          # fase 2: segunda zona al azar en este rectángulo
const SHADOW_X1 = 1030.0
const SHADOW_Y0 = 180.0
const SHADOW_Y1 = 580.0
# Recomendado para ti
const RECO_AVISO = 1.0
const RECO_APUNTA = 0.6          # sigue al jugador este tiempo; luego bloquea el ángulo
const RECO_VEL = 420.0           # px/s
const RECO_DANO = 10.0
const RECO_EMPUJE = 150.0
const RECO_ESCALA = 0.4          # tamaño de la copia (icon.svg ×0,4, como el zombi)
const RECO_LINEA = 1400.0        # largo de la línea del aviso
# Suscriptores (extra)
const SUSC_AVISO = 1.2           # el banner ¡SUSCRÍBETE! sale este tiempo antes de los zombis
const SUSC_SI_MENOS_DE = 5       # solo se lanza si hay menos de estos zombis vivos
const SUSC_CANT = 8              # antes 4
const SUSC_CANT_F2 = 10          # antes 5
const SUSC_SEPARACION = 0.4
# Cambio de set
const SETS = [Vector2(880, 245), Vector2(560, 245), Vector2(240, 245)]   # A, B, C
const CAMBIO_DESVANECE = 0.5
const CAMBIO_INVISIBLE = 0.5
const CAMBIO_APARECE = 0.5
const CAMBIO_MIN = 2             # se cambia de set cada 2-3 ataques (al azar)
const CAMBIO_MAX = 3
# Visual (placeholder)
const COLOR_NORMAL = Color(0.42, 0.36, 0.88)
const COLOR_ATURDIDO = Color(0.5, 0.6, 1.0)
const COLOR_OJO = Color(1, 0.25, 0.4)
const COLOR_SALMON = Color(1, 0.55, 0.5)
const RADIO_DIBUJO = 108.0       # el orbe visual es un poco más grande que el cuerpo

enum Estado { INTRO, ATACANDO, CAMBIANDO, ATURDIDO }

# Insignia: círculo rojo con los golpes que le faltan (se reemplaza por sprite real)
class Insignia extends Node2D:
	var vida = 0
	var ang = 0.0          # ángulo actual de su órbita (radianes)
	var radio = 22.0
	var etiqueta = null

	func _ready():
		etiqueta = Label.new()
		etiqueta.size = Vector2(44, 44)
		etiqueta.position = Vector2(-22, -22)
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etiqueta.add_theme_font_size_override("font_size", 18)
		add_child(etiqueta)
		poner_vida(vida)

	func poner_vida(v):
		vida = v
		if etiqueta != null:
			etiqueta.text = str(v)

	func _draw():
		draw_circle(Vector2.ZERO, radio, Color(1, 0.17, 0.3))
		draw_arc(Vector2.ZERO, radio, 0.0, TAU, 32, Color(1, 0.7, 0.75), 2.0)

var vida = VIDA_MAX
var fase = 1
var estado = Estado.INTRO
var muerto = false
var id_ataque = 0          # sube al cancelar; las corrutinas de ataque lo comparan tras cada await
var en_aviso = false       # true mientras un ataque muestra su aviso
var t_pelea = 0.0          # duración de la pelea (F5)
var vel_orbita = deg_to_rad(VEL_ORBITA)
var tandas = Lista.new()   # tandas de vida de las insignias
var insignias = []         # insignias vivas
var tw_intro = null
var cola = Lista.new()     # cola de rotación: se saca el primero y se reinserta al final
var cooldown = {}          # segundos que le faltan a cada ataque para poder usarse
var set_actual = 0         # 0 = A, 1 = B, 2 = C (el jefe nace en A)
var ataques_hasta_cambio = 2
var tw_cambio = null
var reco_aviso = false     # se está mostrando el aviso de «Recomendado para ti»
var reco_ang = 0.0         # ángulo de la línea (radianes)
var reco_t = 0.0
var burbuja_esc = preload("res://zona_2/jefe/ataques/burbuja.tscn")
var cinta_esc = preload("res://zona_2/jefe/ataques/cinta.tscn")
var sombra_esc = preload("res://zona_2/jefe/ataques/shadowban.tscn")
var clon_esc = preload("res://zona_2/jefe/ataques/clon.tscn")
var icono = preload("res://icon.svg")

@onready var jug = get_parent().get_node("Jugador")
@onready var etiqueta_nombre = $NombreAtaque

func _ready():
	add_to_group("jefe")
	for t in TANDAS:
		tandas.agregar_final(t)
	etiqueta_nombre.position = Vector2(-160, 160)
	etiqueta_nombre.size = Vector2(320, 24)
	etiqueta_nombre.visible = false
	nueva_tanda(-PI / 2.0)
	cola.agregar_final("spam")
	cola.agregar_final("scroll")
	cola.agregar_final("shadowban")
	cola.agregar_final("recomendado")
	cola.agregar_final("suscriptores")
	for nombre in COOLDOWNS:
		cooldown[nombre] = 0.0
	ataques_hasta_cambio = randi_range(CAMBIO_MIN, CAMBIO_MAX)
	vida_cambiada.emit(vida, VIDA_MAX)
	# aparece con un fundido durante la intro
	modulate.a = 0.0
	tw_intro = create_tween()
	tw_intro.tween_property(self, "modulate:a", 1.0, 1.0)
	$TimerEstado.timeout.connect(_al_terminar_estado)
	cambiar_estado(Estado.INTRO)

func _process(delta):
	if muerto:
		return
	t_pelea += delta
	for nombre in cooldown:
		cooldown[nombre] = max(cooldown[nombre] - delta, 0.0)
	actualizar_reco(delta)
	orbitar(delta)
	dano_contacto(delta)
	queue_redraw()

# ---------------- Dibujo placeholder ----------------

func _draw():
	var aturdido = estado == Estado.ATURDIDO
	var tono = COLOR_NORMAL
	if aturdido:
		tono = COLOR_ATURDIDO
	var t = Time.get_ticks_msec() / 1000.0
	# 3 tentáculos curvos debajo (llegan a y = +150)
	for i in range(3):
		var x0 = -55.0 + 55.0 * i
		var pts = PackedVector2Array()
		for k in range(11):
			var f = k / 10.0
			pts.append(Vector2(x0 + sin(t * 2.5 + i * 2.0 + f * 4.0) * 14.0 * f, 60.0 + f * 90.0))
		draw_polyline(pts, tono.darkened(0.2), 12.0, true)
	# orbe con aro claro
	draw_circle(Vector2.ZERO, RADIO_DIBUJO, tono)
	draw_arc(Vector2.ZERO, RADIO_DIBUJO, 0.0, TAU, 64, tono.lightened(0.45), 5.0)
	var ojo = Vector2(0, -6)
	if aturdido:
		# ojo cerrado (párpado) y pupila de «cargando»
		draw_set_transform(ojo, 0.0, Vector2(1.0, 0.12))
		draw_circle(Vector2.ZERO, 52.0, Color(0.9, 0.9, 0.95))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_line(ojo + Vector2(-54, 0), ojo + Vector2(54, 0), Color(0.1, 0.1, 0.2), 6.0)
		draw_arc(ojo, 20.0, t * 7.0, t * 7.0 + PI * 1.5, 24, Color(1, 1, 1), 5.0)
	else:
		# ojo abierto: el iris sigue un poco al jugador
		draw_set_transform(ojo, 0.0, Vector2(1.0, 0.7))
		draw_circle(Vector2.ZERO, 54.0, Color(1, 1, 1))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var d = jug.global_position - global_position
		var iris = ojo + d.normalized() * min(d.length() / 20.0, 14.0)
		draw_circle(iris, 26.0, COLOR_OJO)
		draw_circle(iris, 11.0, Color(0.1, 0.05, 0.15))
	# aviso de «Recomendado para ti»: copia semitransparente en el borde y línea hacia el jugador
	if reco_aviso:
		var dir = Vector2.from_angle(reco_ang)
		var salida = dir * RADIO_SALIDA
		var alfa_linea = 0.35
		if reco_t > RECO_APUNTA:
			alfa_linea = 0.85   # ya bloqueó el ángulo
		draw_line(salida, salida + dir * RECO_LINEA, Color(1, 0.15, 0.2, alfa_linea), 4.0)
		var lado = 128.0 * RECO_ESCALA   # icon.svg mide 128 px
		draw_texture_rect(icono, Rect2(salida - Vector2(lado, lado) / 2.0, Vector2(lado, lado)), false, Color(1, 0.5, 0.5, 0.5))

# ---------------- Estados ----------------

func cambiar_estado(nuevo):
	estado = nuevo
	$TimerEstado.stop()
	if nuevo == Estado.INTRO:
		$TimerEstado.start(TIEMPO_INTRO)
	elif nuevo == Estado.ATURDIDO:
		$TimerEstado.start(TIEMPO_ATURDIDO)
	print("Jefe: ", Estado.keys()[nuevo])

func _al_terminar_estado():
	if estado == Estado.INTRO or estado == Estado.ATURDIDO:
		cambiar_estado(Estado.ATACANDO)
		iniciar_ataques()

# «Visto»: cancela el ataque en curso y limpia el piso. Los zombis se quedan.
func aturdir():
	id_ataque += 1
	en_aviso = false
	reco_aviso = false
	ocultar_nombre()
	# si estaba cambiando de set: se corta el fundido y el jefe vuelve a verse
	if tw_cambio != null and tw_cambio.is_valid():
		tw_cambio.kill()
	modulate.a = 1.0
	mostrar_insignias(true)
	limpiar_ataques()
	if insignias.is_empty():
		nueva_tanda()   # las nuevas ya existen, pero no cuentan hasta que termine
	cambiar_estado(Estado.ATURDIDO)

func limpiar_ataques():
	# get_nodes_in_group devuelve una copia, es seguro liberar dentro del bucle
	for p in get_tree().get_nodes_in_group("proyectiles"):
		p.queue_free()
	for f in get_tree().get_nodes_in_group("franjas"):
		f.queue_free()
	get_parent().get_node("HUD").mostrar_banner(false)   # por si estaba el aviso de Suscriptores
	# los zombis NO se borran

# ---------------- Cola de ataques ----------------

# directo = true: ataca ya (sin pausa) e ignora cooldowns y condiciones (lo usa F3)
func iniciar_ataques(directo = false):
	id_ataque += 1
	en_aviso = false
	reco_aviso = false
	ocultar_nombre()
	bucle_ataques(id_ataque, directo)

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
			# ninguno sirve: espera 0,5 s y vuelve a probar sin pausa extra
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

# Saca el primero y lo reinserta al final; si está en cooldown o no cumple su condición, prueba el siguiente
func siguiente_ataque(ignorar):
	for i in range(cola.tam):
		var nombre = cola.quitar_primero()
		cola.agregar_final(nombre)
		if ignorar or (cooldown[nombre] <= 0.0 and cumple_condicion(nombre)):
			return nombre
	return null

func cumple_condicion(nombre):
	if nombre == "recomendado":
		return jug.ultimo_liberado != ""   # solo si ya liberaste algún zombi
	if nombre == "suscriptores":
		return zombis_vivos() < SUSC_SI_MENOS_DE
	return true

func zombis_vivos():
	return get_tree().get_nodes_in_group("zombis").size()

func ejecutar_ataque(nombre, mi_id):
	if nombre == "spam":
		await ataque_spam(mi_id)
	elif nombre == "scroll":
		await ataque_scroll(mi_id)
	elif nombre == "shadowban":
		await ataque_shadowban(mi_id)
	elif nombre == "recomendado":
		await ataque_recomendado(mi_id)
	elif nombre == "suscriptores":
		await ataque_suscriptores(mi_id)

# Aviso de cada ataque: muestra el nombre bajo el jefe mientras dura
func avisar(mi_id, seg, nombre):
	mostrar_nombre(NOMBRES[nombre])
	en_aviso = true
	await esperar(seg)
	if mi_id == id_ataque:   # si se canceló, aturdir/iniciar_ataques ya lo apagaron
		en_aviso = false
		ocultar_nombre()

# ---------------- Spam de notificaciones ----------------

func ataque_spam(mi_id):
	await avisar(mi_id, SPAM_AVISO, "spam")
	if mi_id != id_ataque or muerto:
		return   # se canceló: aturdir() ya borró las burbujas
	var cant = SPAM_BURBUJAS
	if fase == 2:
		cant = SPAM_BURBUJAS_F2
	for t in range(SPAM_TANDAS):
		disparar_tanda_spam(cant)
		if t < SPAM_TANDAS - 1:
			await esperar(SPAM_SEPARACION)
			if mi_id != id_ataque or muerto:
				return

# Abanico de burbujas centrado en el jugador, saliendo del borde del orbe
func disparar_tanda_spam(cant):
	var centro = (jug.global_position - global_position).angle()
	var abanico = deg_to_rad(SPAM_ABANICO)
	for i in range(cant):
		var ang = centro - abanico / 2.0 + abanico * i / (cant - 1)
		var b = burbuja_esc.instantiate()
		b.position = position + Vector2.from_angle(ang) * RADIO_SALIDA   # jefe y burbujas son hijos de la misma raíz
		b.rapidez = SPAM_VEL
		b.vel = Vector2.from_angle(ang) * SPAM_VEL
		b.giro = SPAM_GIRO
		b.vida_util = SPAM_VIDA_UTIL
		b.dopa = SPAM_DOPA
		get_parent().add_child(b)
	print("Spam: tanda de ", cant, " burbujas")

# ---------------- Scroll infinito ----------------

func ataque_scroll(mi_id):
	# la franja se centra en la y del jugador al empezar el aviso y ya no se mueve
	var c = cinta_esc.instantiate()
	c.position = Vector2(0, clamp(jug.global_position.y, SCROLL_Y_MIN, SCROLL_Y_MAX))
	c.alto = SCROLL_ALTO
	c.vel = SCROLL_VEL
	c.dopa_seg = SCROLL_DOPA
	if randf() < 0.5:
		c.dir = 1
	else:
		c.dir = -1
	get_parent().add_child(c)
	get_parent().move_child(c, 1)   # justo encima del Mapa, debajo de jugador, zombis y jefe
	await avisar(mi_id, SCROLL_AVISO, "scroll")
	if mi_id != id_ataque or muerto:
		return   # se canceló: aturdir() ya borró la franja (grupo "franjas")
	c.activar()
	print("Scroll: cinta activa hacia ", c.dir)
	await esperar(SCROLL_ACTIVA)
	if mi_id != id_ataque or muerto:
		return
	if is_instance_valid(c):
		c.queue_free()

# ---------------- Shadowban ----------------

func ataque_shadowban(mi_id):
	# la zona se centra en el jugador al empezar el aviso; en fase 2 hay otra en un punto al azar
	var zonas = []
	zonas.append(crear_sombra(jug.global_position))
	if fase == 2:
		zonas.append(crear_sombra(Vector2(randf_range(SHADOW_X0, SHADOW_X1), randf_range(SHADOW_Y0, SHADOW_Y1))))
	await avisar(mi_id, SHADOW_AVISO, "shadowban")
	if mi_id != id_ataque or muerto:
		return   # se canceló: aturdir() ya borró las zonas
	for z in zonas:
		if is_instance_valid(z):
			z.activar()
	print("Shadowban: ", zonas.size(), " zona(s) activa(s)")
	await esperar(SHADOW_ACTIVA)
	if mi_id != id_ataque or muerto:
		return
	for z in zonas:
		if is_instance_valid(z):
			z.queue_free()

func crear_sombra(pos):
	var s = sombra_esc.instantiate()
	s.position = pos
	s.radio = SHADOW_RADIO
	s.mult = SHADOW_MULT
	s.dopa_seg = SHADOW_DOPA
	get_parent().add_child(s)
	get_parent().move_child(s, 1)   # justo encima del Mapa
	return s

# ---------------- Recomendado para ti ----------------

func ataque_recomendado(mi_id):
	if jug.ultimo_liberado == "":
		print("Recomendado: forzado sin zombi liberado (solo debug)")
	reco_ang = (jug.global_position - global_position).angle()
	reco_t = 0.0
	reco_aviso = true
	await avisar(mi_id, RECO_AVISO, "recomendado")
	reco_aviso = false
	if mi_id != id_ataque or muerto:
		return
	disparar_clon()

# La línea sigue al jugador hasta RECO_APUNTA y luego queda bloqueada
func actualizar_reco(delta):
	if not reco_aviso:
		return
	reco_t += delta
	if reco_t <= RECO_APUNTA:
		reco_ang = (jug.global_position - global_position).angle()

func disparar_clon():
	# AQUÍ: cuando haya más tipos de enemigo, cargar load(jug.ultimo_liberado) y copiar su sprite.
	# Con un solo tipo (zombi) el clon es icon.svg ×0,4 teñido (ver clon.tscn).
	var c = clon_esc.instantiate()
	c.position = position + Vector2.from_angle(reco_ang) * RADIO_SALIDA
	c.vel = Vector2.from_angle(reco_ang) * RECO_VEL
	c.dano = RECO_DANO
	c.empuje = RECO_EMPUJE
	get_parent().add_child(c)
	print("Recomendado: clon lanzado")

# ---------------- Suscriptores ----------------
# Banner 1,2 s y luego llegan los zombis de a uno. Si se cancela (aturdir) los que ya salieron se quedan.

func ataque_suscriptores(mi_id):
	var hud = get_parent().get_node("HUD")
	var cant = SUSC_CANT
	if fase == 2:
		cant = SUSC_CANT_F2
	hud.mostrar_banner(true, "¡SUSCRÍBETE!")
	await avisar(mi_id, SUSC_AVISO, "suscriptores")
	if mi_id != id_ataque or muerto:
		return   # se canceló: limpiar_ataques() ya escondió el banner
	hud.mostrar_banner(false)
	for i in range(cant):
		get_parent().crear_zombi()   # usa el spawn seguro de oleadas.gd
		if i < cant - 1:
			await esperar(SUSC_SEPARACION)
			if mi_id != id_ataque or muerto:
				return
	print("Suscriptores: ", cant, " zombis")

# ---------------- Cambio de set ----------------
# Fuera de la cola: lo dispara el contador ataques_hasta_cambio. Intangible mientras dura.

func cambiar_set(mi_id):
	cambiar_estado(Estado.CAMBIANDO)
	mostrar_insignias(false)
	tw_cambio = create_tween()
	tw_cambio.tween_property(self, "modulate:a", 0.0, CAMBIO_DESVANECE)
	await esperar(CAMBIO_DESVANECE)
	if mi_id != id_ataque or muerto:
		return   # aturdir() ya restauró todo
	# ahora es invisible: se mueve a un set distinto del actual
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
	mostrar_insignias(true)
	cambiar_estado(Estado.ATACANDO)   # el bucle de ataques sigue solo

# Espera sin usar el árbol global: si el jefe se libera, la corrutina simplemente no continúa
func esperar(seg):
	var t = Timer.new()
	t.one_shot = true
	add_child(t)
	t.start(seg)
	await t.timeout
	t.queue_free()

# ---------------- Nombre del ataque ----------------

func mostrar_nombre(texto):
	etiqueta_nombre.text = texto.to_upper() + " ◂"
	etiqueta_nombre.visible = true

func ocultar_nombre():
	etiqueta_nombre.visible = false

# ---------------- Insignias ----------------

# Crea 3 insignias separadas 120° con la siguiente tanda de vidas
func nueva_tanda(ang_inicio = null):
	var t = tandas.quitar_primero()
	if t == null:
		t = TANDA_REPETIDA
	if ang_inicio == null:
		ang_inicio = randf() * TAU   # las tandas siguientes empiezan en un ángulo al azar
	for i in range(3):
		var ins = Insignia.new()
		ins.vida = t[i]
		ins.radio = RADIO_INSIGNIA
		ins.ang = ang_inicio + TAU * i / 3.0
		add_child(ins)
		insignias.append(ins)
	posicionar_insignias()

func orbitar(delta):
	for ins in insignias:
		ins.ang += vel_orbita * delta
	posicionar_insignias()
	# las nuevas insignias se ven tenues mientras no cuentan; parpadean al final del aturdimiento
	var alfa = 1.0
	if estado == Estado.ATURDIDO:
		alfa = ALFA_ESPERA
		var falta = $TimerEstado.time_left
		if falta <= PARPADEO_FINAL and fmod(falta, 0.2) < 0.1:
			alfa = 1.0
	for ins in insignias:
		ins.modulate.a = alfa

func posicionar_insignias():
	for ins in insignias:
		ins.global_position = global_position + Vector2.from_angle(ins.ang) * RADIO_ORBITA

func mostrar_insignias(valor):
	for ins in insignias:
		ins.visible = valor

func reventar_insignia(ins):
	insignias.erase(ins)
	ins.queue_free()
	quitar_vida(DANO_INSIGNIA)
	if muerto:
		return
	if insignias.is_empty():
		aturdir()   # la tercera insignia: «Visto»

# ---------------- Contacto ----------------

func dano_contacto(delta):
	if estado == Estado.INTRO or estado == Estado.CAMBIANDO:
		return
	if jug.global_position.distance_to(global_position) <= RADIO_CUERPO:
		jug.vida -= DANO_CONTACTO * delta

# ---------------- Daño ----------------

# pos = posición del jugador al dar la cachetada
func recibir_golpe(pos):
	if muerto or estado == Estado.INTRO or estado == Estado.CAMBIANDO:
		return
	if estado == Estado.ATURDIDO:
		# solo cuenta el cuerpo; las insignias nuevas todavía no
		if pos.distance_to(global_position) <= ALCANCE_JUGADOR + RADIO_CUERPO:
			quitar_vida(DANO_ATURDIDO)
		return
	# bloqueado: se golpea a la insignia más cercana de las que alcanza
	var mejor = null
	var mejor_d = ALCANCE_JUGADOR + RADIO_INSIGNIA
	for ins in insignias:
		var d = pos.distance_to(ins.global_position)
		if d <= mejor_d:
			mejor_d = d
			mejor = ins
	if mejor != null:
		mejor.poner_vida(mejor.vida - 1)
		if mejor.vida <= 0:
			reventar_insignia(mejor)
	# si solo alcanza el cuerpo estando bloqueado: no pasa nada

func quitar_vida(n):
	vida = max(vida - n, 0)
	vida_cambiada.emit(vida, VIDA_MAX)
	if vida <= 0:
		morir()
	elif fase == 1 and vida < FASE2_VIDA:
		entrar_fase_2()

func entrar_fase_2():
	fase = 2
	vel_orbita = deg_to_rad(VEL_ORBITA) * MULT_ORBITA_F2
	print("Jefe: FASE 2")

func morir():
	muerto = true
	print("Pelea terminada en ", snappedf(t_pelea, 0.1), " s")
	murio.emit()
	queue_free()

# ---------------- Teclas de debug (borrar al final) ----------------
# F1 (invocar al jefe) vive en comun/sistema/oleadas.gd

func _unhandled_input(event):
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			aturdir()
		elif event.keycode == KEY_F3 and estado == Estado.ATACANDO:
			limpiar_ataques()
			iniciar_ataques(true)   # fuerza el siguiente ataque de la cola, sin pausa ni cooldown
		elif event.keycode == KEY_F4 and fase == 1:
			quitar_vida(vida - FASE2_VIDA + 1)
		elif event.keycode == KEY_F5:
			print("Duración de la pelea: ", snappedf(t_pelea, 0.1), " s")
		elif event.keycode == KEY_F6:
			# golpe de prueba a la insignia más cercana al jugador
			if estado == Estado.ATACANDO and not insignias.is_empty():
				recibir_golpe(insignias[0].global_position)
		elif event.keycode == KEY_F7:
			recibir_golpe(global_position)   # golpe de prueba al cuerpo
		elif event.keycode == KEY_F8 and estado == Estado.ATACANDO:
			# fuerza un cambio de set ya (cancela el ataque en curso y reanuda la cola al terminar)
			limpiar_ataques()
			id_ataque += 1
			en_aviso = false
			reco_aviso = false
			ocultar_nombre()
			var mi_id = id_ataque
			await cambiar_set(mi_id)
			if mi_id == id_ataque and not muerto:
				iniciar_ataques()
		elif event.keycode == KEY_F9 and estado == Estado.ATACANDO:
			# fuerza Suscriptores ya (cancela el ataque en curso y reanuda la cola al terminar)
			limpiar_ataques()
			id_ataque += 1
			en_aviso = false
			reco_aviso = false
			ocultar_nombre()
			var mi_id = id_ataque
			await ataque_suscriptores(mi_id)
			if mi_id == id_ataque and not muerto:
				cooldown["suscriptores"] = COOLDOWNS["suscriptores"]
				iniciar_ataques()
		elif event.keycode == KEY_F10 and estado == Estado.ATACANDO:
			# revienta todas las insignias de golpe (copia: la lista cambia mientras se recorre)
			for ins in insignias.duplicate():
				if not muerto and is_instance_valid(ins):
					reventar_insignia(ins)
