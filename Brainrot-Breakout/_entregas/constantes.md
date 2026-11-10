# Constantes de balance (Parte 4b)
Cada valor vive al inicio de su script. Se cambian ahí.

## zona_2/jefe/jefe_algoritmo.gd
```
const VIDA_MAX = 60
const FASE2_VIDA = 30            # fase 2 al bajar de este valor
const RADIO_CUERPO = 100.0
const DANO_CONTACTO = 25.0       # vida por segundo dentro del cuerpo
const ALCANCE_JUGADOR = 100.0    # igual a "alcance" de jugador.gd
const TIEMPO_INTRO = 2.0
const TIEMPO_ATURDIDO = 5.0
const PARPADEO_FINAL = 1.0       # el último segundo parpadean las insignias nuevas
const RADIO_ORBITA = 140.0
const RADIO_INSIGNIA = 22.0
const VEL_ORBITA = 40.0          # grados por segundo
const MULT_ORBITA_F2 = 1.6       # fase 2: giran más rápido
const DANO_INSIGNIA = 1          # vida del jefe al reventar una insignia
const DANO_ATURDIDO = 1          # vida del jefe por cachetada estando aturdido
const TANDAS = [[3, 4, 5], [3, 4, 5], [4, 5, 6]]
const TANDA_REPETIDA = [4, 5, 6] # cuando se acaban las tandas
const ALFA_ESPERA = 0.3          # alfa de las insignias nuevas mientras no cuentan
const PAUSA_ATAQUE = 1.5         # pausa entre ataques
const PAUSA_ATAQUE_F2 = 1.0      # pausa en fase 2
const ESPERA_COOLDOWN = 0.5      # si ningún ataque sirve, reintenta tras este tiempo
const COOLDOWNS = {"spam": 9.0, "scroll": 10.0, "shadowban": 9.0, "recomendado": 11.0, "suscriptores": 14.0}
const NOMBRES = {"spam": "Spam de notificaciones", "scroll": "Scroll infinito", "shadowban": "Shadowban", "recomendado": "Recomendado para ti", "suscriptores": "Suscriptores"}
const RADIO_SALIDA = 110.0       # burbujas y clon salen del borde del orbe (así no nacen dentro de un sofá)
const SPAM_AVISO = 0.8
const SPAM_TANDAS = 2
const SPAM_BURBUJAS = 4          # por tanda
const SPAM_BURBUJAS_F2 = 5       # en fase 2
const SPAM_SEPARACION = 0.9      # segundos entre tandas
const SPAM_ABANICO = 60.0        # grados de apertura
const SPAM_VEL = 170.0           # px/s
const SPAM_GIRO = 1.4            # rad/s máximos hacia el jugador
const SPAM_VIDA_UTIL = 6.0       # segundos
const SPAM_DOPA = 6.0            # dopamina al tocar (sin daño de vida)
const SCROLL_AVISO = 1.0
const SCROLL_ACTIVA = 5.0
const SCROLL_ALTO = 110.0        # alto de la franja
const SCROLL_VEL = 140.0         # px/s de arrastre
const SCROLL_Y_MIN = 180.0       # la franja se centra en la y del jugador, dentro de este rango
const SCROLL_Y_MAX = 590.0
const SCROLL_DOPA = 8.0          # dopamina por segundo mientras estés en la franja
const SHADOW_AVISO = 0.8
const SHADOW_ACTIVA = 6.0
const SHADOW_RADIO = 100.0
const SHADOW_MULT = 0.6          # velocidad ×0,6 dentro (se multiplica con el celular)
const SHADOW_DOPA = 6.0          # dopamina por segundo mientras estés dentro
const SHADOW_X0 = 120.0          # fase 2: segunda zona al azar en este rectángulo
const SHADOW_X1 = 1030.0
const SHADOW_Y0 = 180.0
const SHADOW_Y1 = 580.0
const RECO_AVISO = 1.0
const RECO_APUNTA = 0.6          # sigue al jugador este tiempo; luego bloquea el ángulo
const RECO_VEL = 420.0           # px/s
const RECO_DANO = 10.0
const RECO_EMPUJE = 150.0
const RECO_ESCALA = 0.4          # tamaño de la copia (icon.svg ×0,4, como el zombi)
const RECO_LINEA = 1400.0        # largo de la línea del aviso
const SUSC_AVISO = 1.2           # el banner ¡SUSCRÍBETE! sale este tiempo antes de los zombis
const SUSC_SI_MENOS_DE = 5       # solo se lanza si hay menos de estos zombis vivos
const SUSC_CANT = 8              # antes 4
const SUSC_CANT_F2 = 10          # antes 5
const SUSC_SEPARACION = 0.4
const SETS = [Vector2(880, 245), Vector2(560, 245), Vector2(240, 245)]   # A, B, C
const CAMBIO_DESVANECE = 0.5
const CAMBIO_INVISIBLE = 0.5
const CAMBIO_APARECE = 0.5
const CAMBIO_MIN = 2             # se cambia de set cada 2-3 ataques (al azar)
const CAMBIO_MAX = 3
const COLOR_NORMAL = Color(0.42, 0.36, 0.88)
const COLOR_ATURDIDO = Color(0.5, 0.6, 1.0)
const COLOR_OJO = Color(1, 0.25, 0.4)
const COLOR_SALMON = Color(1, 0.55, 0.5)
const RADIO_DIBUJO = 108.0       # el orbe visual es un poco más grande que el cuerpo
```

