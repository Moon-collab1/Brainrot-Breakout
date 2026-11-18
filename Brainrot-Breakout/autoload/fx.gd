extends Node

# Efectos visuales del juego (autoload "Fx", así no se confunde con el bus de audio "Efectos"). Cualquier script los llama así:
#   Fx.temblor(4.0, 0.15)             -> la pantalla tiembla (fuerza en px, duración en s)
#   Fx.pausa_impacto(0.06)            -> congela el juego un instante al pegar fuerte
#   Fx.chispas(pos, Color.RED, 14)    -> ráfaga de partículas
#   Fx.texto_flotante(pos, "+1")      -> número que sube y se desvanece
#   Fx.onda(pos, 60.0, Color.WHITE)   -> anillo que se expande
#   Fx.destello(Color(1,0,0), 0.2)    -> parpadeo de color en toda la pantalla
#   Fx.polvo(pos)                     -> nubecita de polvo al caminar
#   Fx.liberado(pos)                  -> combinación para cuando se libera un zombi
#   Fx.explosion(pos, color)          -> explosión grande (muerte de un jefe)
#   Fx.ambiente(zona, n)              -> partículas flotando según la zona
# Todo se crea por código (sin imágenes) y se borra solo, así funciona igual en la web.

var tex_punto: GradientTexture2D     # puntito suave que usan todas las partículas
var rampa: Gradient                  # hace que las partículas se desvanezcan al final
var capa: CanvasLayer
var velo: ColorRect                  # pantalla de color para los destellos
var tw_velo: Tween

var temblor_t = 0.0
var temblor_dur = 0.001
var temblor_f = 0.0
var congelado = false

# Anillo que crece y se desvanece (clase interna: no necesita archivo aparte)
class Anillo extends Node2D:
	var radio = 40.0
	var color = Color.WHITE
	var avance = 0.0    # 0 al empezar, 1 al terminar (lo anima un Tween)
	func _draw():
		var r = radio * (0.35 + 0.65 * avance)
		var c = Color(color.r, color.g, color.b, color.a * (1.0 - avance))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, c, 5.0 * (1.0 - avance) + 1.0)
	func _process(_d):
		queue_redraw()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	tex_punto = GradientTexture2D.new()
	tex_punto.fill = GradientTexture2D.FILL_RADIAL
	tex_punto.fill_from = Vector2(0.5, 0.5)
	tex_punto.fill_to = Vector2(1.0, 0.5)
	tex_punto.width = 16
	tex_punto.height = 16
	var g = Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	tex_punto.gradient = g
	rampa = Gradient.new()
	rampa.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.0)])
	rampa.offsets = PackedFloat32Array([0.35, 1.0])
	# capa 90: sobre el HUD (1) y bajo la pausa (100) y la pantalla de muerte (110)
	capa = CanvasLayer.new()
	capa.layer = 90
	add_child(capa)
	velo = ColorRect.new()
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	velo.color = Color(1, 1, 1, 0)
	capa.add_child(velo)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# La escena donde se dibujan los efectos (la zona actual)
func escena():
	return get_tree().current_scene

func _process(delta):
	if temblor_t > 0.0:
		temblor_t -= delta
		var k = clamp(temblor_t / temblor_dur, 0.0, 1.0)
		var d = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * temblor_f * k
		if temblor_t <= 0.0:
			d = Vector2.ZERO
			temblor_f = 0.0
		_mover_vista(d)

# La Zona 4 tiene Camera2D (se mueve su offset); las demás: se mueve la zona completa.
# El HUD es un CanvasLayer, así que no tiembla.
func _mover_vista(d):
	var e = escena()
	if e == null:
		return
	var cam = e.get_node_or_null("Camara")
	if cam is Camera2D:
		cam.offset = d
	elif e is Node2D:
		e.position = d

func temblor(fuerza = 4.0, dur = 0.15):
	if fuerza >= temblor_f * clamp(temblor_t / temblor_dur, 0.0, 1.0):
		temblor_f = fuerza
		temblor_dur = max(dur, 0.01)
		temblor_t = dur

# Congela el juego unos instantes (se siente más fuerte el golpe)
func pausa_impacto(dur = 0.06, escala = 0.05):
	if congelado or get_tree().paused:
		return
	congelado = true
	Engine.time_scale = escala
	await get_tree().create_timer(dur, true, false, true).timeout   # ignora el time_scale
	Engine.time_scale = 1.0
	congelado = false

