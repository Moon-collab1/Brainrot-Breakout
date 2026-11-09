# Parte 0 — Reorganizar y parametrizar

Base usada: `Brainrot-Breakout-parte6.zip` (el `main.zip` es la versión vieja de una sola carpeta; no se usó).

## Supuestos aplicados
- `escena_siguiente` queda vacío en la Zona 1: `zona_2.tscn` aún no existe. En la Parte 1 se pone `res://zona_2/zona_2.tscn`. Mientras tanto la Zona 1 sigue con oleadas como hoy.
- `jefe_esc` ya no es un preload dentro de `oleadas.gd`: es `@export` y la Zona 1 lo asigna en `zona_1.tscn` (así `comun/` no depende de `zona_1/`).
- Los demás `@export` tienen por defecto los valores de la Zona 1 (CALLE, INFLUENCER, (880,300), ola_inicial 0, [5,8,12], paso 4, spawn_y_min 130).
- `en_transicion` (variable nueva en oleadas.gd) frena las oleadas durante los 2,5 s antes de cambiar de zona.
- Texto del HUD de la Zona 1: ahora «ZONA 1 · CALLE · OLEADA n» (antes «ZONA 1 · OLEADA n»).
- Panel del jefe: «JEFE: INFLUENCER», color salmón, fuente 11 para que quepa en los 100 px del Label sin mover offsets.

## Archivos movidos (ruta vieja → nueva)
| Vieja | Nueva |
|---|---|
| zona_1/sistema/oleadas.gd (+uid) | comun/sistema/oleadas.gd |
| zona_1/sistema/lista.gd (+uid) | comun/sistema/lista.gd |
| zona_1/sistema/registro.gd (+uid) | comun/sistema/registro.gd |
| zona_1/jugador/jugador.gd (+uid) | comun/jugador/jugador.gd |
| zona_1/zombi/zombi.gd (+uid) | comun/zombi/zombi.gd |
| zona_1/zombi/zombi.tscn | comun/zombi/zombi.tscn |
| zona_1/hud/hud.gd | comun/hud/hud.gd |
| zona_1/hud/HUD.tscn | comun/hud/HUD.tscn |

## Archivos modificados
- comun/sistema/oleadas.gd: @export, spawn con círculos (`choca_con_forma`), transición de zona.
- comun/sistema/registro.gd: `static var libres_inicio`.
- comun/jugador/jugador.gd: `arrastre`, `arrastre_t`, `mult_vel`, `lento_t`, `ultimo_liberado`, libres iniciales, cachetada sobre grupo «destruibles».
- comun/hud/hud.gd: texto de zona desde la raíz, `mostrar_jefe` con nombre, `mostrar_banner(visible_, texto)`.
- zona_1/zona_1.tscn: rutas nuevas + `jefe_esc`.
- comun/zombi/zombi.tscn y comun/hud/HUD.tscn: rutas de script.
- NO se tocó jefe_influencer.gd, corazon.gd, franja.gd, Mapa.tscn ni project.godot.

## Pasos manuales en el editor
Ninguno. Al abrir, Godot regenerará los `.uid` que faltan (ver abajo).

## Checklist de prueba
- [ ] El proyecto abre sin errores de rutas rotas y F5 arranca la Zona 1.
- [ ] Texto superior derecho: «ZONA 1 · CALLE · OLEADA n» y avanza al lanzar oleadas.
- [ ] F1 invoca al Influencer; el panel dice «JEFE: INFLUENCER» en salmón y la barra baja.
- [ ] «Llamado» muestra el banner «¡SÍGUEME!» igual que antes.
- [ ] Zombis nunca aparecen encima de autos/basureros.
- [ ] Morir y reiniciar deja libres en 0 (en la Zona 1 `libres_inicio` es 0).

## No verificado (no pude ejecutar Godot)
- Que el texto «JEFE: INFLUENCER» a fuente 11 no se encime con la barra (si pasa, achica la fuente o mueve la barra).
- Parseo de GDScript y de los .tscn: solo revisé a mano y con grep.
- Faltan `.uid` para `jefe_influencer.gd`, `corazon.gd`, `franja.gd` y `hud.gd`: ya faltaban en parte6; Godot los crea solo y las escenas los referencian por path.

## Constantes (Parte 0)
oleadas.gd: RADIO_ZOMBI=20, INTENTOS_SPAWN=10; @export numero_zona=1, nombre_zona="CALLE", nombre_jefe="INFLUENCER", pos_jefe=(880,300), ola_inicial=0, tamanos_iniciales=[5,8,12], paso_oleada=4, spawn_y_min=130, escena_siguiente="".
