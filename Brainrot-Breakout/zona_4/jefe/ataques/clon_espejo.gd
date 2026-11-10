extends Node2D

# Clon falso de «Clones de espejo». Se parece al Gemelo, vaga por la arena y quema al
# tocarlo, pero NO recibe daño de verdad: una cachetada lo desvanece.
# Grupo "destruibles": jugador.dar_cachetada() llama reventar() a los que estén al alcance.
# OJO: NO va en "franjas", así sobrevive cuando el jefe se aturde y el jugador tiene
# que elegir cuál de los tres es el real.
const ROBOT = preload("res://zona_4/jefe/robot.gd")
const RADIO = 50.0

var tono = Color(0.3, 0.9, 1.0)       # el jefe lo pone (cian o magenta)
var arena = Rect2(311, 170, 530, 320) # donde vaga (el jefe lo pone)
var vel = 70.0
var dano_seg = 10.0                    # vida por segundo al tocarlo
var duracion = 10.0
var t = 0.0
var destino = Vector2.ZERO

func _ready():
	add_to_group("destruibles")
	add_to_group("clones_espejo")
	elegir_destino()

func elegir_destino():
	destino = Vector2(randf_range(arena.position.x, arena.end.x), randf_range(arena.position.y, arena.end.y))

func _process(delta):
	t += delta
	if global_position.distance_to(destino) < 8.0:
		elegir_destino()
	global_position += (destino - global_position).normalized() * vel * delta
	var jug = get_parent().get_node("Jugador")
	if global_position.distance_to(jug.global_position) <= RADIO:
		jug.vida -= dano_seg * delta
	if t >= duracion:
		queue_free()
	queue_redraw()

# La llama jugador.dar_cachetada(): el clon se desvanece sin sumar a «Liberados»
func reventar():
	queue_free()

func _draw():
	ROBOT.dibujar(self, tono, 0.55, false)
