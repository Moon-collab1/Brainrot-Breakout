extends Node2D

# JefeBase: lo que TODOS los jefes de las zonas 3 a 6 tienen en común.
# Cada jefe (Capataz, Gemelo, Dr. Dopamina, Núcleo) hace "extends" de este archivo y solo
# agrega sus ataques. Así no se repite la misma lógica cuatro veces.
#
# Cómo se pelea (igual en los cuatro):
#   1. El jefe nace con una INTRO de 2 s (no se le puede golpear).
#   2. Pasa a ATACANDO: saca un ataque de la cola, lo ejecuta, descansa y repite.
#   3. Solo recibe daño en estado ATURDIDO (la "ventana de daño"). Cada jefe decide
#      cuándo se aturde: el Capataz al chocar, el Dr. al agotarse, etc.
#   4. Al bajar de fase2_vida entra a la fase 2 (más ataques o más rápido).
#
# Estructuras de datos usadas: la cola de ataques es una Lista propia
# (quitar_primero / agregar_final), igual que la cola de oleadas.

signal vida_cambiada(valor, maximo)   # el HUD la usa para la barra del jefe
signal murio                          # oleadas.gd la usa para limpiar la zona

const ALCANCE_JUGADOR = 100.0   # igual a "alcance" de jugador.gd
const TIEMPO_INTRO = 2.0
const PAUSA_ATAQUE = 1.5        # descanso entre ataques
const PAUSA_ATAQUE_F2 = 1.0     # descanso en fase 2
const ESPERA_COOLDOWN = 0.5     # si ningún ataque sirve, reintenta tras este tiempo

# Los tres estados del jefe
enum Estado { INTRO, ATACANDO, ATURDIDO }

# --- Valores que cada jefe cambia en su función configurar() ---
var vida_max = 40
var fase2_vida = 20
var radio_cuerpo = 70.0       # tamaño del cuerpo (daño por contacto y alcance de la cachetada)
var dano_contacto = 20.0      # vida por segundo si el jugador toca el cuerpo
var dano_golpe = 1            # vida que quita cada cachetada cuando está aturdido
var nombres = {}              # ataque -> texto que se muestra bajo el jefe
var cooldowns = {}            # ataque -> segundos que tarda en poder repetirse
var ataques_base = []         # ataques que hay en la cola desde el inicio
var ataques_fase2 = []        # ataques que se agregan a la cola en fase 2
var ventana_cada = 0          # si > 0: cada tantos ataques el jefe se aturde solo
var ventana_seg = 4.0         # cuánto dura esa ventana
var arena = Rect2(90, 195, 972, 380)   # zona donde puede estar el CENTRO del jefe

# --- Estado interno ---
var vida = 0
var fase = 1
var estado = Estado.INTRO
var muerto = false
var id_ataque = 0        # sube al cancelar; cada ataque lo compara después de cada await
var en_aviso = false
var t_pelea = 0.0
var ataques_hechos = 0
var cola = Lista.new()   # cola de rotación de ataques
var cooldown = {}        # segundos que le faltan a cada ataque para poder usarse
var tw_intro = null

# jug = el jugador; el jefe y el jugador son hijos del mismo nodo raíz de la zona
@onready var jug = get_parent().get_node("Jugador")
@onready var etiqueta_nombre = $NombreAtaque
@onready var timer_estado = $TimerEstado

# ---------------- Funciones que cada jefe puede reemplazar ("hooks") ----------------

func configurar():
	pass   # el hijo pone aquí vida_max, nombres, cooldowns, etc.

func actualizar(_delta):
	pass   # el hijo mueve al jefe o actualiza marcas cada frame

func ejecutar_ataque(_nombre, _mi_id):
	pass   # el hijo dice qué hace cada ataque

func cumple_condicion(_nombre):
	return true   # el hijo puede impedir que un ataque salga si no tiene sentido

func contacto_activo():
	return true   # el hijo lo apaga cuando el cuerpo no debe hacer daño

func al_cancelar():
	pass   # el hijo limpia sus cosas propias (luces, marcas) al aturdirse o morir

func al_entrar_fase2():
	pass

