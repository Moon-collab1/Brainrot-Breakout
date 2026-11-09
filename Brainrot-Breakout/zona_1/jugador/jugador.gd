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

func _ready():
	add_to_group("jugador")
	record = reg.leer()
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

	velocity = dir * vel_act + empuje
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
			z.liberar()
			libres += 1
	# los corazones del jefe ya no se pueden bloquear con la cachetada
	# el jefe decide solo si el golpe lo alcanza (cuerpo o antena)
	for j in get_tree().get_nodes_in_group("jefe"):
		j.recibir_golpe(global_position)
	await get_tree().create_timer(0.15).timeout
	$Golpe/Dibujo.visible = false
