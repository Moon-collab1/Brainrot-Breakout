extends Node2D

# El celular que se le cae a un zombi cuando lo liberas con la cachetada (lo crea Fx.soltar_celular).
# Sale volando en la dirección del golpe girando, rebota, queda con la pantalla rota en el piso
# unos segundos (parpadea antes de desaparecer). Si el jugador pasa por encima lo RECOGE y gana XP.
# Sprite: assets/sprites/celular_N.png (cuadro 0 intacto, 1 roto brillante, 2 roto apagado).
const HOJAS = [
	preload("res://assets/sprites/celular_0.png"),
	preload("res://assets/sprites/celular_1.png"),
	preload("res://assets/sprites/celular_2.png"),
]
const AUDIFONOS = preload("res://assets/sprites/audifonos.png")
const COLORES = [Color(0.47, 0.86, 1.0), Color(1.0, 0.47, 0.78), Color(0.75, 1.0, 0.43)]
const DURA_SUELO = 7.0      # segundos que se queda en el piso
const XP_CELULAR = 5        # XP al recoger un celular
const XP_AUDIFONOS = 3      # XP al recoger unos audífonos
const IMAN = 80.0           # a esta distancia el objeto se va solo hacia el jugador
const RECOGE = 26.0         # a esta distancia se recoge
const VUELO = 0.42          # segundos que dura el vuelo
const ALTO_VUELO = 70.0     # altura máxima del arco (px)

var spr: Sprite2D
var variante = 0
var en_suelo = false
var t_suelo = 0.0
var inicio = Vector2.ZERO
var destino = Vector2.ZERO
var giro = 0.0
var es_audifono = false   # true = son los audífonos que se le caen al zombi con la 1.ª cachetada

# pos = dónde estaba el zombi, direccion = hacia dónde salió el golpe, v = color del celular
func iniciar(pos, direccion, v, audifono = false):
	es_audifono = audifono
	variante = v % 3
	inicio = pos
	position = pos
	var d = direccion.normalized().rotated(randf_range(-0.5, 0.5))
	destino = pos + d * randf_range(70.0, 120.0)
	destino.x = clamp(destino.x, 30.0, 1120.0)
	destino.y = clamp(destino.y, 135.0, 615.0)
	giro = TAU * randf_range(1.5, 2.5) * (1.0 if d.x >= 0.0 else -1.0)
	spr = Sprite2D.new()
	if es_audifono:
		spr.texture = AUDIFONOS
		spr.hframes = 1
	else:
		spr.texture = HOJAS[variante]
		spr.hframes = 3
	spr.frame = 0
	add_child(spr)
	z_index = 60   # por encima de todo mientras vuela
	var tw = create_tween()
	tw.tween_method(volar, 0.0, 1.0, VUELO)
	tw.tween_callback(aterrizar)

# u va de 0 a 1: avanza en línea recta y sube y baja formando un arco
func volar(u):
	position = inicio.lerp(destino, u) + Vector2(0, -ALTO_VUELO * 4.0 * u * (1.0 - u))
	spr.rotation = giro * u

func aterrizar():
	position = destino
	z_index = 0
	spr.rotation = deg_to_rad(randf_range(-40.0, 40.0))
	if not es_audifono:
		spr.frame = 1
	en_suelo = true
	queue_redraw()
	# pantallazo de cristales al caer
	if es_audifono:
		Fx.chispas(position, Color(1, 0.35, 0.45), 6, 80.0, 0.35, 4.0, 100.0)
	else:
		Fx.chispas(position, Color(1, 1, 1, 0.9), 8, 110.0, 0.35, 3.0, 200.0)
		Fx.chispas(position, COLORES[variante], 6, 90.0, 0.4, 5.0, 100.0)
	# rebotecito
	var tw = create_tween()
	tw.tween_property(spr, "position:y", -10.0, 0.08).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "position:y", 0.0, 0.08).set_ease(Tween.EASE_IN)

func _process(delta):
	if not en_suelo:
		return
	t_suelo += delta
	# la pantalla rota parpadea (cuadro 1 = brillante, 2 = apagado)
	if not es_audifono:
		spr.frame = 1 if int(t_suelo * 3.0) % 3 != 2 else 2
	var resta = DURA_SUELO - t_suelo
	if resta < 1.6:
		modulate.a = 0.35 + 0.65 * (1.0 if int(t_suelo * 10.0) % 2 == 0 else 0.0)   # parpadea antes de irse
	if resta <= 0.0:
		queue_free()
		return
	# imán: si el jugador pasa cerca, el objeto vuela hacia él; al tocarlo se recoge (XP)
	var jug = get_tree().get_first_node_in_group("jugador")
	if jug == null:
		return
	var dist = jug.global_position.distance_to(global_position)
	if dist < IMAN:
		global_position = global_position.move_toward(jug.global_position, (420.0 - dist * 3.0) * delta)
	if dist < RECOGE:
		var puntos = XP_AUDIFONOS if es_audifono else XP_CELULAR
		if jug.has_method("recoger_objeto"):
			jug.recoger_objeto(puntos, global_position)   # XP (o vida en nivel 12), racha y sonido
		queue_free()

func _draw():
	if en_suelo:
		# sombrita bajo el celular tirado
		draw_set_transform(Vector2(0, 14), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.28))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# brillo de la pantalla sobre el piso
		if es_audifono:
			return
		draw_circle(Vector2.ZERO, 20.0, Color(COLORES[variante].r, COLORES[variante].g, COLORES[variante].b, 0.12))