func pausa_actual():
	if fase == 2:
		return PAUSA_ATAQUE_F2
	return PAUSA_ATAQUE

# ---------------- Inicio ----------------

func _ready():
	add_to_group("jefe")   # jugador.gd llama recibir_golpe() a todo este grupo
	configurar()
	vida = vida_max
	for nombre in ataques_base:
		cola.agregar_final(nombre)
	for nombre in cooldowns:
		cooldown[nombre] = 0.0
	etiqueta_nombre.position = Vector2(-160, radio_cuerpo + 50)
	etiqueta_nombre.size = Vector2(320, 24)
	etiqueta_nombre.visible = false
	vida_cambiada.emit(vida, vida_max)
	# aparece con un fundido durante la intro
	modulate.a = 0.0
	tw_intro = create_tween()
	tw_intro.tween_property(self, "modulate:a", 1.0, 1.0)
	timer_estado.timeout.connect(_al_terminar_estado)
	cambiar_estado(Estado.INTRO)

func _process(delta):
	if muerto:
		return
	t_pelea += delta
	for nombre in cooldown:
		cooldown[nombre] = max(cooldown[nombre] - delta, 0.0)
	actualizar(delta)
	dano_por_contacto(delta)
	queue_redraw()

# ---------------- Estados ----------------

func cambiar_estado(nuevo):
	estado = nuevo
	timer_estado.stop()
	if nuevo == Estado.INTRO:
		timer_estado.start(TIEMPO_INTRO)
	print("Jefe: ", Estado.keys()[nuevo])

# El Timer avisa cuando termina la intro o el aturdimiento
func _al_terminar_estado():
	if estado == Estado.INTRO or estado == Estado.ATURDIDO:
		cambiar_estado(Estado.ATACANDO)
		iniciar_ataques()

# Aturde al jefe "seg" segundos: cancela el ataque en curso y limpia el piso.
# Los zombis se quedan. Aquí es cuando el jugador puede pegarle.
func aturdir(seg):
	id_ataque += 1   # los ataques en marcha ven que cambió y se detienen
	en_aviso = false
	ocultar_nombre()
	limpiar_ataques()
	estado = Estado.ATURDIDO
	timer_estado.stop()
	timer_estado.start(seg)
	print("Jefe: ATURDIDO ", seg, " s")

func limpiar_ataques():
	# get_nodes_in_group devuelve una copia, es seguro liberar dentro del bucle
	for p in get_tree().get_nodes_in_group("proyectiles"):
		p.queue_free()
	for f in get_tree().get_nodes_in_group("franjas"):
		f.queue_free()
	get_parent().get_node("HUD").mostrar_banner(false)
	al_cancelar()

# ---------------- Cola de ataques ----------------

# directo = true: ataca ya (sin pausa) e ignora cooldowns (lo usa la tecla F3)
func iniciar_ataques(directo = false):
	id_ataque += 1
	en_aviso = false
	ocultar_nombre()
	bucle_ataques(id_ataque, directo)

func bucle_ataques(mi_id, directo):
	var saltar_pausa = directo
	while mi_id == id_ataque and not muerto:
		if not saltar_pausa:
			await esperar(pausa_actual())
			if mi_id != id_ataque or muerto:
				return
		saltar_pausa = false
		var nombre = siguiente_ataque(directo)
		directo = false
		if nombre == null:
			# ningún ataque sirve ahora: espera 0,5 s y vuelve a probar
			await esperar(ESPERA_COOLDOWN)
			saltar_pausa = true
			continue
		print("Cola -> ", nombre)
		await ejecutar_ataque(nombre, mi_id)
		cooldown[nombre] = cooldowns[nombre]   # el cooldown cuenta desde que termina
		if mi_id != id_ataque or muerto:
			return   # se canceló (por ejemplo, el jefe se aturdió solo)
		ataques_hechos += 1
		# ventana de daño automática (Gemelo y Núcleo): cada N ataques se aturde
		if ventana_cada > 0 and ataques_hechos % ventana_cada == 0:
			aturdir(ventana_seg)
			return

