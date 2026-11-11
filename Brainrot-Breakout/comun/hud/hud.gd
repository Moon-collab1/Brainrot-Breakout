extends CanvasLayer

# HUD de la zona: solo lee datos del jugador y de la raíz, no tiene colisiones
@onready var jug = get_parent().get_node("Jugador")
@onready var barra_vida = $PanelVida/BarraVida
@onready var barra_dopa = $PanelVida/BarraDopa
@onready var texto_ola = $PanelZona/TextoOla
@onready var texto_libres = $PanelLibres/TextoLibres
@onready var panel_jefe = $PanelJefe
@onready var barra_jefe = $PanelJefe/BarraJefe
@onready var banner = $Banner
@onready var texto_banner = $Banner/Texto
@onready var label_jefe = $PanelJefe/LabelJefe
@onready var pantalla_cel = $SlotCelular/Pantalla
@onready var flash = $Flash

func _ready():
	# Controles táctiles: solo se activan en celular/tableta (ver controles_tactiles.gd)
	var tactil = preload("res://comun/controles_tactiles/controles_tactiles.gd").new()
	add_child(tactil)

	# Pantalla del celular: video aleatorio o imagen de bloqueo (ver pantalla_celular.gd)
	var cel = preload("res://comun/hud/pantalla_celular.gd").new()
	cel.jug = jug
	pantalla_cel.add_child(cel)

func _process(_delta):
	barra_vida.value = jug.vida
	barra_dopa.value = jug.dopa

	var mejor = max(jug.record, jug.libres)
	var raiz = get_parent()
	texto_ola.text = "ZONA " + str(raiz.numero_zona) + " · " + raiz.nombre_zona + " · OLEADA " + str(raiz.n_ola)
	texto_libres.text = "Liberados: " + str(jug.libres) + "   Récord: " + str(mejor)

# --- Funciones para el jefe (se conectan en las Partes 3 y 4) ---

func mostrar_jefe(visible_):
	if visible_:
		label_jefe.text = "JEFE: " + get_parent().nombre_jefe
		label_jefe.add_theme_color_override("font_color", Color(1, 0.45, 0.45))
	panel_jefe.visible = visible_

# Se conecta a la señal vida_cambiada(valor, maximo) del jefe
func actualizar_jefe(valor, maximo):
	barra_jefe.max_value = maximo
	barra_jefe.value = valor

func mostrar_banner(visible_, texto = "¡SÍGUEME!"):
	texto_banner.text = texto
	banner.visible = visible_

# Pantalla blanca del Flash de selfie
func flash_blanco(seg):
	flash.visible = true
	var tw = create_tween()
	tw.tween_interval(seg)
	tw.tween_callback(func(): flash.visible = false)