func destello(color = Color(1, 1, 1), alfa = 0.25, dur = 0.18):
	if tw_velo:
		tw_velo.kill()
	velo.color = Color(color.r, color.g, color.b, alfa)
	tw_velo = create_tween()
	tw_velo.tween_property(velo, "color:a", 0.0, dur)

func chispas(pos, color = Color(1, 1, 1), cantidad = 14, vel = 180.0, vida = 0.5, tam = 5.0, gravedad = 320.0):
	var e = escena()
	if e == null:
		return
	var p = CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = cantidad
	p.lifetime = vida
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = vel * 0.35
	p.initial_velocity_max = vel
	p.gravity = Vector2(0, gravedad)
	p.texture = tex_punto
	p.scale_amount_min = tam / 16.0 * 0.5
	p.scale_amount_max = tam / 16.0 * 1.4
	p.color = color
	p.color_ramp = rampa
	p.z_index = 100
	p.global_position = pos
	e.add_child(p)
	p.emitting = true
	get_tree().create_timer(vida + 0.3).timeout.connect(p.queue_free)

func onda(pos, radio = 60.0, color = Color(1, 1, 1, 0.8), dur = 0.3):
	var e = escena()
	if e == null:
		return
	var a = Anillo.new()
	a.radio = radio
	a.color = color
	a.z_index = 99
	a.global_position = pos
	e.add_child(a)
	var tw = a.create_tween()
	tw.tween_property(a, "avance", 1.0, dur).set_ease(Tween.EASE_OUT)
	tw.tween_callback(a.queue_free)

func texto_flotante(pos, texto, color = Color(1, 1, 1), tam = 26):
	var e = escena()
	if e == null:
		return
	var l = Label.new()
	l.text = texto
	l.size = Vector2(160, 40)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.z_index = 200
	l.global_position = pos - Vector2(80, 30)
	l.pivot_offset = Vector2(80, 20)
	l.scale = Vector2(0.4, 0.4)
	e.add_child(l)
	var tw = l.create_tween()
	tw.tween_property(l, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector2.ONE, 0.08)
	tw.parallel().tween_property(l, "position:y", l.position.y - 46.0, 0.7).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tw.tween_callback(l.queue_free)

# El celular que se le cae a un zombi al liberarlo (ver comun/zombi/celular_suelo.gd)
# ---------------- Sonidos cortos (bus "Efectos") ----------------
# Fx.sonar("recoger", tono, volumen_db). Usa varios reproductores para que se puedan pisar.
const SONIDOS = {
	"recoger": preload("res://assets/audio/fx/recoger.wav"),
	"nivel": preload("res://assets/audio/fx/nivel.wav"),
	"liberar": preload("res://assets/audio/fx/liberar.wav"),
	"audifonos": preload("res://assets/audio/fx/audifonos.wav"),
	"crash": preload("res://assets/audio/fx/crash.wav"),
	"whoosh": preload("res://assets/audio/fx/whoosh.wav"),
	"combo": preload("res://assets/audio/fx/combo.wav"),
	"alarma": preload("res://assets/audio/fx/alarma.wav"),
	"curar": preload("res://assets/audio/fx/curar.wav"),
	# jefes
	"jefe_aparece": preload("res://assets/audio/fx/jefe_aparece.wav"),
	"aviso": preload("res://assets/audio/fx/aviso.wav"),
	"aturdido": preload("res://assets/audio/fx/aturdido.wav"),
	"fase2": preload("res://assets/audio/fx/fase2.wav"),
	"jefe_muere": preload("res://assets/audio/fx/jefe_muere.wav"),
	"impacto": preload("res://assets/audio/fx/impacto.wav"),
	"camara": preload("res://assets/audio/fx/camara.wav"),
	"zap": preload("res://assets/audio/fx/zap.wav"),
	"perla": preload("res://assets/audio/fx/perla.wav"),
}
var reproductores = []
var sig_rep = 0

func sonar(nombre, tono = 1.0, volumen_db = 0.0):
	if not SONIDOS.has(nombre):
		return
	if reproductores.is_empty():
		for i in range(10):
			var r = AudioStreamPlayer.new()
			r.bus = "Efectos" if AudioServer.get_bus_index("Efectos") != -1 else "Master"
			r.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(r)
			reproductores.append(r)
	var r = reproductores[sig_rep]
	sig_rep = (sig_rep + 1) % reproductores.size()
	r.stream = SONIDOS[nombre]
	r.pitch_scale = tono
	r.volume_db = volumen_db
	r.play()

