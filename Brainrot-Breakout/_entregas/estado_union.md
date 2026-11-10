# Estado de la unión

- [x] Fase 1 · Unión
- [x] Fase 2 · HUD
- [x] Fase 3 · Celular
- [x] Fase 4 · Exportar y documentar

## Decisiones
- Base = ZIP A (parte 5). De B solo se copiaron zona_3 a zona_6 y comun/jefe/jefe_base.gd. Los demás archivos de B (menu.gd, menu.tscn, mapa_simple.gd, MapaZona1.tscn y copias viejas de hud, project.godot, zombi, lista, registro, icon.svg) no se usaron.
- Fusionados de forma aditiva (verificado con diff): jugador.gd (invertido_t, cel_bloqueado_t, control invertido, apagón del celular) y oleadas.gd (spawn_x_min/x_max/y_max/y_fondo con los defaults de siempre). zona_2.tscn: escena_siguiente → zona_3. Zona 6 no tiene escena_siguiente (victoria → zona_1).
- Zombis: el modelo viene de Brainrot-Breakout_zonas_3-6.zip (círculo verde con dos ojos blancos dibujado por _draw(), sin texturas). Se aplicó solo a comun/zombi/ (zombi.gd y zombi.tscn: se quitó el Sprite2D de icon.svg). API de A intacta: grupo «zombis», liberar(), vel_z, dano, RADIO=20 y su colisión. Ese zip solo trae este modelo; no hay modelos por zona, así que no se añadió zombi_esc.
- icon.svg: las escenas de zonas 3 a 6 llevaban el ExtResource sin uid; se les puso uid://bm24ys2gn1nw7 (el de A) para que todas coincidan.
- Textos acortados (Banner 282x86, fuente 28): «¡CONTROLES INVERTIDOS!» → «¡INVERTIDO!»; «¡CELULAR BLOQUEADO!» → «¡SIN CELULAR!»; «¡GANASTE! Usaste el celular con cuidado» → «¡GANASTE!» + un Label propio en victoria.gd con «Usaste el celular con cuidado» (no se toca el HUD; si no lo quieres, borrar la llamada a mostrar_mensaje).
- nombre_jefe acortado (LabelJefe 100 px, fuente 11), en el .tscn de la zona: «EL ALGORITMO» → «ALGORITMO» (zona_2.tscn, cambio mínimo en un archivo protegido, por estar indicado en la fase 2), «CAPATAZ BOT» → «CAPATAZ», «EL GEMELO DIGITAL» → «GEMELO», «DR. DOPAMINA» → «DOPAMINA». «INFLUENCER» y «NÚCLEO-∞» ya cabían.
- Firmas del HUD confirmadas: mostrar_jefe(bool), actualizar_jefe(valor, maximo) (conectada a la señal vida_cambiada), mostrar_banner(bool, texto), flash_blanco(seg). hud.gd, HUD.tscn, controles_tactiles.gd, project.godot, lista.gd, registro.gd, icon.svg y zona_1/* no se modificaron.
- F1-F9 de debug: todas protegidas con OS.is_debug_build() (oleadas, jefe_base y los jefes de zonas 1 y 2). No hay usos de teclado ni mouse fuera de eso.
- Rendimiento: solo se corrigió el redibujo del mapa de zona_4 (ahora solo cuando se mueve un pasamanos). El resto está listado en parte6_zonas_3_a_6.md.
- Pantallas anchas: no se cambió el stretch. Opciones de arreglo (color de fondo por zona / Camera2D centrada) descritas en parte6_zonas_3_a_6.md, pendientes de tu OK.

## Pendientes / no verificado
- No se ejecutó Godot: la verificación es estática (0 errores) y no prueba que el juego corra. Abrir el proyecto en el editor y mirar la consola al cargar cada zona.
- Probar en el editor con FORZAR_TACTIL = true (checklist en _entregas/exportar_y_probar.md) y luego en un celular real (Android y navegador).
- Ver a simple vista que quepan: Banner, LabelJefe y PanelZona (anchos calculados con otra fuente).
- Glifo «∞» en Web (puede verse como cuadrito).
- Confirmar a la vista que el apagón de zona_4 no oscurece HUD ni controles táctiles.
- Decidir si se aplica el arreglo de pantallas anchas (requiere tocar zona_1 y zona_2 .tscn).
- Observación menor heredada de A: error posible en consola si se muere dentro de los 0,15 s posteriores a una cachetada.
