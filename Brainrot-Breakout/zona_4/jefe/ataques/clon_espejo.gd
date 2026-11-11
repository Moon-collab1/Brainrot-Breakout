extends Node2D

# Clon falso de «Clones de espejo». Se parece al Gemelo, PERSIGUE al jugador y quema al
# tocarlo, pero NO recibe daño de verdad: una cachetada lo desvanece.
# Grupo "destruibles": jugador.dar_cachetada() llama reventar() a los que estén al alcance.
# OJO: NO va en "franjas", así sobrevive cuando el jefe se aturde y el jugador tiene
# que elegir cuál de los tres es el real.
const ROBOT = preload("res://zona_4/jefe/robot.gd")
const RADIO = 50.0

var tono = Color(0.3, 0.95, 1.0)      # el jefe lo pone (todos los clones usan el mismo color)
var arena = Rect2(311, 170, 530, 320) # de dónde no puede salirse (el jefe lo pone)
var vel = 130.0                        # velocidad con la que persigue (el jefe lo pone)
var dano_seg = 10.0                    # vida por segundo al tocarlo
var duracion = 10.0
var t = 0.0

func _ready():
	add_to_group("destruibles")
	add_to_group("clones_espejo")

func _process(delta):
	t += delta
	# Persigue al jugador en línea recta (como un zombi), sin salirse del ascensor
	var jug = get_parent().get_node("Jugador")
	var hacia = jug.global_position - global_position
	if hacia.length() > 20.0:
		global_position += hacia.normalized() * vel * delta
		global_position.x = clamp(global_position.x, arena.position.x, arena.end.x)
		global_position.y = clamp(global_position.y, arena.position.y, arena.end.y)
	# quema mientras toca al jugador
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