func soltar_celular(pos, direccion, variante):
	var e = escena()
	if e == null:
		return
	var c = preload("res://comun/zombi/celular_suelo.gd").new()
	e.add_child(c)
	var mapa = e.get_node_or_null("Mapa")
	if mapa:
		e.move_child(c, mapa.get_index() + 1)   # sobre el piso pero debajo de los personajes
	c.iniciar(pos, direccion, variante)

# Igual que soltar_celular pero con los audífonos rojos (1.ª cachetada al zombi con audífonos)
func soltar_audifonos(pos, direccion):
	var e = escena()
	if e == null:
		return
	var c = preload("res://comun/zombi/celular_suelo.gd").new()
	e.add_child(c)
	var mapa = e.get_node_or_null("Mapa")
	if mapa:
		e.move_child(c, mapa.get_index() + 1)
	c.iniciar(pos, direccion, 0, true)

func polvo(pos):
	chispas(pos, Color(0.85, 0.85, 0.9, 0.55), 4, 40.0, 0.4, 7.0, -30.0)

# Un zombi liberado: destello verde, anillo y estrellitas hacia arriba
func liberado(pos):
	chispas(pos + Vector2(0, -10), Color(0.55, 1.0, 0.45), 14, 220.0, 0.55, 6.0)
	chispas(pos + Vector2(0, -10), Color(1.0, 1.0, 0.7), 6, 140.0, 0.45, 5.0, 100.0)
	onda(pos, 48.0, Color(0.6, 1.0, 0.5, 0.9), 0.28)

# Golpe a un jefe: chispas del color del jefe, temblor y pausa (sin número de daño)
func impacto_jefe(pos, _dano, color = Color(1, 0.9, 0.5)):
	sonar("impacto", randf_range(0.9, 1.1))
	chispas(pos, color, 22, 280.0, 0.6, 6.0)
	onda(pos, 90.0, Color(1, 1, 1, 0.85), 0.35)
	temblor(7.0, 0.25)
	destello(Color(1, 1, 1), 0.12, 0.12)
	pausa_impacto(0.06)

# Muerte del jefe: explosión larga con varios anillos y el juego en cámara lenta
func explosion(pos, color = Color(1, 0.8, 0.3)):
	sonar("jefe_muere")
	for i in range(4):
		var off = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		get_tree().create_timer(0.12 * i).timeout.connect(func():
			chispas(pos + off, color, 26, 340.0, 0.8, 8.0)
			onda(pos + off, 110.0 + 25.0 * i, Color(1, 1, 1, 0.9), 0.5))
	temblor(14.0, 0.8)
	destello(Color(1, 1, 1), 0.55, 0.6)
	pausa_impacto(0.3, 0.2)

# Partículas flotando por toda la zona (polvo, chispas, datos...). Cada zona tiene su color.
const AMBIENTE = {
	1: {"color": Color(1.0, 0.95, 0.75, 0.35), "sube": 1, "cant": 28},
	2: {"color": Color(1.0, 0.45, 0.85, 0.35), "sube": 1, "cant": 36},
	3: {"color": Color(1.0, 0.65, 0.25, 0.45), "sube": 1, "cant": 30},
	4: {"color": Color(0.85, 0.9, 1.0, 0.28), "sube": 0, "cant": 24},
	5: {"color": Color(0.8, 0.45, 1.0, 0.4), "sube": 1, "cant": 40},
	6: {"color": Color(0.3, 0.95, 1.0, 0.45), "sube": 0, "cant": 44},
}
func ambiente(zona, numero):
	var cfg = AMBIENTE.get(numero, AMBIENTE[1])
	var p = CPUParticles2D.new()
	p.amount = cfg["cant"]
	p.lifetime = 7.0
	p.preprocess = 7.0   # ya hay partículas desde el primer cuadro
	p.texture = tex_punto
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(576, 324)
	p.position = Vector2(576, 324)
	p.direction = Vector2(0.2, -1.0 if cfg["sube"] == 1 else 0.0)
	p.spread = 70.0
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 22.0
	p.scale_amount_min = 0.15
	p.scale_amount_max = 0.5
	p.color = cfg["color"]
	var r = Gradient.new()
	r.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	r.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	p.color_ramp = r
	p.z_index = 40
	zona.add_child(p)