## zona_2/jefe/ataques/burbuja.gd
(los valores por defecto de las `var` los pisa el jefe al crearla; se ajustan en jefe_algoritmo.gd)
```
const GRACIA = 0.25
```

## zona_2/jefe/ataques/cinta.gd
(los valores por defecto de las `var` los pisa el jefe al crearla; se ajustan en jefe_algoritmo.gd)
```
const ANCHO = 1152.0     # de borde a borde del mapa
const ESPACIO = 70.0     # separación entre chevrones
```

## zona_2/jefe/ataques/shadowban.gd
(los valores por defecto de las `var` los pisa el jefe al crearla; se ajustan en jefe_algoritmo.gd)
```

```

## zona_2/jefe/ataques/clon.gd
(los valores por defecto de las `var` los pisa el jefe al crearla; se ajustan en jefe_algoritmo.gd)
```
const GRACIA = 0.25
const MARGEN_FUERA = 150.0   # si se aleja tanto del mapa, se borra
```

## comun/sistema/oleadas.gd
```
const RADIO_ZOMBI = 20.0   # mismo valor que RADIO en zombi.gd
const INTENTOS_SPAWN = 10
@export var numero_zona = 1
@export var nombre_zona = "CALLE"
@export var nombre_jefe = "INFLUENCER"
@export var jefe_esc: PackedScene          # la zona lo asigna en su .tscn
@export var pos_jefe = Vector2(880, 300)   # Set A del jefe
@export var ola_inicial = 0
@export var tamanos_iniciales: Array = [5, 8, 12]
@export var paso_oleada = 4                # cuánto sube "ult" en cada oleada
@export var spawn_y_min = 130.0
@export var spawn_x_min = 30.0       # bordes de spawn (los defaults son los de siempre; la Zona 4 los cambia)
@export var spawn_x_max = 1122.0
@export var spawn_y_max = 630.0
@export var spawn_y_fondo = 618.0
@export var escena_siguiente = ""          # vacío = siguen las oleadas
var pausa = 3.0
```

## comun/jugador/jugador.gd
```
const ESCALA = 0.4
const RADIO = 20.0
const EMPUJE_TIEMPO = 0.25   # lo que dura el empujón del Pulso del jefe
var vel = 300.0
var vida = 100.0
var dopa = 0.0
var alcance = 100.0
var invertido_t = 0.0      # segundos de «Control invertido» que faltan (Dr. Dopamina; dir = -dir)
var cel_bloqueado_t = 0.0  # segundos de «Apagón del celular» que faltan (Núcleo-∞; ignora ui_accept)
# (en _physics_process) cachetada: enfriamiento 0.4 s · celular abierto: velocidad ×0.6, vida +5/s, dopamina +8/s · cerrado: dopamina −2/s
```

## comun/zombi/zombi.gd
```
const ESCALA = 0.4
const RADIO = 20.0
var vel_z = 100.0
var dano = 10.0
```

