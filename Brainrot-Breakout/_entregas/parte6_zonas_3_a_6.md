# Parte 6 — Zonas 3 a 6 (unión con la base táctil)

## Qué hace
- Suma al proyecto de la parte 5 las zonas 3 «Zona de carga» (Capataz), 4 «Ascensor» (Gemelo digital), 5 «Laboratorio» (Dr. Dopamina) y 6 «Supercomputadoras» (Núcleo-∞, jefe final).
- La cadena queda: zona_1 → zona_2 → zona_3 → zona_4 → zona_5 → zona_6 → (victoria) → zona_1. La zona 6 no tiene `escena_siguiente`; su victoria reinicia en zona 1 a los 6 s.
- Los jefes 3 a 6 heredan de `comun/jefe/jefe_base.gd` (intro, cola de ataques con la `Lista` propia, aturdimiento, fase 2, daño por contacto, teclas de debug).
- El jugador gana dos efectos que ponen los jefes: «Control invertido» (zona 5) y «Apagón del celular» (zona 6). Funcionan igual con teclado y con los controles táctiles.
- Los textos largos se acortaron para que quepan en el HUD de la parte 5 (que no se tocó).

## Archivos
- NUEVOS (copiados de zonas_3_a_6.zip sin cambios de lógica): zona_3/ a zona_6/ completas y comun/jefe/jefe_base.gd.
- FUSIONADOS (A + lo aditivo de B):
  - comun/jugador/jugador.gd: `invertido_t`, `cel_bloqueado_t`, bloque «Control invertido» (`dir = -dir`) y bloque «Apagón del celular» (el `elif` de `ui_accept`).
  - comun/sistema/oleadas.gd: `@export spawn_x_min/spawn_x_max/spawn_y_max/spawn_y_fondo` (defaults = los de siempre) y `punto_borde()` los usa.
  - zona_2/zona_2.tscn: `escena_siguiente = "res://zona_3/zona_3.tscn"` y `nombre_jefe = "ALGORITMO"` (ver abajo).
- MODIFICADOS por compatibilidad con el HUD / celular:
  - zona_5/jefe/jefe_dopamina.gd: banner «¡CONTROLES INVERTIDOS!» → «¡INVERTIDO!».
  - zona_6/jefe/jefe_nucleo.gd: banner «¡CELULAR BLOQUEADO!» → «¡SIN CELULAR!».
  - zona_6/jefe/ataques/victoria.gd: banner «¡GANASTE!» + Label propio «Usaste el celular con cuidado» (CanvasLayer propio, no toca el HUD).
  - zona_2..zona_5 .tscn: `nombre_jefe` acortado (ALGORITMO, CAPATAZ, GEMELO, DOPAMINA) para que «JEFE: …» quepa en LabelJefe (100 px, fuente 11).
  - zona_3..zona_6 .tscn: el ExtResource de icon.svg lleva `uid://bm24ys2gn1nw7` (el mismo que usan zonas 1 y 2).
  - zona_4/mapa/mapa.gd: ya no hace `queue_redraw()` cada cuadro; redibuja solo si un pasamanos cambia de posición.
