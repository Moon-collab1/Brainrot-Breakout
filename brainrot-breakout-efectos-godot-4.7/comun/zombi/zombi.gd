extends CharacterBody2D

# Zombi básico. Persigue al jugador en línea recta y le quita vida si está cerca.
# Va en el grupo "zombis": oleadas.gd cuenta cuántos quedan y jugador.gd los libera con la
# cachetada (liberar() lo borra y el jugador suma 1 a "libres"). Su modelo es un círculo verde
# con ojos dibujado por código (sin textura).
# Usa sprites animados (assets/sprites/zombi_0..4.png): todos enviciados con el celular.
# Para volver al dibujo por código: USAR_SPRITES = false
const RADIO = 20.0
const USAR_SPRITES = true
# Aspectos (todos van enviciados con el celular):
#   0 celular azul                         -> 1 cachetada
#   1 celular rosa + audífonos             -> 2 cachetadas (1.ª: se caen los audífonos y pasa a 4)
#   2 celular verde + gorra                -> 1 cachetada
#   3 celular verde + gorra + audífonos    -> 2 cachetadas (1.ª: se caen los audífonos y pasa a 2)
#   4 celular rosa (el 1 sin audífonos)    -> 1 cachetada
const HOJAS = [
	preload("res://assets/sprites/zombi_0.png"),
	preload("res://assets/sprites/zombi_1.png"),
	preload("res://assets/sprites/zombi_2.png"),
	preload("res://assets/sprites/zombi_3.png"),
	preload("res://assets/sprites/zombi_4.png"),
]
const COLOR_CEL = [0, 1, 2, 2, 1]        # color del celular de cada aspecto (celular_N.png)
const SIN_AUDIFONOS = [0, 4, 2, 2, 4]    # a qué aspecto pasa cuando se le caen los audífonos
const CON_AUDIFONOS = [false, true, false, true, false]
# Cuando lo liberas deja de mirar el celular: queda confundido (4 cuadros) y se desvanece
const HOJAS_LIBRE = [
	preload("res://assets/sprites/zombi_libre_0.png"),
	preload("res://assets/sprites/zombi_libre_1.png"),
	preload("res://assets/sprites/zombi_libre_2.png"),
]
const LIBRE_DE = [0, 1, 2, 2, 1]         # hoja de «liberado» de cada aspecto (la 2 tiene gorra)
# Lo que dice al liberarse: siempre sobre salir del vicio del celular
const FRASES = ["¡Liberado del vicio!", "¡Liberado del vicio!", "¡Liberado del vicio!", "¡Adiós, scroll infinito!", "¡Libre del celular!", "¡Chao, notificaciones!", "¡Volví a la vida real!"]

var vel_z = 100.0
var dano = 10.0
var spr: Sprite2D
var anim_t = 0.0
var variante = 0       # aspecto (ver HOJAS arriba)
var liberado = false   # true mientras hace su animación de «desperté»
var libre_t = 0.0
var empuje = Vector2.ZERO
var golpes = 1         # cachetadas que aguanta antes de soltar el celular
var aturdido = 0.0     # tiempo restante de «me pegaron pero sigo»

