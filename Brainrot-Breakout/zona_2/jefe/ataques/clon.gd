extends Area2D

# Clon de «Recomendado para ti»: copia del último enemigo liberado que vuela recto hacia el jugador.
# Grupos: "destruibles" (la cachetada lo revienta, sin sumar libres) y "proyectiles".
# Capa 8 (proyectiles), máscara 5 = jugador (1) + obstáculos (4).
# Los primeros GRACIA segundos solo detecta al jugador (máscara 1): al salir del borde del orbe
# puede quedar pegado a un sofá o a la pared de arriba y no debe reventar al nacer.
const GRACIA = 0.25
const MARGEN_FUERA = 150.0   # si se aleja tanto del mapa, se borra

var vel = Vector2.ZERO   # el jefe la pone (ángulo bloqueado * velocidad)
var dano = 10.0          # el jefe la pone
var empuje = 150.0       # píxeles de empujón (el jefe lo pone)
var t = 0.0
var con_obstaculos = false

func _ready():
	collision_mask = 1
	body_entered.connect(_al_tocar)

func _physics_process(delta):
	t += delta
	if not con_obstaculos and t >= GRACIA:
		con_obstaculos = true
		collision_mask = 5   # desde ahora los obstáculos y límites lo destruyen
	global_position += vel * delta
	var p = global_position
	if p.x < -MARGEN_FUERA or p.x > 1152 + MARGEN_FUERA or p.y < -MARGEN_FUERA or p.y > 648 + MARGEN_FUERA:
		queue_free()

# La llama jugador.dar_cachetada() (grupo "destruibles")
func reventar():
	queue_free()

func _al_tocar(body):
	if is_queued_for_deletion():
		return
	if body.is_in_group("jugador"):
		body.vida -= dano
		body.empujar(vel.normalized() * empuje)
		queue_free()
	else:
		queue_free()   # sofás, macetas y límites
