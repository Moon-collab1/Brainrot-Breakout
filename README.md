# Brainrot Breakout

**🎮 Jugar en el navegador:** https://lookthereis.itch.io/brainrot-breakout

Juego 2D de acción hecho en **Godot 4.7** (GDScript, renderer GL Compatibility) para la Feria Gamer de la Universidad del Norte y el curso de Estructuras de Datos I.

Eres un jugador atrapado en el *doomscrolling*: libera zombis con cachetadas, usa el celular para curarte (¡pero cuidado con la dopamina!) y derrota a un jefe al final de cada una de las 6 zonas. El celular es una metáfora del consumo compulsivo de redes sociales: te da alivio inmediato, pero te cuesta visibilidad y control.

## Características
- Mecánica de riesgo y recompensa: con el celular abierto te curas, pero sube la dopamina, te mueves más lento y la pantalla se vuelve borrosa.
- 6 zonas con 6 jefes distintos, oleadas progresivas y un jefe cada 5 oleadas.
- Leaderboard top 10 persistente (más zombis liberados primero; en empate, menor tiempo).
- Accesibilidad: filtros para daltonismo (protanopía, deuteranopía, tritanopía), volúmenes independientes, bloqueo de los videos del celular y controles configurables.
- Controles táctiles que se activan solos en pantallas táctiles.
- Estructuras de datos implementadas a mano: `Lista`, `Cola`, `Leaderboard` y `Registro` (en `comun/datos/`).

## Cómo abrirlo
1. Clona el repositorio:
   `git clone https://github.com/Moon-collab1/Brainrot-Breakout.git`
2. Abre **Godot 4.7** → **Import** → selecciona `project.godot`. La primera vez Godot regenera la carpeta `.godot/`, que no se sube al repositorio.
3. Ejecuta con **F5** (la escena principal es `menu/menu.tscn`).

## Exportar a la web
El preset **Web** ya está configurado en `export_presets.cfg` (Project → Export → Web). Exporta a la carpeta `web/` (ignorada por git) y sube su contenido a itch.io como proyecto HTML5.

## Controles
| Acción | Teclado (modo 1) | Teclado (modo 2) | Táctil |
|---|---|---|---|
| Moverse | Flechas | W A S D | Joystick flotante (mitad izquierda) |
| Cachetada | **X** | Clic derecho | Botón CACHETADA |
| Abrir/cerrar celular | Espacio | Espacio | Botón CELULAR |
| Pausa | Esc | Esc | Botón **II** |

Las teclas se pueden cambiar en **Configuración → Controles**.

**Reglas rápidas:** si la vida llega a 0 o la dopamina a 100, pierdes la zona. Con el celular abierto te curas (+5/s) pero subes la dopamina (+8/s) y te mueves más lento; con el celular cerrado la dopamina baja (−2/s). El jefe solo recibe daño cuando está aturdido.

**Teclas de debug** (solo en builds de depuración): `F1` invoca al jefe · `F2` lo aturde · `F3` fuerza el siguiente ataque · `F4` pasa a fase 2 · `F5` muestra la duración de la pelea · `F6` golpe de prueba.

## Zonas y jefes
| Zona | Escenario | Jefe |
|---|---|---|
| 1 | Calle | El Influencer Viral |
| 2 | Edificio Social | El Algoritmo |
| 3 | Zona de Carga | Capataz |
| 4 | Ascensor | Gemelo |
| 5 | Laboratorio | Dr. Dopamina |
| 6 | Supercomputadoras | Núcleo-∞ |

## Estructuras de datos
| TAD | Archivo | Uso en el juego |
|---|---|---|
| `Lista` (lista enlazada simple) | `comun/datos/lista.gd` | Colas de oleadas, rotación de ataques de los jefes, cajas de la Zona 3, historial de posiciones de la Zona 4 |
| `Cola` | `comun/datos/cola.gd` | Rotación de las pistas del menú de pausa |
| `Leaderboard` | `comun/datos/leaderboard.gd` | Ranking top 10 ordenado, guardado en archivo |
| `Registro` | `comun/datos/registro.gd` | Estado de la partida entre escenas y récord personal |