- SIN CAMBIOS (de A): hud.gd, HUD.tscn, controles_tactiles.gd, project.godot, lista.gd, registro.gd, icon.svg, zona_1/*, zombi.
- NO usados de B (eran versiones viejas de placeholder, gana A): menu.gd, menu.tscn, mapa_simple.gd, zona_1/mapa/MapaZona1.tscn y las copias de hud, project.godot, zombi, lista, registro, icon.svg.

## Constantes
Todas las de balance de zonas 3 a 6 están en `_entregas/constantes.md` (mismo estilo que zonas 1 y 2).

## Pantallas anchas (informe, no se cambió nada)
El mundo mide 1152x648 y el stretch es «expand». En un celular 19.5:9 la ventana pasa a ~1404x648: el mapa queda pegado a la izquierda y sobra una franja de ~250 px a la derecha con el color de fondo por defecto de Godot (gris). Zonas 1, 2, 3, 5 y 6 se ven así. La zona 4 tiene una `Camera2D` en (576, 324), así que su franja se reparte a ambos lados (~126 px cada uno). El HUD y los botones táctiles se calculan con el tamaño real, así que quedan en los bordes de la pantalla y no se desacomodan; la zona jugable sigue siendo 1152x648.
Arreglo mínimo, como opción aparte (no aplicado):
1. Color de fondo por zona: `@export var color_fondo: Color` en oleadas.gd y, en `_ready`, `RenderingServer.set_default_clear_color(color_fondo)`; se asigna el color del piso en cada zona (requiere tocar zona_1 y zona_2 .tscn, por eso queda pendiente de tu OK).
2. Camera2D centrada en (576, 324) en las zonas que no la tienen: reparte la franja a ambos lados (como ya hace la zona 4). Se puede combinar con 1.

## Pausa en vertical (revisado)
`controles_tactiles` pausa el árbol en vertical y `create_timer()` corre en pausa por defecto. Solo se usa en dos sitios:
- `jugador.dar_cachetada` (0,15 s): no causa problema; mientras está pausado el jugador no procesa entradas, y el timer solo oculta el dibujo del golpe.
- `oleadas.pasar_de_zona` (2,5 s): sigue contando en pausa y cambia de escena; el cambio es correcto y la escena nueva vuelve a evaluar la orientación. No causa problema real.
Los jefes no usan `create_timer`: usan nodos `Timer` y tweens ligados al nodo, que sí se pausan con el árbol.
Observación menor (ya existía en A, sin tocar): si el jugador muere dentro de los 0,15 s posteriores a una cachetada, `perder()` recarga la escena y la línea `$Golpe/Dibujo.visible = false` se ejecuta con el nodo ya liberado (puede salir un error en consola, no cierra el juego).

## Rendimiento móvil
- Corregido: mapa de zona_4 (de 1 redibujo por cuadro a solo cuando se mueve un pasamanos).
- Sin tocar (lista):
  - `oleadas._process`: `get_nodes_in_group("zombis").size()` cada cuadro (copia el arreglo).
  - `zombi._physics_process`: `get_parent().get_node("Jugador")` por zombi y por cuadro (se podría cachear).
  - zona_3 `cinta_carga._process`: `get_nodes_in_group("zombis")` cada cuadro mientras la cinta está activa y `queue_redraw()` siempre; `caja_carga` lo hace al caer.
  - `queue_redraw()` por cuadro en `jefe_base` y en proyectiles/ataques (charco, cerebro, laser, dato, reflejo, clon_espejo, cajas, cintas): necesario mientras se mueven; costoso solo con muchos a la vez.
  - `jefe_base.obstaculo_en` recorre los grupos «rebotables» y «obstaculos» en cada consulta.

## No verificado
- No pude ejecutar Godot aquí. Hice verificación estática (ExtResource/SubResource, rutas `res://`, uid de icon.svg, aridad de las funciones llamadas entre archivos y existencia de los atributos que los jefes leen/escriben en el jugador y la raíz): 0 errores. Esto NO prueba que el juego corra.
- Anchos de texto calculados con DejaVu Sans y Liberation Sans como referencia; la fuente real de Godot es otra, así que hay que ver en pantalla el banner, LabelJefe y PanelZona.
- El glifo «∞» de «NÚCLEO-∞»: si falta en la fuente por defecto, en Web puede verse como cuadrito (en Web no hay fuentes del sistema como respaldo). Mirarlo en el navegador; si falla, quitar «-∞» en `nombre_jefe` de zona_6.tscn.
- CanvasModulate + PointLight2D del apagón (zona 4): por diseño del motor solo afectan a su propia capa del canvas (la 0, el mundo), no al HUD (CanvasLayer) ni a los controles táctiles (capa 5). Falta confirmarlo a la vista.
- Todo en celular real: toques, rendimiento y control invertido con el joystick.