## zona_1/jefe/jefe_influencer.gd
```
const VIDA_MAX = 56
const FASE2_VIDA = 28            # fase 2 al bajar de este valor
const ANTENAS = [8, 8, 10, 10]   # vida de las antenas sucesivas
const ANTENA_REPETIDA = 10       # si se acaban, se repite este valor
const DANO_ANTENA = 4            # vida que pierde el jefe al romper una antena
const TIEMPO_INTRO = 2.0
const TIEMPO_ATURDIDO = 5.0
const PARPADEO_FINAL = 1.0
const ALCANCE_JUGADOR = 100.0    # igual a "alcance" de jugador.gd
const RADIO_CUERPO = 70.0
const RADIO_ANTENA = 25.0
const POS_ANTENA = [Vector2(0, -95), Vector2(-95, 0), Vector2(95, 0)]
const PAUSA_ATAQUE = 1.5         # pausa entre ataques
const PAUSA_ATAQUE_F2 = 1.0      # pausa en fase 2
const ESPERA_COOLDOWN = 0.5      # si todos los ataques están en cooldown
const COOLDOWNS = {"flash": 7.0, "lluvia": 6.0, "lluvia_grande": 12.0, "directo": 14.0, "pulso": 4.0, "llamado": 12.0}
const PULSO_DIST = 130.0     # distancia al centro que activa el pulso
const PULSO_ESPERA = 1.2     # segundos cerca del jefe para que se active
const PULSO_BRILLO = 0.8     # el aro brilla este tiempo antes de la onda
const PULSO_RADIO = 140.0
const PULSO_DANO = 5.0
const PULSO_EMPUJE = 150.0
const PULSO_ANIM = 0.3       # duración del dibujo de la onda
const DANO_CONTACTO = 25.0
const FLASH_AVISO = 1.0        # duración del aviso (el cono amarillo)
const FLASH_APUNTA = 0.6       # sigue al jugador este tiempo; después bloquea el ángulo
const FLASH_ALCANCE = 450.0
const FLASH_SEMIANGULO = 16.0  # grados
const FLASH_BLANCO = 1.5       # segundos de pantalla blanca si te alcanza
const LLUVIA_AVISO = 0.6       # aviso antes de la primera tanda
const LLUVIA_TANDAS = 2
const LLUVIA_CORAZONES = 5     # corazones por tanda
const LLUVIA_SEPARACION = 0.5  # segundos entre tandas
const LLUVIA_ABANICO = 50.0    # grados de apertura del abanico
const LLUVIA_VEL = 220.0       # px/s
const DANO_LIKE = 6.0          # bajar a 5 en la Parte 7 si el jugador muere mucho
const GRANDE_AVISO = 1.2
const GRANDE_OLAS = 6          # tandas de corazones
const GRANDE_SEPARACION = 0.5  # segundos entre tandas
const GRANDE_COLUMNAS = 12     # el ancho del mapa se divide en columnas
const GRANDE_POR_OLA = 8       # corazones por tanda (quedan 4 columnas libres para esquivar)
const GRANDE_VEL = 240.0       # px/s hacia abajo
const GRANDE_Y = 125.0         # justo debajo de la pared de arriba (que llega hasta y=112)
const GRANDE_X0 = 30.0
const GRANDE_X1 = 1122.0
const DANO_LIKE_GRANDE = 4.0   # más bajo que DANO_LIKE porque caen muchos
const DIRECTO_AVISO = 1.0
const DIRECTO_ACTIVA = 5.0
const DIRECTO_ANCHO = 90.0
const DIRECTO_DOPA = 15.0      # dopamina por segundo mientras estés dentro
const LLAMADO_AVISO = 1.2        # el banner ¡SÍGUEME! sale este tiempo antes de los zombis
const LLAMADO_SI_MENOS_DE = 6    # solo se lanza si hay menos de estos zombis vivos
const LLAMADO_CANT = 6           # zombis que llama
const LLAMADO_CANT_F2 = 8        # en fase 2
const LLAMADO_SEPARACION = 0.4   # segundos entre un zombi y el siguiente
const SETS = [Vector2(880, 300), Vector2(560, 324), Vector2(250, 324)]   # A, B, C
const CAMBIO_DESVANECE = 0.5
const CAMBIO_INVISIBLE = 0.5
const CAMBIO_APARECE = 0.5
const CAMBIO_MIN = 2           # se cambia de set cada 2-3 ataques (al azar)
const CAMBIO_MAX = 3
const COLOR_NORMAL = Color(1, 0.45, 0.8)
const COLOR_ATURDIDO = Color(0.5, 0.6, 1.0)
```

