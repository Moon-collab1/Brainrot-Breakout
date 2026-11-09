extends CharacterBody2D

var vel = 300.0
var cel_abierto = false
var vida = 100.0
var dopa = 0.0
var enfria = 0.0
var libres = 0

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
		print("Perdiste por dopamina")
		get_tree().reload_current_scene()

	if vida <= 0.0:
		print("Perdiste por vida")
		get_tree().reload_current_scene()

	$Info.text = "Vida: " + str(int(vida)) + "  Dopamina: " + str(int(dopa)) + "  Liberados: " + str(libres)

	velocity = dir * vel_act
	move_and_slide()

func dar_cachetada():
	$Golpe/Dibujo.visible = true
	for cuerpo in $Golpe.get_overlapping_bodies():
		if cuerpo.is_in_group("zombis"):
			cuerpo.liberar()
			libres += 1
	await get_tree().create_timer(0.15).timeout
	$Golpe/Dibujo.visible = false
