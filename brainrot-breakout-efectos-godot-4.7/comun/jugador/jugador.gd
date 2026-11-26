extends CharacterBody2D

# El jugador (nodo "Jugador" de cada zona). Se mueve con las flechas / joystick táctil, abre el
# celular con la acción "celular" y da cachetadas con la acción "cachetada".
# Las teclas de cada acción se eligen en CONFIGURACIÓN > CONTROLES (ver autoload/ajustes.gd).
#
# Mecánica central:
#   - Vida y DOPAMINA (0-100). Con el celular abierto se cura (+5/s) pero sube la dopamina
#     (+8/s) y va más lento (60 %). Con el celular cerrado la dopamina baja (-2/s).
#   - Pierde si vida llega a 0 o dopamina a 100: se guarda el récord y se reinicia la zona.
#   - La cachetada libera zombis en un círculo frente a él (suma a "libres") y golpea al jefe.
#   - Los jefes y zonas del piso le aplican efectos con las variables de abajo (empuje,
#     arrastre, mult_vel, invertido_t, cel_bloqueado_t...), que se apagan solas.

# Valores visuales/colisión (para revertir: ESCALA = 1.0, RADIO = 10.0)
const ESCALA = 0.4
const RADIO = 20.0
const POSE_DURA = 0.3        # segundos que el sprite muestra la cachetada (carga, barrido, impacto, remate)
const GOLPE_DURA = 0.18      # segundos que dura la animación de la cachetada (la mano cruzando)
const EMPUJE_TIEMPO = 0.25   # lo que dura el empujón del Pulso del jefe
# Sprite animado (assets/sprites/jugador_N.png, una hoja por nivel: 0-3 quieto, 4-9 caminando, 10-13 cachetada).
# Para volver al dibujo por código: USAR_SPRITES = false
const USAR_SPRITES = true
# Una hoja por nivel: la skin mejora al subir de nivel con XP (1 normal ... 6-10 cada vez más fuerte: músculos, vendas, cinturón de campeón, armadura)
const HOJAS_NIVEL = [
	preload("res://assets/sprites/jugador_1.png"),
	preload("res://assets/sprites/jugador_2.png"),
	preload("res://assets/sprites/jugador_3.png"),
	preload("res://assets/sprites/jugador_4.png"),
	preload("res://assets/sprites/jugador_5.png"),
	preload("res://assets/sprites/jugador_6.png"),
	preload("res://assets/sprites/jugador_7.png"),
	preload("res://assets/sprites/jugador_8.png"),
	preload("res://assets/sprites/jugador_9.png"),
	preload("res://assets/sprites/jugador_10.png"),
	preload("res://assets/sprites/jugador_11.png"),
	preload("res://assets/sprites/jugador_12.png"),
]
const XP_NIVELES = [0, 90, 220, 380, 570, 790, 1040, 1320, 1630, 1980, 2380, 2820]   # 12 niveles   # XP que hace falta para cada nivel (1 a 10)
const NOMBRES_NIVEL = ["Novato", "Callejero", "Desconectado", "Leyenda", "Libre total", "Entrenado", "Boxeador", "Campeón", "Blindado", "Titán", "Coloso", "Leyenda Suprema"]