## zona_1/jefe/ataques/corazon.gd
```
const MARGEN_FUERA = 150.0   # si se aleja tanto del mapa, se borra
```

## zona_1/jefe/ataques/franja.gd
```
const ALTO = 648.0   # de borde a borde del mapa
```

## zona_2/zona_2.tscn (exports de la raíz)

```
numero_zona = 2
nombre_zona = "EDIFICIO SOCIAL"
nombre_jefe = "ALGORITMO"   # acortado: LabelJefe del HUD mide 100 px (fuente 11)
pos_jefe = Vector2(880, 245)
ola_inicial = 5
tamanos_iniciales = [14, 16, 18]
paso_oleada = 2
spawn_y_min = 150.0
escena_siguiente = "res://zona_3/zona_3.tscn"
```

# Constantes de balance de las zonas 3 a 6 (Parte 6)
Mismo estilo que arriba. Los jefes de las zonas 3 a 6 heredan de `comun/jefe/jefe_base.gd` (ver sus constantes comunes más abajo).

## comun/jefe/jefe_base.gd
```
const ALCANCE_JUGADOR = 100.0   # igual a "alcance" de jugador.gd
const TIEMPO_INTRO = 2.0
const PAUSA_ATAQUE = 1.5        # descanso entre ataques
const PAUSA_ATAQUE_F2 = 1.0     # descanso en fase 2
const ESPERA_COOLDOWN = 0.5     # si ningún ataque sirve, reintenta tras este tiempo
var vida_max = 40          # cada jefe lo pisa en configurar()
var dano_golpe = 1          # vida que quita cada cachetada con el jefe aturdido
```

## zona_3/jefe/jefe_capataz.gd
```
const VIDA = 20
const FASE2_VIDA = 10
const RADIO = 70.0
const DANO_CONTACTO = 25.0       # vida por segundo dentro del cuerpo
const COOLDOWNS = {"embestida": 8.0, "lluvia": 10.0, "cintas": 14.0, "doble": 12.0}
const NOMBRES = {"embestida": "Embestida", "lluvia": "Lluvia de cajas", "cintas": "Cintas aceleradas", "doble": "Turno doble"}
const EMB_AVISO = 1.0
const EMB_APUNTA = 0.6           # la marca sigue al jugador este tiempo; luego se bloquea
const EMB_VEL = 650.0            # px/s
const EMB_ATURDIDO = 2.0         # segundos aturdido tras chocar
const EMB_DANO = 20.0            # vida si te embiste
const EMB_EMPUJE = 180.0
const EMB_PAUSA_DOBLE = 0.4      # entre las dos embestidas del turno doble
const LLUVIA_AVISO = 0.5
const LLUVIA_TANDAS = 3
const LLUVIA_CAJAS = 3           # por tanda
const LLUVIA_CAJAS_F2 = 5
const LLUVIA_SEPARACION = 0.9
const CAJA_AVISO = 1.0           # de la marca a la caída
const CAJA_DANO = 15.0
const MAX_CAJAS = 6              # si caen más, desaparece la más vieja (cola)
const CAJA_AREA = Rect2(80, 160, 992, 440)   # donde pueden caer
const CINTAS_AVISO = 1.0
const CINTAS_ACTIVA = 8.0
const CINTAS_VEL_INI = 90.0
const CINTAS_VEL_FIN = 240.0
const CINTAS_ALTO = 100.0
const CINTAS_Y = [235.0, 440.0]
const CINTAS_INVIERTE_CADA = 2.6
const DOBLE_CAJAS = 3
```

## zona_3/jefe/ataques/caja_carga.gd
```
const LADO = 76.0          # mismo tamaño que las cajas del mapa
const RADIO_AVISO = 46.0
const RADIO_JUGADOR = 18.0
```

## zona_3/jefe/ataques/cinta_carga.gd
```
const ANCHO = 1152.0
const ESPACIO = 70.0     # separación entre chevrones
```

