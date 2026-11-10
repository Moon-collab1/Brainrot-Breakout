extends CharacterBody2D

# Valores visuales/colisión (para revertir: ESCALA = 1.0, RADIO = 10.0)
const ESCALA = 0.4
const RADIO = 20.0
const EMPUJE_TIEMPO = 0.25   # lo que dura el empujón del Pulso del jefe

var vel = 300.0
var cel_abierto = false
var vida = 100.0
var dopa = 0.0
var enfria = 0.0
var libres = 0
var alcance = 100.0
var cara = Vector2.RIGHT    # NUEVO: hacia dónde mira (última dirección en que se movió)
var desplaz = 45.0          # NUEVO: cuánto se corre el golpe hacia donde mira
var radio_golpe = 70.0      # NUEVO: tamaño del círculo del golpe
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

func _ready():
	add_to_group("jugador")
	record = reg.leer()
	libres = Registro.libres_inicio   # los libres con que se entró a la zona
	$Sprite2D.scale = Vector2(ESCALA, ESCALA)
	$Sprite2D.visible = false   # ahora el jugador se dibuja en _draw() (ver abajo)
	var forma = CircleShape2D.new()
	forma.radius = RADIO
	$CollisionShape2D.shape = forma
	$Golpe/Dibujo.scale = Vector2.ONE * (radio_golpe * 2.0 / 128.0)   # NUEVO: el destello mide lo mismo que el golpe
	add_child(preload("res://comun/jugador/vineta.gd").new())   # NUEVO: la viñeta del celular


func _physics_process(delta):
	Registro.tiempo += delta
	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Control invertido: las direcciones quedan al revés mientras dure
	if invertido_t > 0.0:
		invertido_t -= delta
		dir = -dir

	# NUEVO: guardar hacia dónde mira (si está quieto, se queda la última dirección)
	if dir != Vector2.ZERO and dir.normalized() != cara:
		cara = dir.normalized()
		queue_redraw()

	# Apagón del celular: mientras dure, el celular se cierra y no se puede abrir
	if cel_bloqueado_t > 0.0:
		cel_bloqueado_t -= delta
		cel_abierto = false
	elif Input.is_action_just_pressed("ui_accept"):
		cel_abierto = not cel_abierto

	var vel_act = vel
	if cel_abierto:
		vel_act = vel * 0.6
		vida += 5 * delta
		dopa += 8 * delta
	else:
		dopa -= 2 * delta

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

func perder(razon):
	print(razon)
	reg.guardar(libres)
	get_tree().reload_current_scene()

func dar_cachetada():
	var centro = global_position + cara * desplaz   # NUEVO: el golpe se corre hacia donde mira
	$Golpe.position = cara * desplaz
	$Golpe/Dibujo.visible = true
	for z in get_tree().get_nodes_in_group("zombis"):
		if centro.distance_to(z.global_position) < radio_golpe:
			ultimo_liberado = z.scene_file_path
			z.liberar()
			libres += 1
	# burbujas y clones del jefe: se revientan sin sumar a libres
	for d in get_tree().get_nodes_in_group("destruibles"):
		if centro.distance_to(d.global_position) < radio_golpe:
			d.reventar()
	# los corazones del jefe ya no se pueden bloquear con la cachetada
	# el jefe decide solo si el golpe lo alcanza (cuerpo o antena)
	for j in get_tree().get_nodes_in_group("jefe"):
		j.recibir_golpe(centro)
	await get_tree().create_timer(0.15).timeout
	$Golpe/Dibujo.visible = false

# Modelo del jugador dibujado por código (sin textura): cabeza con lentes, cuerpo azul y sombra.
# Para usar un PNG real, borra este _draw() y vuelve a mostrar el Sprite2D.
func _draw():
	# NUEVO: círculo suave que muestra dónde pega la cachetada (se corre hacia donde mira)
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