var vel = 300.0            # velocidad base (px/s)
var cel_abierto = false    # celular abierto: cura, sube la dopamina y frena
var vida = 100.0
var dopa = 0.0             # dopamina; al llegar a 100 pierde
var enfria = 0.0           # segundos que faltan para poder dar otra cachetada
var libres = 0             # zombis liberados (el puntaje)
var alcance = 100.0
var cara = Vector2.RIGHT    # hacia dónde mira (última dirección en que se movió)
var desplaz = 45.0          # cuánto se corre el golpe hacia donde mira
var radio_golpe = 70.0      # tamaño del círculo del golpe
var reg = Registro.new()
var record = 0
var empuje = Vector2.ZERO   # velocidad extra (la pone empujar() y decae sola)
var empuje_decae = 0.0
# Las zonas del piso (cinta, shadowban) los ponen y se apagan solos (ver _physics_process)
var arrastre = Vector2.ZERO
var arrastre_t = 0.0
var mult_vel = 1.0
var lento_t = 0.0
var ultimo_liberado = ""   # escena del último zombi liberado (lo copia "Recomendado para ti")
# Efectos de los jefes de las zonas 4 a 6 (se apagan solos al llegar a 0)
var invertido_t = 0.0      # «Control invertido» del Dr. Dopamina: segundos que faltan
var cel_bloqueado_t = 0.0  # «Apagón del celular» del Núcleo-∞: segundos que faltan
var xp = 0                # experiencia (se recoge de los celulares y audífonos del piso)
var nivel = 1             # 1 a 12, sale de XP_NIVELES
var racha = 0             # objetos recogidos seguidos (sin pasar más de RACHA_SEG entre uno y otro)
var t_racha = 0.0
const RACHA_SEG = 1.6
var cel_trans = 0.0       # > 0 mientras saca o guarda el celular (animación de la mano)
var cel_antes = false     # para saber si el celular se acaba de abrir o cerrar
const CEL_TRANS = 0.22
var pose_golpe = 0.0      # tiempo que le queda a la pose de cachetada del sprite (cuadros 10-13)
var golpe_t = 0.0          # tiempo que le queda a la animación de la cachetada (0 = no está pegando)
# Animación y efectos visuales
var spr: Sprite2D          # el sprite animado (se crea en _ready)
var anim_t = 0.0           # reloj de la animación
var vida_ant = 100.0       # vida del cuadro anterior (para saber si lo golpearon)

# --- Power ups (ver poderes.gd): los valores base y los que cambian al elegir un poder ---
const VEL_BASE = 300.0
const RADIO_GOLPE_BASE = 70.0
var vida_max = 100.0        # Pecho de Acero la sube
var vida_prev = 100.0       # vida al final del cuadro anterior (Piel Antizombi devuelve parte del daño)
var dano_acum = 0.0         # fracción de daño de Palma Pesada que todavía no se ha cobrado
var chequeo_t = 1.2         # cada cuánto se revisa si hay un poder por elegir
var dano_t = 0.0           # mientras sea > 0 el sprite se ve rojo (recibió daño)
var dano_aviso_t = 0.0     # espera entre un destello de pantalla y el siguiente
var polvo_t = 0.0          # espera entre una nubecita de polvo y la siguiente

# Prepara al jugador: lee el récord, recupera los libres con que llegó y crea la viñeta
func _ready():
	add_to_group("jugador")
	record = reg.leer()
	libres = Registro.libres_inicio   # los libres con que se entró a la zona
	$Sprite2D.scale = Vector2(ESCALA, ESCALA)
	$Sprite2D.visible = false   # el icono de Godot ya no se usa
	if USAR_SPRITES:
		spr = Sprite2D.new()
		xp = Registro.xp_inicio
		nivel = nivel_de(xp)
		spr.texture = HOJAS_NIVEL[nivel - 1]
		spr.scale = Vector2.ONE * escala_nivel()
		spr.position.y = pies_nivel()
		spr.hframes = 30   # 0-3 quieto, 4-9 caminando, 10-13 cachetada, 14-15 sacar celular, 16-19 scroll, 20-25 caminando con celular, 26-29 cachetada con celular
		spr.frame = 0
		add_child(spr)
	var forma = CircleShape2D.new()
	forma.radius = RADIO
	$CollisionShape2D.shape = forma
	$Golpe/Dibujo.visible = false   # ya no se usa el logo de Godot: la cachetada se dibuja en _draw()
	add_child(preload("res://comun/jugador/vineta.gd").new())   # la viñeta del celular
	aplicar_poderes()      # los poderes elegidos en zonas anteriores siguen activos
	vida = vida_max
	vida_prev = vida
	vida_ant = vida


