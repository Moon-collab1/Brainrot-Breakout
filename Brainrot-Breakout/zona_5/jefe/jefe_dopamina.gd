extends "res://comun/jefe/jefe_base.gd"

# Jefe de la Zona 5 «Dr. Dopamina» (un cerebro en una pecera, con bata).
# La lógica común está en comun/jefe/jefe_base.gd. Aquí solo están sus 4 ataques:
#   Nube tóxica       charcos verdes de 8 s; quien los pisa recibe +dopamina continua
#   Jeringazo         embestida con aguja; si te pincha: +20 dopamina en vez de daño de vida
#   Control invertido tus controles quedan al revés 4 s Y AL MISMO TIEMPO te persiguen
#                     mini-cerebros (combo): tienes que esquivarlos con los controles al revés
#   Cerebros mutantes 4 mini-cerebros rápidos que explotan al tocarte (6 en fase 2)
# Cómo se le pega: después de cada Jeringazo queda «agotado» 3 s y ahí se le puede pegar.

# --- Balance (todo se ajusta aquí) ---
const VIDA = 24
const FASE2_VIDA = 12
const RADIO = 60.0
const DANO_CONTACTO = 15.0
const COOLDOWNS = {"nube": 11.0, "jeringazo": 9.0, "invertido": 14.0, "cerebros": 13.0}
const NOMBRES = {"nube": "Nube tóxica", "jeringazo": "Jeringazo", "invertido": "Control invertido", "cerebros": "Cerebros mutantes"}
# Nube tóxica
const NUBE_AVISO = 0.8
const NUBE_CANT = 3
const NUBE_CANT_F2 = 5
const NUBE_RADIO = 60.0
const NUBE_AVISO_CHARCO = 0.6
const NUBE_DURA = 8.0
const NUBE_DOPA = 10.0           # dopamina por segundo dentro del charco
const NUBE_DISTANCIA_MIN = 90.0  # no nace justo encima del jugador
const NUBE_AREA = Rect2(90, 170, 972, 430)
# Jeringazo
const JERINGA_AVISO = 1.0
const JERINGA_APUNTA = 0.6       # la marca sigue al jugador este tiempo; luego se bloquea
const JERINGA_VEL = 700.0
const JERINGA_DOPA = 20.0        # sobredosis al pincharte
const JERINGA_AGOTADO = 3.0      # segundos agotado después (aquí se le pega)
# Control invertido
const INVERTIDO_AVISO = 0.8
const INVERTIDO_SEG = 4.0
const INVERTIDO_SEG_F2 = 5.0
# Combo: cerebros que salen mientras los controles están invertidos (en 2 tandas)
const INVERTIDO_CEREBROS = 2       # cerebros por tanda
const INVERTIDO_CEREBROS_F2 = 3
const INVERTIDO_VEL_CEREBRO = 170.0   # más lentos que los normales (240): con los controles al revés ya es difícil
# Cerebros mutantes
const CEREBROS_AVISO = 0.8
const CEREBROS_CANT = 4
const CEREBROS_CANT_F2 = 6
const CEREBROS_VEL = 240.0
const CEREBROS_DANO = 10.0
const CEREBROS_DOPA = 8.0
const RADIO_SALIDA = 70.0        # los cerebros salen del borde del cuerpo

var charco_script = preload("res://zona_5/jefe/ataques/charco.gd")
var cerebro_script = preload("res://zona_5/jefe/ataques/cerebro.gd")

var jer_ang = 0.0
var jer_t = 0.0
var jer_aviso = false
var inyectando = false
var jer_choco = false
var jer_pincho = false

func configurar():
	vida_max = VIDA
	fase2_vida = FASE2_VIDA
	radio_cuerpo = RADIO
	dano_contacto = DANO_CONTACTO
	nombres = NOMBRES
	cooldowns = COOLDOWNS
	ataques_base = ["nube", "jeringazo", "invertido", "cerebros"]
	arena = Rect2(90, 190, 972, 390)

