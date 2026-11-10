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
@onready var estado_cel = $SlotCelular/Estado
@onready var texto_imagen = $SlotCelular/Pantalla/TextoImagen
@onready var flash = $Flash
# _ready() se ejecuta una vez cuando el HUD entra a la escena
func _ready():
	# Node2D.new() crea un nodo vacío, sin que exista en ninguna escena (.tscn)
	var ct = Node2D.new()
	# set_script() le pone nuestro script de controles táctiles. preload() carga
	# el archivo al arrancar el juego, antes de que se necesite.
	ct.set_script(preload("res://comun/hud/controles_tactiles.gd"))
	# add_child() lo cuelga del HUD, y así aparece en todas las zonas que usen este HUD
	add_child(ct)

func _ready():
	# Controles táctiles: solo se activan en celular/tableta (ver controles_tactiles.gd)
	var tactil = preload("res://comun/controles_tactiles/controles_tactiles.gd").new()
	add_child(tactil)
	if tactil.activo:
		$SlotCelular/TeclaCelular.text = "Botón CELULAR"
		$SlotCelular/TeclaGolpe.text = "Botón CACHETADA"

func _process(_delta):
	barra_vida.value = jug.vida
	barra_dopa.value = jug.dopa

	var mejor = max(jug.record, jug.libres)
	var raiz = get_parent()
	texto_ola.text = "ZONA " + str(raiz.numero_zona) + " · " + raiz.nombre_zona + " · OLEADA " + str(raiz.n_ola)
	texto_libres.text = "Liberados: " + str(jug.libres) + "   Récord: " + str(mejor)

	if jug.cel_abierto:
		pantalla_cel.color = Color(0.5, 0.85, 1.0)
		texto_imagen.add_theme_color_override("font_color", Color(0.05, 0.15, 0.25))
		estado_cel.text = "ABIERTO"
	else:
		pantalla_cel.color = Color(0.08, 0.08, 0.1)
		texto_imagen.add_theme_color_override("font_color", Color(0.85, 0.85, 0.88))
		estado_cel.text = "CERRADO"

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