Ninguna usa el tipo `Array` de GDScript para guardar sus elementos.

## Estructura de carpetas
```
project.godot            Configuración, autoloads y acción de entrada "cachetada"
autoload/                Singletons que viven todo el juego (se registran en project.godot)
  ajustes.gd               Volumen, filtro de daltonismo, videos del celular, controles (user://ajustes.cfg)
  pausa.gd                 Menú de pausa y botón "II"
  transicion.gd            Fundido a negro entre zonas
  musica_global.gd         Música de menú y de juego
  muerte.gd                Pantalla de muerte (reintentar / menú)
menu/                    Menú principal (JUGAR, ARCADE, CONFIGURACIÓN, LEADERBOARD, ayuda) y su fondo animado
comun/                   Lo que comparten todas las zonas
  zona/oleadas.gd          Script raíz de cada zona: oleadas, invocar jefe, pasar de zona
  jugador/                 Jugador (jugador.gd) y viñeta del celular
  zombi/                   Zombi básico
  jefe/jefe_base.gd        Lógica común de los jefes de las zonas 3 a 6
  hud/                     HUD, pantalla del celular y borde punteado
  controles_tactiles/      Joystick y botones para móviles
  datos/                   TADs hechos a mano: Lista, Cola, Registro y Leaderboard
shaders/                 daltonismo.gdshader (accesibilidad) y vineta.gdshader (efecto del celular)
assets/                  audio/ (música y sonidos), video/ (videos del celular), imagenes/
zona_1 … zona_6/         Una carpeta por zona, todas con el mismo formato:
  zona_N.tscn              Escena de la zona (Mapa + Jugador + HUD) con sus valores de oleadas
  mapa/                    MapaZonaN.tscn (colisiones) + mapa.gd (dibujo placeholder)
  jefe/                    JefeX.tscn + jefe_x.gd (ataques) y ataques/ (proyectiles, zonas del piso)
```

## Cómo funciona (visión general)
1. `menu.gd` carga `zona_1.tscn` (JUGAR) o la zona elegida (ARCADE).
2. El nodo raíz de la zona usa `oleadas.gd`: lanza oleadas de zombis desde los bordes y, en la oleada 5, 10, 15…, invoca al jefe.
3. Los jefes de las zonas 3 a 6 heredan de `jefe_base.gd` (estados INTRO → ATACANDO → ATURDIDO, cola de ataques, cooldowns y fase 2). Los de las zonas 1 y 2 tienen su propia lógica, con el mismo contrato (señales `vida_cambiada` y `murio`, método `recibir_golpe`).
4. Al morir el jefe se limpia la zona y se pasa a la siguiente con `Transicion`. El Núcleo-∞ (zona 6) muestra la pantalla de victoria y pide un nombre para el **Leaderboard**.
5. Todo se dibuja por código (`_draw()`) como *placeholder*; cada bloque marcado `REEMPLAZAR` puede cambiarse por un sprite real.

### Datos guardados (carpeta `user://` de Godot)
`ajustes.cfg` (ajustes) · `record.txt` (récord de liberados) · `leaderboard.txt` (top 10, formato `nombre;libres;tiempo`).

### Capas de física
1 jugador · 2 enemigos · 3 obstáculos · 4 proyectiles · 5 jefe.

## Convenciones de código
- GDScript con **tabs** (ver `.editorconfig`), nombres y comentarios en español.
- Cada archivo empieza con un comentario que explica qué hace; los números de balance de cada jefe están en `const` al inicio de su script.

## Equipo
**Último Scroll Studios**, Universidad del Norte (Barranquilla, Colombia).

| Integrante | Rol |
|---|---|
| Samuel Navarro | Director de proyecto y de pruebas |
| José Daza | Director de diseño |
| Iván Rivas | Director de UI/UX |
| Manuel Hormechea | Director de documentación |

## Flujo de trabajo
Control de versiones con **GitHub Flow** (una rama por cambio e integración por *pull request*) y tareas en un tablero de **Trello**.