func ejecutar_ataque(nombre, mi_id):
	if nombre == "nube":
		await ataque_nube(mi_id)
	elif nombre == "jeringazo":
		await ataque_jeringazo(mi_id)
	elif nombre == "invertido":
		await ataque_invertido(mi_id)
	elif nombre == "cerebros":
		await ataque_cerebros(mi_id)

func contacto_activo():
	return not inyectando

func al_cancelar():
	jer_aviso = false
	inyectando = false

# ---------------- Cada frame ----------------

func actualizar(delta):
	if jer_aviso:
		jer_t += delta
		if jer_t <= JERINGA_APUNTA:
			jer_ang = (jug.global_position - global_position).angle()
	if inyectando:
		mover_jeringazo(delta)

# ---------------- Nube tóxica ----------------

func ataque_nube(mi_id):
	await avisar(mi_id, NUBE_AVISO, "nube")
	if mi_id != id_ataque or muerto:
		return
	var cant = NUBE_CANT
	if fase == 2:
		cant = NUBE_CANT_F2
	for i in range(cant):
		var pos = global_position
		for intento in range(10):
			pos = Vector2(randf_range(NUBE_AREA.position.x, NUBE_AREA.end.x), randf_range(NUBE_AREA.position.y, NUBE_AREA.end.y))
			if pos.distance_to(jug.global_position) >= NUBE_DISTANCIA_MIN:
				break
		var c = charco_script.new()
		c.position = pos
		c.radio = NUBE_RADIO
		c.dopa_seg = NUBE_DOPA
		c.aviso = NUBE_AVISO_CHARCO
		c.duracion = NUBE_DURA
		get_parent().add_child(c)
		get_parent().move_child(c, 1)   # justo encima del Mapa
	print("Nube tóxica: ", cant, " charcos")

# ---------------- Jeringazo ----------------

func mover_jeringazo(delta):
	var dir = Vector2.from_angle(jer_ang)
	var nueva = global_position + dir * JERINGA_VEL * delta
	if not arena.has_point(nueva) or obstaculo_en(nueva, radio_cuerpo - 10.0):
		inyectando = false
		jer_choco = true
		return
	global_position = nueva
	# si te alcanza, NO quita vida: te inyecta dopamina (una sola vez)
	if not jer_pincho and global_position.distance_to(jug.global_position) <= radio_cuerpo + 20.0:
		jer_pincho = true
		jug.dopa += JERINGA_DOPA
		jug.empujar(dir * 120.0)
		print("Jeringazo: sobredosis +", JERINGA_DOPA)

func ataque_jeringazo(mi_id):
	jer_ang = (jug.global_position - global_position).angle()
	jer_t = 0.0
	jer_aviso = true
	await avisar(mi_id, JERINGA_AVISO, "jeringazo")
	jer_aviso = false
	if mi_id != id_ataque or muerto:
		return
	jer_choco = false
	jer_pincho = false
	inyectando = true
	while inyectando and mi_id == id_ataque and not muerto:
		await esperar(0.03)
	inyectando = false
	if jer_choco and mi_id == id_ataque and not muerto:
		aturdir(JERINGA_AGOTADO)   # queda agotado: ahora sí se le pega

# ---------------- Control invertido ----------------

func ataque_invertido(mi_id):
	await avisar(mi_id, INVERTIDO_AVISO, "invertido")
	if mi_id != id_ataque or muerto:
		return
	var seg = INVERTIDO_SEG
	if fase == 2:
		seg = INVERTIDO_SEG_F2
	jug.invertido_t = seg   # jugador.gd invierte las direcciones mientras sea > 0
	var hud = get_parent().get_node("HUD")
	hud.mostrar_banner(true, "¡INVERTIDO!")
	# COMBO: mientras los controles están al revés salen cerebros en 2 tandas
	# (una al empezar y otra a la mitad), para que el control invertido sí sea un peligro
	var cant = INVERTIDO_CEREBROS
	if fase == 2:
		cant = INVERTIDO_CEREBROS_F2
	soltar_cerebros(cant, INVERTIDO_VEL_CEREBRO)
	await esperar(seg / 2.0)
	if mi_id != id_ataque or muerto:
		return   # se canceló: limpiar_ataques() ya escondió el cartel y borró los cerebros
	soltar_cerebros(cant, INVERTIDO_VEL_CEREBRO)
	await esperar(seg / 2.0)
	if mi_id != id_ataque or muerto:
		return
	hud.mostrar_banner(false)

