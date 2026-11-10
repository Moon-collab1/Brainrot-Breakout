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

func _ready():
	add_to_group("jugador")
	record = reg.leer()
	libres = Registro.libres_inicio   # los libres con que se entró a la zona
	$Sprite2D.scale = Vector2(ESCALA, ESCALA)
	var forma = CircleShape2D.new()
	forma.radius = RADIO
	$CollisionShape2D.shape = forma

func _physics_process(delta):
	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if Input.is_action_just_pressed("ui_accept"):
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
	$Golpe/Dibujo.visible = true
	for z in get_tree().get_nodes_in_group("zombis"):
		if global_position.distance_to(z.global_position) < alcance:
			ultimo_liberado = z.scene_file_path
			z.liberar()
			libres += 1
	# burbujas y clones del jefe: se revientan sin sumar a libres
	for d in get_tree().get_nodes_in_group("destruibles"):
		if global_position.distance_to(d.global_position) < alcance:
			d.reventar()
	# los corazones del jefe ya no se pueden bloquear con la cachetada
	# el jefe decide solo si el golpe lo alcanza (cuerpo o antena)
	for j in get_tree().get_nodes_in_group("jefe"):
		j.recibir_golpe(global_position)
	await get_tree().create_timer(0.15).timeout
	$Golpe/Dibujo.visible = false