# Cada frame de física: lee la entrada, aplica celular/cachetada, revisa si perdió y se mueve
func _physics_process(delta):
	Registro.tiempo += delta

	# Piel Antizombi: lo que bajó la vida desde el cuadro anterior (zombis, jefes, ataques) se
	# devuelve en parte. Así no hay que tocar cada ataque; si no hay poder, no suma nada.
	if vida < vida_prev:
		vida += (vida_prev - vida) * Poderes.reduccion_dano()
	# Las acciones "mover_*", "celular" y "cachetada" las crea autoload/ajustes.gd con las teclas
	# que el jugador eligió en CONFIGURACIÓN > CONTROLES
	var dir = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
	

	# Control invertido: las direcciones quedan al revés mientras dure
	if invertido_t > 0.0:
		invertido_t -= delta
		dir = -dir

	# guardar hacia dónde mira (si está quieto, se queda la última dirección)
	if dir != Vector2.ZERO and dir.normalized() != cara:
		cara = dir.normalized()
		queue_redraw()

	# Apagón del celular: mientras dure, el celular se cierra y no se puede abrir
	if cel_bloqueado_t > 0.0:
		cel_bloqueado_t -= delta
		cel_abierto = false
	elif Input.is_action_just_pressed("celular"):
		cel_abierto = not cel_abierto

	var vel_act = vel
	if cel_abierto:
		vel_act = vel * 0.6
		vida += 5 * delta * Poderes.mult_cura()
		dopa += 8 * delta * Poderes.mult_dopa_cel()
	else:
		dopa -= Poderes.caida_dopa() * delta

	# animación de la cachetada: mientras dure, se redibuja cada frame para mover la mano
	if golpe_t > 0.0:
		golpe_t = max(golpe_t - delta, 0.0)
		queue_redraw()

	animar(delta)

	enfria -= delta
	if Input.is_action_just_pressed("cachetada") and enfria <= 0.0:
		enfria = Poderes.enfriamiento()
		dar_cachetada()

	vida = clamp(vida, 0.0, vida_max)
	dopa = clamp(dopa, 0.0, 100.0)
	vida_prev = vida

	# ¿hay un poder por elegir? (se revisa cada 0,4 s)
	chequeo_t -= delta
	if chequeo_t <= 0.0:
		chequeo_t = 0.4
		revisar_poderes()

	if dopa >= 100.0:
		perder("Perdiste por dopamina: el celular te ganó")
	if vida <= 0.0:
		perder("Perdiste por vida: los zombis te alcanzaron")

	# los temporizadores cortos apagan el arrastre y la lentitud si la zona ya no los renueva
	if arrastre_t > 0.0:
		arrastre_t -= delta
		if arrastre_t <= 0.0:
			arrastre = Vector2.ZERO
	if lento_t > 0.0:
		lento_t -= delta
		if lento_t <= 0.0:
			mult_vel = 1.0

	velocity = dir * vel_act * mult_vel + empuje + arrastre
	empuje = empuje.move_toward(Vector2.ZERO, empuje_decae * delta)
	move_and_slide()   # respeta autos, basureros y muros aunque haya empuje

