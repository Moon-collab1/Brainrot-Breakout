extends "res://comun/jefe/jefe_base.gd"

# Jefe de la Zona 4 «El Gemelo Digital». Pelea dentro de un ascensor (arena de 650x440).
# La lógica común está en comun/jefe/jefe_base.gd. Aquí solo están sus 4 ataques:
#   Reflejo           una sombra copia tus movimientos con 1 s de retraso; tocarla duele
#   Clones de espejo  2 clones falsos (3 en fase 2); una cachetada los desvanece
#   Apagón            las luces se van 5 s: NO se ve nada. Solo si abres el celular alumbras
#                     150 px a tu alrededor (pero el celular sube la dopamina y te frena)
#   Sacudida de cables el ascensor tiembla y los pasamanos cambian de lugar
#   Refuerzos         llama 10 zombis (solo si quedan menos de 4 vivos)
# El Gemelo y sus clones PERSIGUEN al jugador, como los zombis.
# Cómo se le pega: cada 2 ataques el Gemelo se «desincroniza» (aturdido 4 s) y ahí hay
# que pegarle al REAL (los clones siguen dando vueltas para confundirte).

# --- Balance (todo se ajusta aquí) ---
const VIDA = 40
const FASE2_VIDA = 20
const RADIO = 55.0
const DANO_CONTACTO = 20.0
const VEL_PERSIGUE = 110.0       # CAMBIO: el Gemelo ahora te PERSIGUE a esta velocidad (antes paseaba a 80).
                                 # Los zombis van a 100 y tú a 300.
const COOLDOWNS = {"reflejo": 12.0, "clones": 14.0, "apagon": 13.0, "sacudida": 11.0, "llamado": 20.0}
const NOMBRES = {"reflejo": "Reflejo", "clones": "Clones de espejo", "apagon": "Apagón", "sacudida": "Sacudida de cables", "llamado": "Refuerzos"}
const VENTANA_CADA = 2           # ataques entre desincronizaciones
const VENTANA_SEG = 4.0
# Reflejo
const REFLEJO_AVISO = 0.8
const REFLEJO_DURA = 8.0
const REFLEJO_RETRASO = 1.0
const REFLEJO_RETRASO_F2 = 0.7   # en fase 2 te alcanza más rápido
const REFLEJO_DANO = 12.0
# Clones de espejo
const CLONES_AVISO = 0.8
const CLONES_CANT = 2
const CLONES_CANT_F2 = 3
const CLONES_DURA = 10.0
const CLONES_VEL = 130.0          # CAMBIO: los clones te persiguen a esta velocidad (antes paseaban a 70)
const CLONES_DISTANCIA_MIN = 150.0   # no nacen encima del jugador
const COLOR_CLON = Color(0.3, 0.95, 1.0)   # CAMBIO: todos los clones del mismo color que el Gemelo (antes cian, magenta y verde)
# Apagón
const APAGON_AVISO = 1.0
const APAGON_DURA = 5.0
const APAGON_RADIO = 150.0           # radio de luz alrededor del jugador
const APAGON_COLOR = Color(0, 0, 0)  # CAMBIO: negro total (antes casi negro)
# Sacudida de cables
const SACUDIDA_AVISO = 1.0
const SACUDIDA_DURA = 1.5
const SACUDIDA_FUERZA = 8.0          # píxeles de temblor de la cámara
const PASAMANOS_Y = [200.0, 330.0, 460.0]
# Refuerzos (NUEVO): llama zombis, igual que el «¡SÍGUEME!» del jefe 1 y el «¡SUSCRÍBETE!» del jefe 2
const LLAMADO_AVISO = 1.2        # el cartel sale este tiempo antes de los zombis
const LLAMADO_SI_MENOS_DE = 4    # solo los llama si hay menos de estos zombis vivos
const LLAMADO_CANT = 10          # zombis que llama (antes 4)
const LLAMADO_SEPARACION = 0.4   # segundos entre un zombi y el siguiente
const LLAMADO_TEXTO = "¡REFUERZOS!"

const ROBOT = preload("res://zona_4/jefe/robot.gd")
var reflejo_script = preload("res://zona_4/jefe/ataques/reflejo.gd")
var clon_script = preload("res://zona_4/jefe/ataques/clon_espejo.gd")

var oscuridad = null    # CanvasModulate que oscurece todo
var luz = null          # PointLight2D que sigue al jugador

