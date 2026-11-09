# Parte 1 — Mapa de la Zona 2 + zona_2.tscn (sin jefe)

Sobre la Parte 0 (todo lo anterior se mantiene).

## Supuestos aplicados
- Las macetas son obstáculos (grupo «obstaculos», CircleShape2D r=22); los sofás van en «rebotables» (rectángulo 146×56, offset (0,2)).
- Todo el arte es placeholder dibujado en `zona_2/mapa/mapa.gd` (_draw); cada bloque dice «REEMPLAZAR» para cambiarlo por PNG en `zona_2/assets/`.
- Medidas exactas del Anexo B / tabla A2 (sofás, macetas, 4 límites, pantallas decorativas sin colisión).
- `jefe_esc` de la Zona 2 queda sin asignar (Parte 2): F1 y la oleada 10 solo muestran una advertencia en la consola y no hacen nada.
- En la Zona 1 se puso `escena_siguiente = "res://zona_2/zona_2.tscn"`: al morir el Influencer se espera 2,5 s y se carga la Zona 2 con los libres acumulados.

## Archivos nuevos
- zona_2/zona_2.tscn (raíz «Zona2» con comun/sistema/oleadas.gd: numero_zona 2, «EDIFICIO SOCIAL», «EL ALGORITMO», pos_jefe (880,245), ola_inicial 5, [14,16,18], paso 2, spawn_y_min 150)
- zona_2/mapa/MapaZona2.tscn, zona_2/mapa/mapa.gd
- zona_2/assets/.gitkeep, zona_2/jefe/ataques/ (carpetas para las Partes 2–4; en el zip solo se conservan si tienen archivos)

## Archivos modificados
- zona_1/zona_1.tscn: `escena_siguiente`.

## Pasos manuales en el editor
Ninguno. Para probar solo la Zona 2: abre `zona_2/zona_2.tscn` y pulsa F6 (la escena principal sigue siendo la Zona 1).

## Checklist de prueba
- [ ] F6 en zona_2.tscn: se ve el piso azul con baldosas, edificios y 3 pantallas arriba, 4 sofás y 2 macetas.
- [ ] El jugador no atraviesa sofás, macetas ni los 4 bordes (arriba se detiene en y≈124).
- [ ] El HUD dice «ZONA 2 · EDIFICIO SOCIAL · OLEADA 6» al salir la primera oleada (14 zombis).
- [ ] Oleadas 6–9: ningún zombi aparece encima de macetas ni del sofá de abajo (spawn en y≥150).
- [ ] F1 no rompe nada (solo advertencia en consola).
- [ ] Zona 1 sigue igual; al matar al Influencer carga la Zona 2 tras 2,5 s.

## No verificado (sin ejecutar Godot)
- Que los .tscn escritos a mano abran sin advertencias.
- Que el arte placeholder coincida al píxel con tu captura (medidas estimadas ±3 px).
- Que el zip incluya carpetas vacías: `zona_2/jefe/` aparecerá en la Parte 2.

## Constantes nuevas
mapa.gd: PISO_Y=124, BALDOSA=72, SOFAS, MACETAS, PANTALLAS, ALTURAS (posiciones de dibujo).
