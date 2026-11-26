class_name Poderes

# Power ups que se eligen al subir de nivel (10 poderes, cada uno mejorable hasta categoría 5).
#
# Igual que Registro, vive en variables "static": las categorías sobreviven al cambio de zona
# y se borran con reiniciar() cuando se pierde, se vuelve al menú o se empieza una partida.
# El jugador (jugador.gd) lee los multiplicadores de aquí; el selector (selector_poderes.gd)
# usa los textos; el HUD usa texto_lista().
#
# Reparto: del nivel 1 al 12 hay 11 subidas de nivel y los 10 poderes completos son 50
# categorías, así que nadie los tiene todos: subir uno al máximo ya gasta 5 elecciones.

const MAX_CAT = 5
const CURA_PECHO = 8.0   # lo que cura Pecho de Acero al elegirlo (igual que lo que sube la vida máxima)

const IDS = ["brazo", "pecho", "scroll", "palma", "pacto", "rayo", "turbo", "piel", "detox", "karma"]

const NOMBRES = {
	"brazo": "Brazo Largo",
	"pecho": "Pecho de Acero",
	"scroll": "Scroll Consciente",
	"palma": "Palma Pesada",
	"pacto": "Pacto con el Algoritmo",
	"rayo": "Manos de Rayo",
	"turbo": "Zapatillas Turbo",
	"piel": "Piel Antizombi",
	"detox": "Detox Digital",
	"karma": "Karma Positivo",
}

const RESUMEN = {
	"brazo": "Agranda el círculo de la cachetada.",
	"pecho": "Más vida máxima, y te cura al elegirlo.",
	"scroll": "Con el celular abierto, la dopamina sube más lento.",
	"palma": "Cada cachetada al jefe hace más daño.",
	"pacto": "El celular cura más, pero la dopamina sube más rápido.",
	"rayo": "Menos espera entre cachetadas.",
	"turbo": "Corres más rápido.",
	"piel": "Recibes menos daño de zombis y jefes.",
	"detox": "Con el celular cerrado, la dopamina baja más rápido.",
	"karma": "Liberar zombis con la cachetada te cura.",
}

const COLORES = {
	"brazo": Color(1.0, 0.75, 0.25),
	"pecho": Color(1.0, 0.4, 0.45),
	"scroll": Color(0.45, 0.8, 1.0),
	"palma": Color(1.0, 0.55, 0.2),
	"pacto": Color(0.8, 0.45, 1.0),
	"rayo": Color(1.0, 0.95, 0.35),
	"turbo": Color(0.4, 1.0, 0.7),
	"piel": Color(0.6, 0.7, 0.85),
	"detox": Color(0.5, 0.95, 0.5),
	"karma": Color(1.0, 0.6, 0.85),
}

# id -> categoría actual (1 a 5). Solo están los que ya se eligieron, en el orden en que se eligieron.
static var cats = {}
# true mientras el selector está abierto (lo leen la pausa y los controles táctiles)
static var eligiendo = false

static func reiniciar():
	cats = {}
	eligiendo = false

static func cat(id):
	return int(cats.get(id, 0))

static func subir(id):
	cats[id] = mini(cat(id) + 1, MAX_CAT)

# Total de elecciones hechas (suma de todas las categorías)
static func total():
	var n = 0
	for id in cats:
		n += int(cats[id])
	return n

# Elecciones que le faltan por hacer: una por cada nivel ganado (nivel 2 = 1, nivel 3 = 2...)
static func pendientes(nivel):
	return maxi((nivel - 1) - total(), 0)

# Hasta 3 poderes distintos al azar entre los que todavía no están en categoría 5
static func tres_opciones():
	var libres = []
	for id in IDS:
		if cat(id) < MAX_CAT:
			libres.append(id)
	libres.shuffle()
	return libres.slice(0, 3)

# ---------------- Efectos (el jugador los lee cada vez que los necesita) ----------------

static func mult_radio():     # Brazo Largo: +6 % de radio por categoría (70 -> 91 px)
	return 1.0 + 0.06 * cat("brazo")

static func vida_max():       # Pecho de Acero: +8 de vida máxima por categoría (100 -> 140)
	return 100.0 + CURA_PECHO * cat("pecho")

static func mult_cura():      # Pacto con el Algoritmo: el celular cura +15 % por categoría
	return 1.0 + 0.15 * cat("pacto")

# Dopamina con el celular abierto: Scroll Consciente -8 % por categoría, Pacto con el Algoritmo +10 %
static func mult_dopa_cel():
	return (1.0 - 0.08 * cat("scroll")) * (1.0 + 0.10 * cat("pacto"))

static func mult_dano():      # Palma Pesada: +15 % de daño a los jefes por categoría (1 -> 1,75)
	return 1.0 + 0.15 * cat("palma")

static func enfriamiento():   # Manos de Rayo: -0,025 s por categoría (0,40 -> 0,275 s)
	return 0.4 - 0.025 * cat("rayo")

static func mult_vel():       # Zapatillas Turbo: +4 % por categoría (300 -> 360)
	return 1.0 + 0.04 * cat("turbo")

static func reduccion_dano(): # Piel Antizombi: -6 % de daño recibido por categoría (hasta -30 %)
	return 0.06 * cat("piel")

static func caida_dopa():     # Detox Digital: con el celular cerrado la dopamina baja +0,25/s más por categoría
	return 2.0 + 0.25 * cat("detox")

static func cura_karma():     # Karma Positivo: vida por zombi liberado (+0,3 por categoría)
	return 0.3 * cat("karma")

# ---------------- Textos ----------------

# Lo que da este poder al llegar a la categoría "c" (el total, no solo el aumento)
static func efecto(id, c):
	match id:
		"brazo":
			return "Radio del golpe +%d%% (%d px)" % [roundi(6.0 * c), roundi(70.0 * (1.0 + 0.06 * c))]
		"pecho":
			return "Vida máxima %d (+%d y te cura %d)" % [roundi(100.0 + CURA_PECHO * c), roundi(CURA_PECHO), roundi(CURA_PECHO)]
		"scroll":
			return "Dopamina del celular: %s/s" % str(snappedf(8.0 * (1.0 - 0.08 * c), 0.01))
		"palma":
			return "Daño a jefes x%s" % str(snappedf(1.0 + 0.15 * c, 0.01))
		"pacto":
			return "Celular: cura +%d%%, dopamina +%d%%" % [roundi(15.0 * c), roundi(10.0 * c)]
		"rayo":
			return "Espera entre cachetadas: %s s" % str(snappedf(0.4 - 0.025 * c, 0.001))
		"turbo":
			return "Velocidad +%d%%" % roundi(4.0 * c)
		"piel":
			return "Daño recibido -%d%%" % roundi(6.0 * c)
		"detox":
			return "Con celular cerrado: dopamina -%s/s" % str(snappedf(2.0 + 0.25 * c, 0.01))
		"karma":
			return "Cada zombi liberado cura %s (hasta 5 por golpe)" % str(snappedf(0.3 * c, 0.1))
	return ""

# Lista para el HUD: un renglón por poder elegido, en el orden en que se eligieron
static func texto_lista():
	var t = ""
	for id in cats:
		if t != "":
			t += "\n"
		t += "%s  %d/%d" % [NOMBRES[id], int(cats[id]), MAX_CAT]
	return t
