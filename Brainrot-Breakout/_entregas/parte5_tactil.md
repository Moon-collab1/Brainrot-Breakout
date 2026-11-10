# Parte 5 — Controles táctiles (celular y tableta)

## Qué hace
- Joystick flotante: toca en la mitad izquierda de la pantalla y arrastra (se ve un círculo de guía en reposo).
- Botón rojo CACHETADA y botón azul CELULAR en la esquina inferior derecha.
- Solo aparece en pantallas táctiles (en PC no se ve nada).
- Si el celular está en vertical, el juego se pausa y pide girarlo.

## Archivos
- NUEVO: comun/controles_tactiles/controles_tactiles.gd (todo se dibuja por código, no hay .tscn)
- MODIFICADO: comun/hud/hud.gd (agrega `_ready()` que crea los controles; cambia los textos de ayuda a «Botón …» si es táctil)
- MODIFICADO: project.godot (`window/handheld/orientation=4`, solo afecta exports Android/iOS)

## Constantes (controles_tactiles.gd)
FORZAR_TACTIL=false, RADIO_BASE=85, RADIO_PERILLA=36, RADIO_BOTON_GOLPE=62, RADIO_BOTON_CEL=46, ZONA_MUERTA=0.12.

## Probar en PC
Pon `FORZAR_TACTIL = true` y en Project Settings → Input Devices → Pointing activa «Emulate Touch From Mouse».

## No verificado
No pude ejecutar Godot aquí: el script está revisado a mano, no probado. Probar primero en el editor (con FORZAR_TACTIL) y luego en un celular real.
