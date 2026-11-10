# Parte 3 — Conexión y prueba del jefe quieto

Sobre la Parte 2. **No hay cambios de código**: la conexión ya quedó hecha en las Partes 0–2 y la revisé línea por línea.

## Qué se revisó (por lectura, sin ejecutar Godot)
- `oleadas.gd.invocar_jefe()` ya está parametrizado: usa `jefe_esc` y `pos_jefe` de la raíz, conecta `vida_cambiada` → `HUD.actualizar_jefe` y `murio` → `_al_morir_jefe` ANTES de `add_child`, y lo mueve antes del Jugador.
- Zona 2: `ola_inicial = 5`, tamaños [14,16,18] → oleadas 6, 7, 8, 9 con zombis y la 10 es el jefe (`n_ola % 5 == 0`).
- `jugador.dar_cachetada()` llama `recibir_golpe(global_position)` a todo el grupo «jefe»: llega a las insignias y al cuerpo aturdido.
- `_al_morir_jefe()` limpia zombis, «proyectiles» y «franjas», oculta panel y banner; con `escena_siguiente = ""` las oleadas siguen tras 3 s.

## Aviso
Con la Zona 3 sin existir, la oleada 15 de la Zona 2 volvería a invocar a El Algoritmo (la regla `% 5` no cambia). Es comportamiento esperado hasta que exista `escena_siguiente`.

## Checklist de prueba (zona_2.tscn, F6)
- [ ] Sin tocar F1: matar zombis hasta la oleada 10; sale «Oleada 10: JEFE» en la consola y aparece el jefe con la intro.
- [ ] Barra del jefe llena (60) y baja 1 por insignia reventada.
- [ ] Romper las 3 insignias → «Visto» → bajarle vida con cachetadas.
- [ ] Bajar de 30 de vida → «FASE 2» en consola.
- [ ] Vida 0 → mensaje «Pelea terminada en X s», limpieza y la oleada 11 a los 3 s.
- [ ] Morir tú (vida 0 o dopamina 100) reinicia la Zona 2 limpia.
