# Parte 4b — Más suscriptores y dopamina en Scroll y Shadowban

Sobre la Parte 4. Solo cambian constantes y 3 scripts.

## Cambios
- **Suscriptores:** ahora llaman 8 zombis (10 en fase 2), antes 4 y 5 (`SUSC_CANT`, `SUSC_CANT_F2`). Sigue saliendo uno cada 0,4 s, así que el ataque dura ~3 s más. La condición «menos de 5 vivos» no cambió (`SUSC_SI_MENOS_DE`).
- **Shadowban:** además de frenarte, suma +6 de dopamina por segundo mientras estés dentro (`SHADOW_DOPA`). Con 6 s activa son hasta 36, y con el celular abierto se acumula con sus +8/s.
- **Scroll infinito (la cinta que te arrastra):** suma +8 de dopamina por segundo mientras estés en la franja (`SCROLL_DOPA`). Con 5 s activa son hasta 40.

Los valores son un punto de partida mío; el balance es tuyo.

## Archivos modificados
- zona_2/jefe/jefe_algoritmo.gd (constantes nuevas y paso de `dopa_seg` a cada zona)
- zona_2/jefe/ataques/cinta.gd, zona_2/jefe/ataques/shadowban.gd (variable `dopa_seg` y suma por frame)
- _entregas/constantes.md (regenerado)

## Checklist de prueba
- [ ] F9: llegan 8 zombis (10 con F4 antes).
- [ ] Meterte en la zona violeta del Shadowban: la barra de dopamina sube ~6/s.
- [ ] Quedarte en la franja del Scroll: sube ~8/s; salir de la franja o de la zona la deja de subir.

## Verificado (Godot 4.5 headless)
Dopamina sube dentro de ambas zonas y 8 zombis nuevos con F9. No probé el balance en pantalla.