# Elige el cuadro del sprite, lo voltea hacia donde mira, lo pone rojo si lo golpean y suelta polvo
func animar(delta):
	# ¿le quitaron vida? (los zombis y el jefe se la restan directo a "vida")
	if vida < vida_ant - 0.02:
		dano_t = 0.16
		if dano_aviso_t <= 0.0:
			dano_aviso_t = 0.6
			Fx.destello(Color(1, 0.1, 0.1), 0.16, 0.25)
			Fx.temblor(3.0, 0.12)
			Fx.chispas(global_position + Vector2(0, -10), Color(1, 0.35, 0.35), 6, 130.0, 0.35, 4.0)
	vida_ant = vida
	dano_t = max(dano_t - delta, 0.0)
	dano_aviso_t = max(dano_aviso_t - delta, 0.0)

	t_racha = max(t_racha - delta, 0.0)
	if t_racha <= 0.0:
		racha = 0
	var camina = velocity.length() > 20.0
	anim_t += delta
	if camina:
		polvo_t -= delta
		if polvo_t <= 0.0:
			polvo_t = 0.16
			Fx.polvo(global_position + Vector2(-cara.x * 6.0, 30.0))
	if spr == null:
		return
	pose_golpe = max(pose_golpe - delta, 0.0)
	# ¿se acaba de abrir o cerrar el celular? -> la mano lo saca del bolsillo o lo guarda
	if cel_abierto != cel_antes:
		cel_antes = cel_abierto
		cel_trans = CEL_TRANS
		Fx.sonar("whoosh", 1.6 if cel_abierto else 1.3, -10.0)
	cel_trans = max(cel_trans - delta, 0.0)
	if pose_golpe > 0.0:
		# carga -> barrido -> impacto (se sostiene) -> remate. Con el celular abierto pega con la
		# otra mano mientras sigue mirando el celular (cuadros 26-29)
		var t = POSE_DURA - pose_golpe
		var base = 26 if cel_abierto else 10
		spr.frame = base + (0 if t < 0.05 else (1 if t < 0.09 else (2 if t < 0.22 else 3)))
	elif cel_trans > 0.0:
		# sacar: bolsillo (14) -> subiendo (15); guardar: al revés
		var mitad = cel_trans > CEL_TRANS / 2.0
		if cel_abierto:
			spr.frame = 14 if mitad else 15
		else:
			spr.frame = 15 if mitad else 14
	elif cel_abierto:
		# mirando el celular y haciendo scroll con el pulgar
		if camina:
			spr.frame = 20 + int(anim_t * 10.0) % 6
		else:
			spr.frame = 16 + int(anim_t * 6.0) % 4
	elif camina:
		spr.frame = 4 + int(anim_t * 12.0) % 6
	else:
		spr.frame = int(anim_t * 5.0) % 4
	if abs(cara.x) > 0.2:
		spr.flip_h = cara.x < 0.0
	# rojo si lo golpearon, azulado si tiene el celular abierto
	if dano_t > 0.0:
		spr.modulate = Color(1.0, 0.45, 0.45)
	elif cel_abierto:
		spr.modulate = Color(0.8, 0.9, 1.0)
	else:
		spr.modulate = Color(1, 1, 1)

# ---------------- XP y niveles ----------------

# Solo visual: en cada nivel el personaje se ve un poco más grande (nivel 10 = 30 % más)
func escala_nivel():
	return 1.0 + (nivel - 1) * 0.033

# La llama celular_suelo.gd al recoger un celular o unos audífonos.
# Lleva la racha: cada objeto seguido suena más agudo y cada 5 sale «¡RACHA xN!».
func recoger_objeto(puntos, pos):
	racha = racha + 1 if t_racha > 0.0 else 1
	t_racha = RACHA_SEG
	var tono = min(1.0 + 0.07 * (racha - 1), 2.0)
	var extra = ("  x%d" % racha) if racha >= 3 else ""
	if nivel >= XP_NIVELES.size():
		# nivel máximo: ya no hay XP, cura un poquito
		vida = min(vida + 2.0, vida_max)
		Fx.sonar("curar", tono)
		Fx.chispas(pos, Color(0.4, 1.0, 0.5), 10, 160.0, 0.4, 4.0)
		Fx.texto_flotante(pos + Vector2(0, -26), "+2 vida" + extra, Color(0.45, 1.0, 0.55), 18)
	else:
		Fx.sonar("recoger", tono)
		Fx.chispas(pos, Color(0.45, 0.95, 1.0), 10, 160.0, 0.4, 4.0)
		Fx.texto_flotante(pos + Vector2(0, -26), "+%d XP%s" % [puntos, extra], Color(0.45, 0.95, 1.0), 18 + min(racha, 10))
		ganar_xp(puntos)
	if racha % 5 == 0:
		Fx.sonar("combo", 1.0 + 0.05 * (racha / 5))
		Fx.texto_flotante(global_position + Vector2(0, -95), "¡RACHA x%d!" % racha, Color(1.0, 0.85, 0.2), 28)
		Fx.onda(global_position, 80.0, Color(1.0, 0.85, 0.3), 0.35)

# Al crecer, el sprite sube para que los pies sigan en el mismo sitio (así no "pisa" las cajas
# ni los sofás: lo que choca es el círculo de los pies, que no cambia)
func pies_nivel():
	return -36.0 * (escala_nivel() - 1.0)

func nivel_de(puntos):
	var n = 1
	for i in range(XP_NIVELES.size()):
		if puntos >= XP_NIVELES[i]:
			n = i + 1
	return n

