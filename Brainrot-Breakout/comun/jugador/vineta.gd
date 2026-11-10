extends CanvasLayer

# Viñeta del celular: con el celular abierto, lo que queda lejos del jugador se ve borroso.
# Va como hijo del Jugador, así que lee sus datos directamente.

const VEL_EFECTO = 3.0   # qué tan rápido aparece y desaparece (por segundo)

var rect: ColorRect
var mat: ShaderMaterial
var fuerza = 0.0
var jug

func _ready():
	layer = 0   # sobre el juego, pero debajo del HUD (capa 1) y de los controles táctiles (capa 5)
	jug = get_parent()
	mat = ShaderMaterial.new()
	mat.shader = load("res://vineta.gdshader")
	rect = ColorRect.new()
	rect.material = mat
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE   # que no bloquee los clics
	add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.visible = false

func _process(delta):
	var meta = 0.0
	if jug.cel_abierto:
		meta = 1.0
	fuerza = move_toward(fuerza, meta, VEL_EFECTO * delta)
	rect.visible = fuerza > 0.0
	if not rect.visible:
		return
	var vp = get_viewport()
	var tam = vp.get_visible_rect().size
	var p = vp.get_canvas_transform() * jug.global_position
	mat.set_shader_parameter("centro", p / tam)
	mat.set_shader_parameter("aspecto", tam.x / tam.y)
	mat.set_shader_parameter("fuerza", fuerza)