func configurar():
	vida_max = VIDA
	fase2_vida = FASE2_VIDA
	radio_cuerpo = RADIO
	dano_contacto = DANO_CONTACTO
	nombres = NOMBRES
	cooldowns = COOLDOWNS
	ataques_base = ["reflejo", "clones", "llamado", "apagon", "sacudida"]
	ventana_cada = VENTANA_CADA
	ventana_seg = VENTANA_SEG
	arena = Rect2(311, 170, 530, 320)   # centro del jefe dentro del ascensor

func ejecutar_ataque(nombre, mi_id):
	if nombre == "reflejo":
		await ataque_reflejo(mi_id)
	elif nombre == "clones":
		await ataque_clones(mi_id)
	elif nombre == "apagon":
		await ataque_apagon(mi_id)
	elif nombre == "sacudida":
		await ataque_sacudida(mi_id)
	elif nombre == "llamado":
		await ataque_llamado(mi_id)

# jefe_base.gd pregunta esto antes de lanzar un ataque: los Refuerzos solo salen
# si quedan pocos zombis vivos (para no llenar el ascensor más de la cuenta)
func cumple_condicion(nombre):
	if nombre == "llamado":
		return get_tree().get_nodes_in_group("zombis").size() < LLAMADO_SI_MENOS_DE
	return true

# Se llama al aturdirse o morir: devuelve la luz y la cámara a la normalidad
func al_cancelar():
	apagar_oscuridad()
	reiniciar_camara()
	poner_piso("normal")   # el contador de pisos vuelve a subir normal

# Al morir desaparecen también los clones falsos
func al_morir():
	for c in get_tree().get_nodes_in_group("clones_espejo"):
		c.queue_free()

# ---------------- Cada frame: el Gemelo persigue al jugador ----------------

func actualizar(delta):
	# Apagón: la luz solo existe mientras el celular está abierto (es la «linterna»)
	if luz != null and is_instance_valid(luz):
		luz.visible = jug.cel_abierto
	if estado != Estado.ATACANDO:
		return   # quieto en la intro y mientras está desincronizado
	# Camina en línea recta hacia el jugador (igual que un zombi), sin salirse del ascensor.
	# Si ya está encima del jugador no se mueve más (ahí ya hace daño por contacto).
	var hacia = jug.global_position - global_position
	if hacia.length() > 30.0:
		global_position += hacia.normalized() * VEL_PERSIGUE * delta
		global_position.x = clamp(global_position.x, arena.position.x, arena.end.x)
		global_position.y = clamp(global_position.y, arena.position.y, arena.end.y)

# ---------------- Reflejo ----------------

func ataque_reflejo(mi_id):
	await avisar(mi_id, REFLEJO_AVISO, "reflejo")
	if mi_id != id_ataque or muerto:
		return
	var r = reflejo_script.new()
	r.position = global_position
	r.retraso = REFLEJO_RETRASO
	if fase == 2:
		r.retraso = REFLEJO_RETRASO_F2
	r.dano = REFLEJO_DANO
	r.duracion = REFLEJO_DURA
	get_parent().add_child(r)
	get_parent().move_child(r, 1)   # justo encima del Mapa
	print("Reflejo: dura ", REFLEJO_DURA, " s")

# ---------------- Clones de espejo ----------------

func ataque_clones(mi_id):
	await avisar(mi_id, CLONES_AVISO, "clones")
	if mi_id != id_ataque or muerto:
		return
	var cant = CLONES_CANT
	if fase == 2:
		cant = CLONES_CANT_F2
	for i in range(cant):
		# posición al azar, lejos del jugador
		var pos = global_position
		for intento in range(10):
			pos = Vector2(randf_range(arena.position.x, arena.end.x), randf_range(arena.position.y, arena.end.y))
			if pos.distance_to(jug.global_position) >= CLONES_DISTANCIA_MIN:
				break
		crear_clon(pos)
	print("Clones: ", cant)

# Crea un clon en "pos" (lo usa el ataque Clones de espejo)
func crear_clon(pos):
	var c = clon_script.new()
	c.tono = COLOR_CLON   # todos iguales: son clones
	c.arena = arena
	c.duracion = CLONES_DURA
	c.vel = CLONES_VEL
	c.position = pos
	get_parent().add_child(c)
	get_parent().move_child(c, 1)   # justo encima del Mapa

# ---------------- Refuerzos (llama zombis) ----------------
# Cartel 1,2 s y luego llegan los zombis de a uno, por los bordes del ascensor.
# Si se cancela (el jefe se desincroniza), los que ya salieron se quedan.

