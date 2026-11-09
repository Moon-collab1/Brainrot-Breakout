extends CharacterBody2D

var vel = 300.0
var cel_abierto = false
var vida = 100.0
var dopa = 0.0

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

	vida = clamp(vida, 0.0, 100.0)
	dopa = clamp(dopa, 0.0, 100.0)

	if dopa >= 100.0:
		print("Perdiste por dopamina")
		get_tree().reload_current_scene()

	if vida <= 0.0:
		print("Perdiste por vida")
		get_tree().reload_current_scene()

	$Info.text = "Vida: " + str(int(vida)) + "  Dopamina: " + str(int(dopa))

	velocity = dir * vel_act
	move_and_slide()
