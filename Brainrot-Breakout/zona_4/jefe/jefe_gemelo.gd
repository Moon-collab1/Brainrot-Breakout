extends "res://comun/jefe/jefe_base.gd"

# Jefe de la Zona 4 «El Gemelo Digital». Pelea dentro de un ascensor (arena de 650x440).
# La lógica común está en comun/jefe/jefe_base.gd. Aquí solo están sus 4 ataques:
#   Reflejo           una sombra copia tus movimientos con 1 s de retraso; tocarla duele
#   Clones de espejo  2 clones falsos (3 en fase 2); una cachetada los desvanece
#   Apagón            las luces fallan 5 s: solo ves 150 px alrededor del jugador
#   Sacudida de cables el ascensor tiembla y los pasamanos cambian de lugar
# Cómo se le pega: cada 2 ataques el Gemelo se «desincroniza» (aturdido 4 s) y ahí hay
# que pegarle al REAL (los clones siguen dando vueltas para confundirte).

# --- Balance (todo se ajusta aquí) ---
const VIDA = 40
const FASE2_VIDA = 20
const RADIO = 55.0
const DANO_CONTACTO = 20.0
const VEL_VAGA = 80.0            # el Gemelo da vueltas por la arena a esta velocidad
const COOLDOWNS = {"reflejo": 12.0, "clones": 14.0, "apagon": 13.0, "sacudida": 11.0}
const NOMBRES = {"reflejo": "Reflejo", "clones": "Clones de espejo", "apagon": "Apagón", "sacudida": "Sacudida de cables"}
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
const CLONES_DISTANCIA_MIN = 150.0   # no nacen encima del jugador
const COLORES_CLON = [Color(0.3, 0.9, 1.0), Color(1.0, 0.3, 0.8), Color(0.6, 1.0, 0.5)]
# Apagón
const APAGON_AVISO = 1.0
const APAGON_DURA = 5.0
const APAGON_RADIO = 150.0           # radio de luz alrededor del jugador
const APAGON_COLOR = Color(0.03, 0.03, 0.06)
# Sacudida de cables
const SACUDIDA_AVISO = 1.0
const SACUDIDA_DURA = 1.5
const SACUDIDA_FUERZA = 8.0          # píxeles de temblor de la cámara
const PASAMANOS_Y = [200.0, 330.0, 460.0]

const ROBOT = preload("res://zona_4/jefe/robot.gd")
var reflejo_script = preload("res://zona_4/jefe/ataques/reflejo.gd")
var clon_script = preload("res://zona_4/jefe/ataques/clon_espejo.gd")

var destino = Vector2.ZERO
var oscuridad = null    # CanvasModulate que oscurece todo
var luz = null          # PointLight2D que sigue al jugador

func configurar():
	vida_max = VIDA
	fase2_vida = FASE2_VIDA
	radio_cuerpo = RADIO
	dano_contacto = DANO_CONTACTO
	nombres = NOMBRES
	cooldowns = COOLDOWNS
	ataques_base = ["reflejo", "clones", "apagon", "sacudida"]
	ventana_cada = VENTANA_CADA
	ventana_seg = VENTANA_SEG
	arena = Rect2(311, 170, 530, 320)   # centro del jefe dentro del ascensor
	destino = position

func ejecutar_ataque(nombre, mi_id):
	if nombre == "reflejo":
		await ataque_reflejo(mi_id)
	elif nombre == "clones":
		await ataque_clones(mi_id)
	elif nombre == "apagon":
		await ataque_apagon(mi_id)
	elif nombre == "sacudida":
		await ataque_sacudida(mi_id)

# Se llama al aturdirse o morir: devuelve la luz y la cámara a la normalidad
func al_cancelar():
	apagar_oscuridad()
	reiniciar_camara()

# Al morir desaparecen también los clones falsos
func al_morir():
	for c in get_tree().get_nodes_in_group("clones_espejo"):
		c.queue_free()

# ---------------- Cada frame: el Gemelo vaga por la arena ----------------

func actualizar(delta):
	if estado != Estado.ATACANDO:
		return   # quieto en la intro y mientras está desincronizado
	if global_position.distance_to(destino) < 8.0:
		destino = Vector2(randf_range(arena.position.x, arena.end.x), randf_range(arena.position.y, arena.end.y))
	global_position += (destino - global_position).normalized() * VEL_VAGA * delta

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
		var c = clon_script.new()
		c.tono = COLORES_CLON[i % COLORES_CLON.size()]
		c.arena = arena
		c.duracion = CLONES_DURA
		# posición al azar, lejos del jugador
		var pos = global_position
		for intento in range(10):
			pos = Vector2(randf_range(arena.position.x, arena.end.x), randf_range(arena.position.y, arena.end.y))
			if pos.distance_to(jug.global_position) >= CLONES_DISTANCIA_MIN:
				break
		c.position = pos
		get_parent().add_child(c)
		get_parent().move_child(c, 1)
	print("Clones: ", cant)

# ---------------- Apagón ----------------

func ataque_apagon(mi_id):
	await avisar(mi_id, APAGON_AVISO, "apagon")
	if mi_id != id_ataque or muerto:
		return
	encender_oscuridad()
	await esperar(APAGON_DURA)
	apagar_oscuridad()

# CanvasModulate oscurece todo el mundo del juego (el HUD no se oscurece).
# PointLight2D pegada al jugador deja un círculo de luz de 150 px de radio.
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
	await avisar(mi_id, SACUDIDA_AVISO, "sacudida")
	if mi_id != id_ataque or muerto:
		return
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