func _ready():
	add_to_group("zombis")
	queue_redraw()
	if USAR_SPRITES:
		spr = Sprite2D.new()
		poner_tipo(randi() % 4)   # sale uno de los 4 aspectos al azar (el 4 solo aparece al quitarle audífonos)
		spr.hframes = 6
		anim_t = randf() * 3.0   # para que no caminen todos al mismo paso
		spr.scale = Vector2(0.2, 0.2)   # aparece «inflándose»
		add_child(spr)
		var tw = create_tween()
		tw.tween_property(spr, "scale", Vector2(1.0, 1.0), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var forma = CircleShape2D.new()
	forma.radius = RADIO
	$CollisionShape2D.shape = forma

# Cambia el aspecto. Con audífonos aguanta 2 cachetadas, sin audífonos 1.
func poner_tipo(v):
	variante = v
	golpes = 2 if CON_AUDIFONOS[v] else 1
	if spr != null:
		spr.texture = HOJAS[v]

# La cachetada llama a esto. Devuelve true si el zombi quedó liberado (suma a «libres»).
# Si tiene audífonos, la 1.ª cachetada solo se los tumba: salen volando y quedan en el piso.
func golpear(dir_golpe = Vector2.ZERO):
	if liberado:
		return false
	golpes -= 1
	if golpes > 0:
		var dir = dir_golpe if dir_golpe != Vector2.ZERO else Vector2.RIGHT
		aturdido = 0.5
		global_position += dir.normalized() * 22.0
		Fx.soltar_audifonos(global_position + Vector2(0, -30), dir)
		Fx.sonar("audifonos", randf_range(0.95, 1.1))
		Fx.chispas(global_position + Vector2(0, -30), Color(1, 0.35, 0.45), 12, 200.0, 0.35, 5.0)
		Fx.texto_flotante(global_position + Vector2(0, -56), "¡Mis audífonos!", Color(1, 0.55, 0.65), 16)
		variante = SIN_AUDIFONOS[variante]
		if spr != null:
			spr.texture = HOJAS[variante]
			spr.modulate = Color(1.6, 0.7, 0.7)
			create_tween().tween_property(spr, "modulate", Color(1, 1, 1), 0.4)
		return false
	liberar(dir_golpe)
	return true

# dir_golpe = hacia dónde salió el golpe (el celular sale volando para allá)
func liberar(dir_golpe = Vector2.ZERO):
	if liberado:
		return
	Fx.liberado(global_position)
	if spr == null:
		queue_free()
		return
	liberado = true
	# ya no cuenta como zombi (oleadas.gd cuenta el grupo), no muerde y no choca
	remove_from_group("zombis")
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	var dir = dir_golpe if dir_golpe != Vector2.ZERO else Vector2.RIGHT
	empuje = dir.normalized() * 60.0
	# se le cae el celular y despierta
	Fx.soltar_celular(global_position + dir.normalized() * 14.0 + Vector2(0, -4), dir, COLOR_CEL[variante])
	spr.texture = HOJAS_LIBRE[LIBRE_DE[variante]]
	spr.hframes = 4
	spr.frame = 0
	spr.flip_h = dir.x < 0.0
	spr.scale = Vector2(1.0, 1.0)
	var tb = create_tween()   # saltito de sorpresa
	tb.tween_property(spr, "position:y", -12.0, 0.1).set_ease(Tween.EASE_OUT)
	tb.tween_property(spr, "position:y", 0.0, 0.1).set_ease(Tween.EASE_IN)
	var arriba = global_position + Vector2(0, -56)
	Fx.texto_flotante(arriba, FRASES[randi() % FRASES.size()], Color(0.75, 1.0, 0.6), 16)
	var tw = create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)

# Solo trabaja mientras está liberado: cambia de cuadro y retrocede un poco, aturdido
func _process(delta):
	if not liberado:
		return
	libre_t += delta
	spr.frame = int(libre_t * 5.0) % 4
	global_position += empuje * delta
	empuje = empuje.move_toward(Vector2.ZERO, 120.0 * delta)

# Camina hacia el jugador (se detiene a 45 px) y le hace daño continuo a menos de 55 px
func _physics_process(delta):
	var jug = get_parent().get_node("Jugador")
	var dist = position.distance_to(jug.position)
	var dir = (jug.position - position).normalized()

	aturdido = max(0.0, aturdido - delta)
	if aturdido > 0.0:
		velocity = Vector2.ZERO   # tras un golpe que aguantó se queda quieto un momento
	elif dist > 45:
		velocity = dir * vel_z
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	if dist < 55 and aturdido <= 0.0:
		jug.vida -= dano * delta

	if spr != null:
		anim_t += delta * (1.4 if dist < 55 else 1.0)
		spr.frame = int(anim_t * 8.0) % 6
		if abs(dir.x) > 0.15:
			spr.flip_h = dir.x < 0.0

func _draw():
	if USAR_SPRITES:
		# solo la sombra: el cuerpo es el Sprite2D
		draw_set_transform(Vector2(0, 31), 0.0, Vector2(1.2, 0.34))
		draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	# Dibujo un poco más grande que el modelo base para que cubra la colisión (radio 20)
	var esc = Vector2(1.2, 1.2)
	var verde = Color(0.494, 0.851, 0.341)
	var verde_osc = Color(0.16, 0.43, 0.16)
	# sombra en el piso
	draw_set_transform(Vector2(0, 31), 0.0, Vector2(esc.x, esc.y * 0.28))
	draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, esc)
	# cuerpo (ropa gris azulada)
	var ropa = StyleBoxFlat.new()
	ropa.bg_color = Color(0.333, 0.353, 0.467)
	ropa.set_corner_radius_all(8)
	draw_style_box(ropa, Rect2(-13, -5, 26, 28))
	# cabeza verde con contorno oscuro
	draw_circle(Vector2(0, -15), 15.0, verde_osc)
	draw_circle(Vector2(0, -15), 13.0, verde)
	# ojos con pupila
	draw_circle(Vector2(-5, -14), 3.2, Color(1, 1, 1))
	draw_circle(Vector2(5, -14), 3.2, Color(1, 1, 1))
	draw_circle(Vector2(-5, -14), 1.4, Color(0, 0, 0))
	draw_circle(Vector2(5, -14), 1.4, Color(0, 0, 0))
	# cejas fruncidas
	draw_arc(Vector2(-4.5, -19), 4.5, deg_to_rad(200), deg_to_rad(340), 8, verde_osc, 1.6)
	draw_arc(Vector2(4.5, -19), 4.5, deg_to_rad(200), deg_to_rad(340), 8, verde_osc, 1.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
