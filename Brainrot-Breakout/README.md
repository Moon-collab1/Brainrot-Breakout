# Brainrot Breakout

Juego 2D de acción (Godot 4.7, renderer GL Compatibility) hecho para la Feria Gamer de la Universidad del Norte.
Eres un jugador atrapado en el *doomscrolling*: libera zombis con cachetadas, usa el celular para curarte
(¡pero cuidado con la dopamina!) y derrota a un jefe al final de cada una de las 6 zonas.

## Cómo abrirlo
1. Abre Godot 4.7 → **Import** → selecciona `project.godot`.
2. Ejecuta con **F5** (la escena principal es `menu/menu.tscn`).
3. Exporta a Web/Android si quieres: los controles táctiles se activan solos en pantallas táctiles.

## Controles
| Acción | Teclado | Táctil |
|---|---|---|
| Moverse | Flechas | Joystick flotante (mitad izquierda) |
| Cachetada | **X** | Botón CACHETADA |
| Abrir/cerrar celular | Espacio / Enter | Botón CELULAR |
| Pausa | Esc | Botón **II** |

**Reglas rápidas:** vida a 0 o dopamina a 100 = pierdes la zona. Con el celular abierto te curas (+5/s) pero
subes la dopamina (+8/s) y te mueves más lento. Cada 5 oleadas aparece el jefe, que solo recibe daño cuando está aturdido.

**Teclas de debug** (solo en builds de depuración): `F1` invoca al jefe · `F2` lo aturde · `F3` fuerza el siguiente ataque ·
`F4` pasa a fase 2 · `F5` muestra la duración de la pelea · `F6` golpe de prueba.

## Estructura de carpetas
```
project.godot            Configuración, autoloads y acción de entrada "cachetada"
autoload/                Singletons que viven todo el juego (se registran en project.godot)
  ajustes.gd               Volumen, filtro de daltonismo, videos del celular (user://ajustes.cfg)
  pausa.gd                 Menú de pausa y botón "II"
  transicion.gd            Fundido a negro entre zonas
  musica_global.gd         Música de menú y de juego
menu/                    Menú principal (JUGAR, ARCADE, CONFIGURACIÓN, LEADERBOARD, ayuda «?») y su fondo animado
comun/                   Lo que comparten todas las zonas
  zona/oleadas.gd          Script raíz de cada zona: oleadas, invocar jefe, pasar de zona
  jugador/                 Jugador (jugador.gd) y viñeta del celular
  zombi/                   Zombi básico
  jefe/jefe_base.gd        Lógica común de los jefes de las zonas 3 a 6
  hud/                     HUD, pantalla del celular y borde punteado
  controles_tactiles/      Joystick y botones para móviles
  datos/                   Lista enlazada propia, Registro (estado/récord) y Leaderboard (top 10)
shaders/                 daltonismo.gdshader (accesibilidad) y vineta.gdshader (efecto del celular)
assets/                  audio/ (música y sonidos), video/ (videos del celular), imagenes/
zona_1 … zona_6/         Una carpeta por zona, todas con el mismo formato:
  zona_N.tscn              Escena de la zona (Mapa + Jugador + HUD) con sus valores de oleadas
  mapa/                    MapaZonaN.tscn (colisiones) + mapa.gd (dibujo placeholder)
  jefe/                    JefeX.tscn + jefe_x.gd (ataques) y ataques/ (proyectiles, zonas del piso)
```

## Cómo funciona (visión general)
1. `menu.gd` carga `zona_1.tscn` (JUGAR) o la zona elegida (ARCADE).
2. El nodo raíz de la zona usa `oleadas.gd`: lanza oleadas de zombis desde los bordes; en la oleada 5, 10, 15… invoca al jefe.
3. Los jefes de las zonas 3–6 heredan de `jefe_base.gd` (estados INTRO → ATACANDO → ATURDIDO, cola de ataques,
   cooldowns, fase 2). Los de las zonas 1 y 2 tienen su propia lógica, con el mismo contrato (señales `vida_cambiada` y `murio`, método `recibir_golpe`).
4. Al morir el jefe se limpia la zona y se pasa a la siguiente con `Transicion`. El Núcleo-∞ (zona 6) muestra la
   pantalla de victoria y se pide un nombre para el **Leaderboard** (se ordena por liberados y, en empate, por tiempo).
5. Todo se dibuja por código (`_draw()`) como *placeholder*; cada bloque marcado `REEMPLAZAR` puede cambiarse por un sprite real.

### Datos guardados (carpeta `user://` de Godot)
`ajustes.cfg` (ajustes) · `record.txt` (récord de liberados) · `leaderboard.txt` (top 10, formato `nombre;libres;tiempo`).

### Capas de física
1 jugador · 2 enemigos · 3 obstáculos · 4 proyectiles · 5 jefe.

## Convenciones de código
- GDScript con **tabs** (ver `.editorconfig`), nombres y comentarios en español.
- Cada archivo empieza con un comentario que explica qué hace; los números de balance de cada jefe están en `const` al inicio de su script.
