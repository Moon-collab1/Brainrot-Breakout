extends CanvasLayer

# HUD de la zona: solo lee datos del jugador y de la raíz, no tiene colisiones
@onready var jug = get_parent().get_node("Jugador")
@onready var barra_vida = $PanelVida/BarraVida
@onready var barra_dopa = $PanelVida/BarraDopa
@onready var texto_ola = $PanelZona/TextoOla
@onready var texto_libres = $PanelZona/TextoLibres
@onready var panel_jefe = $PanelJefe
@onready var barra_jefe = $PanelJefe/BarraJefe
@onready var banner = $Banner
@onready var pantalla_cel = $SlotCelular/Pantalla
@onready var estado_cel = $SlotCelular/Estado
@onready var flash = $Flash

func _process(_delta):
	barra_vida.value = jug.vida
	barra_dopa.value = jug.dopa

	var mejor = max(jug.record, jug.libres)
	texto_ola.text = "ZONA 1  ·  OLEADA " + str(get_parent().n_ola)
	texto_libres.text = "Liberados: " + str(jug.libres) + "   Récord: " + str(mejor)

	if jug.cel_abierto:
		pantalla_cel.color = Color(0.5, 0.85, 1.0)
		estado_cel.text = "ABIERTO"
	else:
		pantalla_cel.color = Color(0.08, 0.08, 0.1)
		estado_cel.text = "CERRADO"

# --- Funciones para el jefe (se conectan en las Partes 3 y 4) ---

func mostrar_jefe(visible_):
	panel_jefe.visible = visible_

# Se conecta a la señal vida_cambiada(valor, maximo) del jefe
func actualizar_jefe(valor, maximo):
	barra_jefe.max_value = maximo
	barra_jefe.value = valor

func mostrar_banner(visible_):
	banner.visible = visible_

# Pantalla blanca del Flash de selfie
func flash_blanco(seg):
	flash.visible = true
	var tw = create_tween()
	tw.tween_interval(seg)
	tw.tween_callback(func(): flash.visible = false)
