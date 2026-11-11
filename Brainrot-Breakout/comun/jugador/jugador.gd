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
const GOLPE_DURA = 0.18      # segundos que dura la animación de la cachetada (la mano cruzando)
const EMPUJE_TIEMPO = 0.25   # lo que dura el empujón del Pulso del jefe

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
var golpe_t = 0.0          # tiempo que le queda a la animación de la cachetada (0 = no está pegando)

# Prepara al jugador: lee el récord, recupera los libres con que llegó y crea la viñeta
func _ready():
	add_to_group("jugador")
	record = reg.leer()
	libres = Registro.libres_inicio   # los libres con que se entró a la zona
	$Sprite2D.scale = Vector2(ESCALA, ESCALA)
	$Sprite2D.visible = false   # ahora el jugador se dibuja en _draw() (ver abajo)
	var forma = CircleShape2D.new()
	forma.radius = RADIO
	$CollisionShape2D.shape = forma
	$Golpe/Dibujo.visible = false   # ya no se usa el logo de Godot: la cachetada se dibuja en _draw()
	add_child(preload("res://comun/jugador/vineta.gd").new())   # la viñeta del celular


# Cada frame de física: lee la entrada, aplica celular/cachetada, revisa si perdió y se mueve
func _physics_process(delta):
	Registro.tiempo += delta
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
		vida += 5 * delta
		dopa += 8 * delta
	else:
		dopa -= 2 * delta

	# animación de la cachetada: mientras dure, se redibuja cada frame para mover la mano
	if golpe_t > 0.0:
		golpe_t = max(golpe_t - delta, 0.0)
		queue_redraw()

	enfria -= delta
	if Input.is_action_just_pressed("cachetada") and enfria <= 0.0:
		enfria = 0.4
		dar_cachetada()

	vida = clamp(vida, 0.0, 100.0)
	dopa = clamp(dopa, 0.0, 100.0)

	if dopa >= 100.0:
		perder("Perdiste por dopamina")
	if vida <= 0.0:
		perder("Perdiste por vida")

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

# Empuja al jugador "desplaz" píxeles en total (si no choca con nada)
func empujar(desplaz):
	empuje = desplaz * 2.0 / EMPUJE_TIEMPO
	empuje_decae = empuje.length() / EMPUJE_TIEMPO

# Fin de la partida: guarda el récord y reinicia la zona (los libres vuelven a los de la entrada)
func perder(razon):
	print(razon)
	reg.guardar(libres)
	get_tree().reload_current_scene()

# Cachetada: libera zombis, revienta burbujas/clones y le avisa a los jefes dónde pegó
func dar_cachetada():
	var centro = global_position + cara * desplaz   # el golpe se corre hacia donde mira
	golpe_t = GOLPE_DURA   # arranca la animación de la mano (se dibuja en _draw())
	queue_redraw()
	var pego = false   # true si la cachetada le dio a algo (para el sonido de «hice daño»)
	for z in get_tree().get_nodes_in_group("zombis"):
		if centro.distance_to(z.global_position) < radio_golpe:
			ultimo_liberado = z.scene_file_path
			z.liberar()
			libres += 1
			pego = true
	# burbujas y clones del jefe: se revientan sin sumar a libres
	for d in get_tree().get_nodes_in_group("destruibles"):
		if centro.distance_to(d.global_position) < radio_golpe:
			d.reventar()
			pego = true
	if pego:
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