func ataque_llamado(mi_id):
	var hud = get_parent().get_node("HUD")
	hud.mostrar_banner(true, LLAMADO_TEXTO)
	await avisar(mi_id, LLAMADO_AVISO, "llamado")
	if mi_id != id_ataque or muerto:
		return   # se canceló: limpiar_ataques() ya escondió el cartel
	hud.mostrar_banner(false)
	for i in range(LLAMADO_CANT):
		get_parent().crear_zombi()   # usa el spawn seguro de oleadas.gd (bordes del ascensor)
		if i < LLAMADO_CANT - 1:
			await esperar(LLAMADO_SEPARACION)
			if mi_id != id_ataque or muerto:
				return
	print("Refuerzos: ", LLAMADO_CANT, " zombis")

# ---------------- Apagón ----------------

func ataque_apagon(mi_id):
	await avisar(mi_id, APAGON_AVISO, "apagon")
	if mi_id != id_ataque or muerto:
		return
	encender_oscuridad()
	await esperar(APAGON_DURA)
	apagar_oscuridad()

# CanvasModulate deja todo el mundo del juego en negro (el HUD no se oscurece).
# PointLight2D pegada al jugador es la luz del celular: un círculo de 150 px de radio
# que SOLO se enciende con el celular abierto (ver actualizar()).
func encender_oscuridad():
	apagar_oscuridad()
	oscuridad = CanvasModulate.new()
	oscuridad.color = APAGON_COLOR
	get_parent().add_child(oscuridad)
	# textura redonda: blanco en el centro, transparente en el borde
	var grad = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.width = int(APAGON_RADIO * 2.0)
	tex.height = int(APAGON_RADIO * 2.0)
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	luz = PointLight2D.new()
	luz.texture = tex
	luz.energy = 1.3
	luz.visible = jug.cel_abierto   # si el celular está cerrado, empieza apagada
	jug.add_child(luz)
	print("Apagón: radio de luz ", APAGON_RADIO)

func apagar_oscuridad():
	if oscuridad != null and is_instance_valid(oscuridad):
		oscuridad.queue_free()
	if luz != null and is_instance_valid(luz):
		luz.queue_free()
	oscuridad = null
	luz = null

# ---------------- Sacudida de cables ----------------

func ataque_sacudida(mi_id):
	poner_piso("aviso")    # aviso: el contador de pisos sube muy rápido (algo anda mal...)
	await avisar(mi_id, SACUDIDA_AVISO, "sacudida")
	if mi_id != id_ataque or muerto:
		return             # se canceló: al_cancelar() ya devolvió el contador a normal
	poner_piso("caida")    # ¡el ascensor se cae! el contador baja rapidísimo
	mover_pasamanos()
	var cam = get_parent().get_node_or_null("Camara")
	var t = 0.0
	while t < SACUDIDA_DURA:
		if cam != null:
			cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * SACUDIDA_FUERZA
		await esperar(0.04)
		if mi_id != id_ataque or muerto:
			reiniciar_camara()
			return
		t += 0.04
	reiniciar_camara()
	poner_piso("normal")   # se acabó la caída: vuelve a subir despacio

# Le dice al mapa cómo debe moverse el contador de pisos: "normal", "aviso" o "caida"
func poner_piso(modo):
	var mapa = get_parent().get_node_or_null("Mapa")
	if mapa != null:
		mapa.modo_piso = modo

func reiniciar_camara():
	var cam = get_parent().get_node_or_null("Camara")
	if cam != null:
		cam.offset = Vector2.ZERO

# Cada pasamanos salta a otra altura (sin caer encima del jugador)
func mover_pasamanos():
	for nombre in ["Mapa/PasamanosIzq", "Mapa/PasamanosDer"]:
		var barra = get_parent().get_node_or_null(nombre)
		if barra == null:
			continue
		var opciones = []
		for y in PASAMANOS_Y:
			if abs(y - barra.position.y) > 1.0:
				# no se mueve a donde está el jugador pegado a la pared
				if abs(jug.global_position.x - barra.position.x) > 70.0 or abs(jug.global_position.y - y) > 130.0:
					opciones.append(y)
		if opciones.is_empty():
			continue
		var nueva_y = opciones[randi() % opciones.size()]
		var tw = create_tween()
		tw.tween_property(barra, "position:y", nueva_y, 0.4)

# ---------------- Dibujo placeholder ----------------

func _draw():
	var aturdido = estado == Estado.ATURDIDO
	ROBOT.dibujar(self, Color(0.3, 0.95, 1.0), 1.0, aturdido)
	if aturdido:
		draw_string(ThemeDB.fallback_font, Vector2(-70, -110), "¡DESINCRONIZADO!", HORIZONTAL_ALIGNMENT_CENTER, 140, 16, Color(1, 1, 0.4))