# Saca el primero de la cola y lo vuelve a meter al final.
# Si está en cooldown o no cumple su condición, prueba con el siguiente.
func siguiente_ataque(ignorar):
	for i in range(cola.tam):
		var nombre = cola.quitar_primero()
		cola.agregar_final(nombre)
		if ignorar or (cooldown[nombre] <= 0.0 and cumple_condicion(nombre)):
			return nombre
	return null

# Muestra el nombre del ataque bajo el jefe mientras dura el aviso
func avisar(mi_id, seg, nombre):
	mostrar_nombre(nombres[nombre])
	en_aviso = true
	await esperar(seg)
	if mi_id == id_ataque:   # si se canceló, aturdir() ya lo apagó
		en_aviso = false
		ocultar_nombre()

# Espera sin usar el árbol global: si el jefe se libera, la corrutina simplemente no continúa
func esperar(seg):
	var t = Timer.new()
	t.one_shot = true
	add_child(t)
	t.start(seg)
	await t.timeout
	t.queue_free()

func mostrar_nombre(texto):
	etiqueta_nombre.text = texto.to_upper() + " ◂"
	etiqueta_nombre.visible = true

func ocultar_nombre():
	etiqueta_nombre.visible = false

# ---------------- Utilidades ----------------

# ¿Un círculo de ese radio en "pos" toca una caja, estante, pilar, mesa...?
# Usa la forma de colisión de cada obstáculo (nodo hijo "Colision").
func obstaculo_en(pos, radio):
	for grupo in ["rebotables", "obstaculos"]:
		for o in get_tree().get_nodes_in_group(grupo):
			var col = o.get_node("Colision")
			var forma = col.shape
			if forma is RectangleShape2D:
				var rect = Rect2(col.global_position - forma.size / 2.0, forma.size).grow(radio)
				if rect.has_point(pos):
					return true
			elif forma is CircleShape2D:
				if col.global_position.distance_to(pos) < forma.radius + radio:
					return true
	return false

# ---------------- Contacto y daño ----------------

func dano_por_contacto(delta):
	if estado == Estado.INTRO or not contacto_activo():
		return
	if jug.global_position.distance_to(global_position) <= radio_cuerpo:
		jug.vida -= dano_contacto * delta

# pos = posición del jugador al dar la cachetada (la llama jugador.dar_cachetada)
func recibir_golpe(pos):
	if muerto or estado != Estado.ATURDIDO:
		return   # solo se le pega con el jefe aturdido
	if pos.distance_to(global_position) <= ALCANCE_JUGADOR + radio_cuerpo:
		quitar_vida(dano_golpe)

func quitar_vida(n):
	vida = max(vida - n, 0)
	vida_cambiada.emit(vida, vida_max)
	if vida <= 0:
		morir()
	elif fase == 1 and vida < fase2_vida:
		entrar_fase_2()

func entrar_fase_2():
	fase = 2
	for nombre in ataques_fase2:
		cola.agregar_final(nombre)
	al_entrar_fase2()
	print("Jefe: FASE 2")

func morir():
	muerto = true
	id_ataque += 1
	limpiar_ataques()
	print("Pelea terminada en ", snappedf(t_pelea, 0.1), " s")
	murio.emit()
	al_morir()
	queue_free()

func al_morir():
	pass   # el hijo puede hacer algo al final (el Núcleo muestra la victoria)

# ---------------- Teclas de debug (borrar al final) ----------------
# F1 (invocar al jefe) vive en comun/sistema/oleadas.gd

func _unhandled_input(event):
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			aturdir(4.0)
		elif event.keycode == KEY_F3 and estado == Estado.ATACANDO:
			limpiar_ataques()
			iniciar_ataques(true)   # fuerza el siguiente ataque, sin pausa ni cooldown
		elif event.keycode == KEY_F4 and fase == 1:
			quitar_vida(vida - fase2_vida + 1)
		elif event.keycode == KEY_F5:
			print("Duración de la pelea: ", snappedf(t_pelea, 0.1), " s")
		elif event.keycode == KEY_F6:
			recibir_golpe(global_position)   # golpe de prueba al cuerpo