# ---------------- Cerebros mutantes ----------------

func ataque_cerebros(mi_id):
	await avisar(mi_id, CEREBROS_AVISO, "cerebros")
	if mi_id != id_ataque or muerto:
		return
	var cant = CEREBROS_CANT
	if fase == 2:
		cant = CEREBROS_CANT_F2
	soltar_cerebros(cant, CEREBROS_VEL)
	print("Cerebros mutantes: ", cant)

# Crea "cant" mini-cerebros alrededor del jefe (lo usan Cerebros mutantes y el combo del Control invertido)
func soltar_cerebros(cant, velocidad):
	for i in range(cant):
		var c = cerebro_script.new()
		var ang = TAU * i / cant + randf() * 0.5
		c.position = global_position + Vector2.from_angle(ang) * RADIO_SALIDA
		c.vel = velocidad
		c.dano = CEREBROS_DANO
		c.dopa = CEREBROS_DOPA
		get_parent().add_child(c)

# ---------------- Dibujo placeholder ----------------

func _draw():
	var aturdido = estado == Estado.ATURDIDO
	# marca del Jeringazo: franja rosada hasta el borde
	if jer_aviso:
		var dir = Vector2.from_angle(jer_ang)
		var lado = dir.orthogonal() * 18.0
		var fin = dir * 1400.0
		var alfa = 0.2
		if jer_t > JERINGA_APUNTA:
			alfa = 0.45
		draw_colored_polygon(PackedVector2Array([lado, lado + fin, -lado + fin, -lado]), Color(1, 0.2, 0.3, alfa))
	# bata blanca
	var bata = Color(0.95, 0.97, 0.98)
	if aturdido:
		bata = Color(0.7, 0.8, 0.9)
	draw_colored_polygon(PackedVector2Array([Vector2(-65, 75), Vector2(-42, -10), Vector2(42, -10), Vector2(65, 75)]), bata)
	draw_line(Vector2(0, -10), Vector2(0, 75), Color(0.6, 0.7, 0.75), 2.0)
	# pecera con el cerebro
	draw_circle(Vector2(0, -52), 46.0, Color(0.6, 0.9, 0.95, 0.5))
	draw_arc(Vector2(0, -52), 46.0, 0.0, TAU, 40, Color(0.7, 0.95, 1, 1), 4.0)
	draw_circle(Vector2(0, -50), 30.0, Color(0.95, 0.5, 0.65))
	draw_line(Vector2(0, -78), Vector2(0, -24), Color(0.7, 0.2, 0.35), 2.0)
	var ojo = Color(1, 1, 1)
	draw_circle(Vector2(-10, -52), 6.0, ojo)
	draw_circle(Vector2(10, -52), 6.0, ojo)
	if aturdido:
		draw_line(Vector2(-16, -52), Vector2(-4, -52), Color(0.1, 0.05, 0.1), 3.0)
		draw_line(Vector2(4, -52), Vector2(16, -52), Color(0.1, 0.05, 0.1), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(-50, -112), "¡AGOTADO!", HORIZONTAL_ALIGNMENT_CENTER, 100, 16, Color(1, 1, 0.4))
	else:
		draw_circle(Vector2(-10, -52), 2.5, Color(0.1, 0.05, 0.1))
		draw_circle(Vector2(10, -52), 2.5, Color(0.1, 0.05, 0.1))
	# suero (poste con bolsa verde)
	draw_line(Vector2(75, -20), Vector2(75, 75), Color(0.7, 0.75, 0.8), 4.0)
	draw_rect(Rect2(66, -40, 18, 28), Color(0.3, 0.9, 0.5))