## zona_4/jefe/jefe_gemelo.gd
```
const VIDA = 40
const FASE2_VIDA = 20
const RADIO = 55.0
const DANO_CONTACTO = 20.0
const VEL_VAGA = 80.0            # el Gemelo da vueltas por la arena a esta velocidad
const COOLDOWNS = {"reflejo": 12.0, "clones": 14.0, "apagon": 13.0, "sacudida": 11.0}
const NOMBRES = {"reflejo": "Reflejo", "clones": "Clones de espejo", "apagon": "Apagón", "sacudida": "Sacudida de cables"}
const VENTANA_CADA = 2           # ataques entre desincronizaciones
const VENTANA_SEG = 4.0
const REFLEJO_AVISO = 0.8
const REFLEJO_DURA = 8.0
const REFLEJO_RETRASO = 1.0
const REFLEJO_RETRASO_F2 = 0.7   # en fase 2 te alcanza más rápido
const REFLEJO_DANO = 12.0
const CLONES_AVISO = 0.8
const CLONES_CANT = 2
const CLONES_CANT_F2 = 3
const CLONES_DURA = 10.0
const CLONES_DISTANCIA_MIN = 150.0   # no nacen encima del jugador
const COLORES_CLON = [Color(0.3, 0.9, 1.0), Color(1.0, 0.3, 0.8), Color(0.6, 1.0, 0.5)]
const APAGON_AVISO = 1.0
const APAGON_DURA = 5.0
const APAGON_RADIO = 150.0           # radio de luz alrededor del jugador
const APAGON_COLOR = Color(0.03, 0.03, 0.06)
const SACUDIDA_AVISO = 1.0
const SACUDIDA_DURA = 1.5
const SACUDIDA_FUERZA = 8.0          # píxeles de temblor de la cámara
const PASAMANOS_Y = [200.0, 330.0, 460.0]
```

## zona_4/jefe/ataques/clon_espejo.gd
```
const RADIO = 50.0
```

## zona_4/jefe/ataques/reflejo.gd
```
const PASO_MUESTRA = 0.05    # cada cuánto se guarda una posición
const RADIO = 24.0
const RADIO_JUGADOR = 20.0
const ENFRIA_GOLPE = 0.8     # segundos entre un golpe y el siguiente
const EMPUJE = 120.0
```

## zona_5/jefe/jefe_dopamina.gd
```
const VIDA = 24
const FASE2_VIDA = 12
const RADIO = 60.0
const DANO_CONTACTO = 15.0
const COOLDOWNS = {"nube": 11.0, "jeringazo": 9.0, "invertido": 14.0, "cerebros": 13.0}
const NOMBRES = {"nube": "Nube tóxica", "jeringazo": "Jeringazo", "invertido": "Control invertido", "cerebros": "Cerebros mutantes"}
const NUBE_AVISO = 0.8
const NUBE_CANT = 3
const NUBE_CANT_F2 = 5
const NUBE_RADIO = 60.0
const NUBE_AVISO_CHARCO = 0.6
const NUBE_DURA = 8.0
const NUBE_DOPA = 10.0           # dopamina por segundo dentro del charco
const NUBE_DISTANCIA_MIN = 90.0  # no nace justo encima del jugador
const NUBE_AREA = Rect2(90, 170, 972, 430)
const JERINGA_AVISO = 1.0
const JERINGA_APUNTA = 0.6       # la marca sigue al jugador este tiempo; luego se bloquea
const JERINGA_VEL = 700.0
const JERINGA_DOPA = 20.0        # sobredosis al pincharte
const JERINGA_AGOTADO = 3.0      # segundos agotado después (aquí se le pega)
const INVERTIDO_AVISO = 0.8
const INVERTIDO_SEG = 4.0
const INVERTIDO_SEG_F2 = 5.0
const CEREBROS_AVISO = 0.8
const CEREBROS_CANT = 4
const CEREBROS_CANT_F2 = 6
const CEREBROS_VEL = 240.0
const CEREBROS_DANO = 10.0
const CEREBROS_DOPA = 8.0
const RADIO_SALIDA = 70.0        # los cerebros salen del borde del cuerpo
```

## zona_5/jefe/ataques/cerebro.gd
```
const RADIO = 16.0
const RADIO_JUGADOR = 20.0
```

