extends CanvasLayer

# HUD de la zona (escena comun/hud/HUD.tscn, hijo "HUD" de cada zona). Solo lee datos del jugador
# y de la raíz de la zona (oleadas.gd), no tiene colisiones. Muestra barras de vida y dopamina,
# zona/oleada, liberados y récord, la barra del jefe, el banner de avisos, el flash blanco y el
# recuadro del celular. Los jefes y oleadas.gd lo usan por las funciones de abajo.
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

var barra_xp: ProgressBar
var texto_xp: Label
var xp_antes = -1
var lleno_xp: StyleBoxFlat

func _ready():
	crear_barra_xp()
	# Controles táctiles: solo se activan en celular/tableta (ver controles_tactiles.gd)
	var tactil = preload("res://comun/controles_tactiles/controles_tactiles.gd").new()
	add_child(tactil)

	# Pantalla del celular: video aleatorio o imagen de bloqueo (ver pantalla_celular.gd)
	var cel = preload("res://comun/hud/pantalla_celular.gd").new()
	cel.jug = jug
	pantalla_cel.add_child(cel)

# Refresca barras y textos cada frame
func _process(_delta):
	barra_vida.value = jug.vida
	barra_dopa.value = jug.dopa
	barra_xp.value = jug.progreso_xp() * 100.0
	if jug.xp != xp_antes:
		if xp_antes >= 0 and jug.xp > xp_antes:
			# la barra destella y el texto da un saltito cada vez que sumas XP
			lleno_xp.bg_color = Color(1, 1, 1)
			create_tween().tween_property(lleno_xp, "bg_color", Color(0.3, 0.85, 1.0), 0.25)
			texto_xp.pivot_offset = texto_xp.size / 2.0
			texto_xp.scale = Vector2(1.25, 1.25)
			create_tween().tween_property(texto_xp, "scale", Vector2.ONE, 0.2)
		xp_antes = jug.xp
	if jug.nivel >= jug.XP_NIVELES.size():
		texto_xp.text = "NIVEL %d · MÁX" % jug.nivel
	else:
		texto_xp.text = "NIVEL %d · %d/%d XP" % [jug.nivel, jug.xp, jug.XP_NIVELES[jug.nivel]]

	var mejor = max(jug.record, jug.libres)
	var raiz = get_parent()
	texto_ola.text = "ZONA " + str(raiz.numero_zona) + " · " + raiz.nombre_zona + " · OLEADA " + str(raiz.n_ola)
	texto_libres.text = "Liberados: " + str(jug.libres) + "   Récord: " + str(mejor)

# Barra de experiencia (debajo de la dopamina). Se crea por código: el panel se alarga 30 px.
func crear_barra_xp():
	var panel = $PanelVida
	panel.offset_bottom += 32.0
	var lbl = Label.new()
	lbl.text = "XP"
	lbl.position = Vector2(14, 75)
	lbl.size = Vector2(68, 22)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(lbl)
	barra_xp = ProgressBar.new()
	barra_xp.position = Vector2(82, 78)
	barra_xp.size = Vector2(206, 16)
	barra_xp.show_percentage = false
	barra_xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo = StyleBoxFlat.new()
	fondo.bg_color = Color(0.13, 0.13, 0.13)
	fondo.set_corner_radius_all(8)
	var lleno = StyleBoxFlat.new()
	lleno_xp = lleno
	lleno.bg_color = Color(0.3, 0.85, 1.0)
	lleno.set_corner_radius_all(8)
	barra_xp.add_theme_stylebox_override("background", fondo)
	barra_xp.add_theme_stylebox_override("fill", lleno)
	panel.add_child(barra_xp)
	texto_xp = Label.new()
	texto_xp.position = Vector2(82, 76)
	texto_xp.size = Vector2(206, 20)
	texto_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_xp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto_xp.add_theme_font_size_override("font_size", 11)
	texto_xp.add_theme_color_override("font_color", Color(1, 1, 1))
	texto_xp.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	texto_xp.add_theme_constant_override("outline_size", 3)
	panel.add_child(texto_xp)

# Cartel grande en el centro al subir de nivel
func anunciar_nivel(n, nombre):
	var caja = Label.new()
	caja.text = "¡NIVEL %d!\n%s" % [n, nombre.to_upper()]
	caja.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caja.add_theme_font_size_override("font_size", 46)
	caja.add_theme_color_override("font_color", Color(0.55, 1.0, 1.0))
	caja.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.15))
	caja.add_theme_constant_override("outline_size", 10)
	caja.size = Vector2(700, 140)
	caja.position = Vector2(576 - 350, 200)
	caja.pivot_offset = caja.size / 2.0
	caja.scale = Vector2(0.3, 0.3)
	add_child(caja)
	var tw = create_tween()
	tw.tween_property(caja, "scale", Vector2(1.1, 1.1), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(caja, "scale", Vector2.ONE, 0.1)
	tw.tween_interval(1.1)
	tw.tween_property(caja, "modulate:a", 0.0, 0.4)
	tw.tween_callback(caja.queue_free)

# --- Funciones para el jefe (se conectan en las Partes 3 y 4) ---

# Muestra u oculta el panel con la barra de vida del jefe
func mostrar_jefe(visible_):
	if visible_:
		label_jefe.text = "JEFE: " + get_parent().nombre_jefe
		label_jefe.add_theme_color_override("font_color", Color(1, 0.45, 0.45))
	panel_jefe.visible = visible_

# Se conecta a la señal vida_cambiada(valor, maximo) del jefe
func actualizar_jefe(valor, maximo):
	barra_jefe.max_value = maximo
	barra_jefe.value = valor

# Banner grande de avisos en pantalla (texto corto: el recuadro es pequeño)
func mostrar_banner(visible_, texto = "¡SÍGUEME!"):
	texto_banner.text = texto
	banner.visible = visible_

# Pantalla blanca del Flash de selfie
func flash_blanco(seg):
	flash.visible = true
	var tw = create_tween()
	tw.tween_interval(seg)
	tw.tween_callback(func(): flash.visible = false)