# XP que falta / total del nivel actual (para la barra del HUD). En el nivel máximo queda llena.
func progreso_xp():
	if nivel >= XP_NIVELES.size():
		return 1.0
	var a = XP_NIVELES[nivel - 1]
	var b = XP_NIVELES[nivel]
	return float(xp - a) / float(b - a)

# Suma XP; si sube de nivel cambia la skin con un efecto grande
func ganar_xp(n):
	xp += n
	var nuevo = nivel_de(xp)
	if nuevo > nivel:
		nivel = nuevo
		if spr != null:
			spr.texture = HOJAS_NIVEL[nivel - 1]
			spr.position.y = pies_nivel()
			spr.scale = Vector2.ONE * escala_nivel() * 1.4
			create_tween().tween_property(spr, "scale", Vector2.ONE * escala_nivel(), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Fx.onda(global_position, 120.0, Color(0.4, 0.95, 1.0), 0.5)
		Fx.chispas(global_position, Color(1.0, 0.85, 0.3), 30, 260.0, 0.7, 6.0)
		Fx.destello(Color(0.6, 0.95, 1.0), 0.25, 0.3)
		Fx.temblor(5.0, 0.2)
		Fx.texto_flotante(global_position + Vector2(0, -80), "¡NIVEL %d! %s" % [nivel, NOMBRES_NIVEL[nivel - 1]], Color(0.5, 1.0, 1.0), 26)
		Fx.sonar("nivel")
		var hud = get_parent().get_node_or_null("HUD")
		if hud != null and hud.has_method("anunciar_nivel"):
			hud.anunciar_nivel(nivel, NOMBRES_NIVEL[nivel - 1])

# Empuja al jugador "desplaz" píxeles en total (si no choca con nada)
func empujar(desplaz):
	empuje = desplaz * 2.0 / EMPUJE_TIEMPO
	empuje_decae = empuje.length() / EMPUJE_TIEMPO

# ---------------- Power ups ----------------

# Recalcula lo que cambian los poderes (los demás efectos se leen de Poderes cuando se usan)
func aplicar_poderes():
	vida_max = Poderes.vida_max()
	radio_golpe = RADIO_GOLPE_BASE * Poderes.mult_radio()
	vel = VEL_BASE * Poderes.mult_vel()
	queue_redraw()

# Daño de esta cachetada a un jefe (la llaman los jefes cuando el golpe SÍ le entra).
# Palma Pesada sube el daño en fracciones: se acumulan y se cobra de a 1 entero, así 1,75 de
# promedio queda como 1, 2, 2, 2, 1, 2, 2, 2... y la vida de los jefes sigue siendo entera.
func dano_cachetada():
	dano_acum += Poderes.mult_dano()
	var n = int(dano_acum)
	dano_acum -= n
	return maxi(n, 1)

# Si subiste de nivel y todavía no elegiste el poder, abre el selector.
# Espera a que no haya pausa, muerte, victoria ni cambio de zona.
func revisar_poderes():
	if Poderes.eligiendo or Muerte.activa or Pausa.abierta:
		return
	if not get_tree().get_nodes_in_group("victoria").is_empty():
		return
	if get_parent().get("en_transicion"):
		return
	if Poderes.pendientes(nivel) <= 0:
		return
	var ofrecidos = Poderes.tres_opciones()
	if ofrecidos.is_empty():
		return
	var sel = preload("res://comun/jugador/selector_poderes.gd").new()
	sel.jug = self
	sel.opciones = ofrecidos
	get_parent().add_child(sel)

# La llama el selector cuando eliges una tarjeta
func poder_elegido(id):
	Poderes.subir(id)
	aplicar_poderes()
	if id == "pecho":
		vida = min(vida + Poderes.CURA_PECHO, vida_max)
		vida_prev = vida
	var color = Poderes.COLORES[id]
	Fx.sonar("combo", 1.3)
	Fx.onda(global_position, 120.0, Color(color.r, color.g, color.b, 0.85), 0.45)
	Fx.chispas(global_position, color, 18, 220.0, 0.5, 5.0)
	Fx.texto_flotante(global_position + Vector2(0, -85), "¡%s %d!" % [Poderes.NOMBRES[id], Poderes.cat(id)], color, 26)

# Fin de la partida: guarda el récord y muestra la pantalla de muerte (autoload Muerte).
# Ella congela el juego y deja elegir REINTENTAR (recarga la zona, los libres vuelven a los de
# la entrada) o MENÚ. Antes aquí se reiniciaba la zona de golpe, sin avisar.
func perder(razon):
	if Muerte.activa:
		return   # vida y dopamina pueden llegar a 0 en el mismo cuadro: se avisa una sola vez
	print(razon)
	Registro.xp_inicio = 0   # al perder, la XP y la skin vuelven al nivel 1
	Poderes.reiniciar()
	reg.guardar(libres)
	Muerte.mostrar(razon, libres)

# Cachetada: libera zombis, revienta burbujas/clones y le avisa a los jefes dónde pegó
func dar_cachetada():
	var centro = global_position + cara * desplaz   # el golpe se corre hacia donde mira
	pose_golpe = POSE_DURA  # el sprite hace la pose de cachetada
	Fx.sonar("whoosh", randf_range(0.9, 1.15), -4.0)
	golpe_t = GOLPE_DURA   # arranca la animación de la mano (se dibuja en _draw())
	queue_redraw()
	var pego = false   # true si la cachetada le dio a algo (para el sonido de «hice daño»)
	var tanda = 0      # cuántos zombis liberó este mismo golpe (para el combo)
	for z in get_tree().get_nodes_in_group("zombis"):
		if centro.distance_to(z.global_position) < radio_golpe:
			var dir_g = (z.global_position - centro).normalized()   # el celular sale hacia donde pegó
			pego = true
			var pos_z = z.global_position
			if z.golpear(dir_g):   # false = aguantó (zombi con audífonos: pide 2 cachetadas)
				ultimo_liberado = z.scene_file_path
				libres += 1
				tanda += 1
				Fx.texto_flotante(pos_z + Vector2(0, -34), "+1", Color(0.7, 1.0, 0.5))
				Fx.sonar("liberar", 1.0 + 0.1 * (tanda - 1))
	# burbujas y clones del jefe: se revientan sin sumar a libres
	for d in get_tree().get_nodes_in_group("destruibles"):
		if centro.distance_to(d.global_position) < radio_golpe:
			d.reventar()
			pego = true
			Fx.chispas(d.global_position, Color(1, 0.85, 0.4), 10, 200.0, 0.4, 5.0)
	# Karma Positivo: cada zombi liberado en este golpe te cura (hasta 5)
	if tanda > 0 and Poderes.cura_karma() > 0.0:
		var cura = Poderes.cura_karma() * mini(tanda, 5)
		vida = min(vida + cura, vida_max)
		Fx.texto_flotante(global_position + Vector2(0, -50), "+%s vida" % str(snappedf(cura, 0.1)), Color(0.45, 1.0, 0.55), 18)
	if tanda >= 3:
		Fx.texto_flotante(centro + Vector2(0, -70), "¡COMBO x%d!" % tanda, Color(1.0, 0.75, 0.2), 34)
		Fx.temblor(5.0 + tanda, 0.2)
		Fx.sonar("combo", 1.0 + 0.04 * tanda)
	if pego:
		Fx.temblor(3.5, 0.12)
		Fx.texto_flotante(centro + Vector2(cara.x * 20.0, -62), "¡PAF!", Color(1.0, 0.92, 0.35), 26)
		MusicaGlobal.sonar_golpe()   # sonido de «hice daño» (el del jefe lo pone musica_global.gd)
	# los corazones del jefe ya no se pueden bloquear con la cachetada
	# el jefe decide solo si el golpe lo alcanza (cuerpo o antena)
	for j in get_tree().get_nodes_in_group("jefe"):
		j.recibir_golpe(centro)

# Modelo del jugador dibujado por código (sin textura): cabeza con lentes, cuerpo azul y sombra.
# Para usar un PNG real, borra este _draw() y vuelve a mostrar el Sprite2D.
func _draw():
	# círculo suave que muestra dónde pega la cachetada (se corre hacia donde mira)
	draw_circle(cara * desplaz, radio_golpe, Color(1, 1, 1, 0.05))
	# sombra en el piso
	draw_set_transform(Vector2(0, 31), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if USAR_SPRITES:
		dibujar_cachetada()   # el cuerpo es el Sprite2D; aquí solo se dibuja la mano
		return
	# cuerpo azul con contorno blanco
	var cuerpo = StyleBoxFlat.new()
	cuerpo.bg_color = Color(0.23, 0.51, 0.96)
	cuerpo.border_color = Color(1, 1, 1)
	cuerpo.set_border_width_all(3)
	cuerpo.set_corner_radius_all(11)
	draw_style_box(cuerpo, Rect2(-16, -9, 32, 37))
	# cabeza con contorno blanco
	draw_circle(Vector2(0, -20), 18.0, Color(1, 1, 1))
	draw_circle(Vector2(0, -20), 15.5, Color(0.95, 0.76, 0.61))
	# lentes oscuros
	var lentes = StyleBoxFlat.new()
	lentes.bg_color = Color(0.13, 0.13, 0.13)
	lentes.set_corner_radius_all(3)
	draw_style_box(lentes, Rect2(-10, -24, 20, 7))
	dibujar_cachetada()

# Animación de la cachetada: la mano cruza rápido de un lado al otro del círculo del golpe.
# El círculo que se ilumina es EXACTAMENTE el área que hace daño (centro = cara * desplaz,
# radio = radio_golpe), así lo que se ve es lo mismo que lo que pega.
func dibujar_cachetada():
	if golpe_t <= 0.0:
		return
	var avance = 1.0 - golpe_t / GOLPE_DURA        # va de 0 (empieza) a 1 (termina)
	var centro = cara * desplaz                    # centro del área de daño
	var lado = cara.orthogonal()                   # dirección «de costado» respecto a donde mira
	var piel = Color(0.95, 0.76, 0.61)
	# 1) el área de daño se enciende y se va apagando
	draw_circle(centro, radio_golpe, Color(1, 1, 1, 0.22 * (1.0 - avance)))
	draw_arc(centro, radio_golpe, 0.0, TAU, 40, Color(1, 1, 1, 0.7 * (1.0 - avance)), 2.0)
	# 2) recorrido de la mano: cruza el círculo de un borde al otro, haciendo una curva hacia adelante
	var puntos = PackedVector2Array()
	var pasos = 10
	for i in range(pasos + 1):
		var f = avance * i / pasos                 # solo se dibuja hasta donde va la mano
		puntos.append(punto_cachetada(f, centro, lado))
	# 3) la estela: una raya blanca gruesa que sigue a la mano (se nota el movimiento rápido)
	if puntos.size() >= 2:
		draw_polyline(puntos, Color(1, 1, 1, 0.55), 14.0)
		draw_polyline(puntos, Color(1, 1, 1, 0.9), 4.0)
	if USAR_SPRITES:
		return   # el brazo y la mano ya los muestra el sprite (cuadros 10-13)
	# 4) el brazo y la mano abierta
	var mano = punto_cachetada(avance, centro, lado)
	draw_line(Vector2(0, 2), mano, Color(0.23, 0.51, 0.96), 9.0)   # manga azul, igual que el cuerpo
	draw_line(Vector2(0, 2), mano, Color(1, 1, 1), 2.0)
	draw_circle(mano, 11.0, Color(1, 1, 1))
	draw_circle(mano, 9.0, piel)
	# dedos: tres rayitas hacia adelante
	for d in [-0.5, 0.0, 0.5]:
		var punta = mano + (cara.rotated(d)) * 16.0
		draw_line(mano, punta, Color(1, 1, 1), 6.0)
		draw_line(mano, punta, piel, 4.0)

# Posición de la mano cuando la cachetada lleva una fracción "f" (0 a 1) del recorrido
func punto_cachetada(f, centro, lado):
	var costado = lerp(-radio_golpe * 0.85, radio_golpe * 0.85, f)   # de un borde al otro
	var adelante = sin(f * PI) * radio_golpe * 0.35                  # la curva: en el medio va más adelante
	return centro + lado * costado + cara * adelante