## zona_6/jefe/jefe_nucleo.gd
```
const VIDA = 25
const FASE2_VIDA = 10            # 40 % de 25
const RADIO = 75.0
const DANO_CONTACTO = 20.0
const COOLDOWNS = {"rejilla": 8.0, "tormenta": 9.0, "apagon": 15.0}
const NOMBRES = {"rejilla": "Rejilla láser", "tormenta": "Tormenta de datos", "apagon": "Apagón del celular"}
const VENTANA_CADA = 3
const VENTANA_SEG = 4.0
const MULT_SOBRECARGA = 1.5      # en fase 2 todo va ×1.5 más rápido
const LASER_AVISO = 1.0
const LASER_CANT = 3
const LASER_CANT_F2 = 5
const LASER_VEL = 140.0
const LASER_DANO = 15.0
const LASER_COLORES = [Color(1.0, 0.25, 0.75), Color(0.2, 0.9, 1.0)]   # rosa y cian
const TORMENTA_AVISO = 0.8
const TORMENTA_OLAS = 6
const TORMENTA_OLAS_F2 = 8
const TORMENTA_SEPARACION = 0.9
const DATO_VEL = 200.0
const DATO_DANO = 5.0
const DATO_DOPA = 4.0
const COLUMNAS_X0 = 60.0         # los datos caen en columnas con un hueco por donde pasar
const COLUMNAS_PASO = 100.0
const COLUMNAS_N = 11
const ANILLO_N = 14              # en cada ola par sale un anillo de datos desde el núcleo
const APAGON_AVISO = 0.8
const APAGON_SEG = 6.0
```

## zona_6/jefe/ataques/dato.gd
```
const RADIO = 12.0
const RADIO_JUGADOR = 20.0
const FUERA = 60.0
```

## zona_6/jefe/ataques/laser.gd
```
const LARGO_X = 1152.0
const LARGO_Y = 648.0
const ESPESOR = 10.0           # ancho visual
const MARGEN_DANO = 14.0       # distancia a la línea que ya cuenta como tocarla
const ENFRIA_GOLPE = 0.6       # segundos entre un golpe y el siguiente
const FUERA = 80.0             # cuánto se puede salir del mapa antes de borrarse
```

## zona_6/jefe/ataques/victoria.gd
```
const SEG_ESPERA = 6.0
const ZONA_INICIAL = "res://zona_1/zona_1.tscn"
```

## zona_3/zona_3.tscn (exports de la raíz)

```
numero_zona = 3
nombre_zona = "ZONA DE CARGA"
nombre_jefe = "CAPATAZ"
pos_jefe = Vector2(880, 324)
ola_inicial = 10
tamanos_iniciales = [18, 20, 22]
paso_oleada = 2
spawn_y_min = 150.0
escena_siguiente = "res://zona_4/zona_4.tscn"
```

## zona_4/zona_4.tscn (exports de la raíz)

```
numero_zona = 4
nombre_zona = "ASCENSOR"
nombre_jefe = "GEMELO"
pos_jefe = Vector2(700, 260)
ola_inicial = 15
tamanos_iniciales = [22, 24, 26]
paso_oleada = 2
spawn_y_min = 150.0
spawn_x_min = 281.0
spawn_x_max = 871.0
spawn_y_max = 520.0
spawn_y_fondo = 520.0
escena_siguiente = "res://zona_5/zona_5.tscn"
```

## zona_5/zona_5.tscn (exports de la raíz)

```
numero_zona = 5
nombre_zona = "LABORATORIO"
nombre_jefe = "DOPAMINA"
pos_jefe = Vector2(880, 324)
ola_inicial = 20
tamanos_iniciales = [26, 28, 30]
paso_oleada = 2
spawn_y_min = 150.0
escena_siguiente = "res://zona_6/zona_6.tscn"
```

## zona_6/zona_6.tscn (exports de la raíz)

```
numero_zona = 6
nombre_zona = "SUPERCOMPUTADORAS"
nombre_jefe = "NÚCLEO-∞"
pos_jefe = Vector2(880, 324)
ola_inicial = 25
tamanos_iniciales = [30, 32, 34]
paso_oleada = 2
spawn_y_min = 150.0
```

