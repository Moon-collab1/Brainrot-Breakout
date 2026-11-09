# Parte 2 — JefeAlgoritmo base (sin ataques)

Sobre la Parte 1 (todo lo anterior se mantiene).

## Supuestos aplicados
- Insignias = clase interna `Insignia` dentro de jefe_algoritmo.gd (círculo + Label con los golpes que faltan); no hay escena aparte.
- JefeAlgoritmo.tscn es mínima (Node2D, Label «NombreAtaque», Timer «TimerEstado»); el orbe, ojo y tentáculos se dibujan en `_draw()`.
- El golpe a una insignia resta 1 a la más cercana de las que alcanza (≤ 100+22). Con el jefe aturdido solo cuenta el cuerpo (≤ 100+100).
- Las insignias nuevas se crean al empezar el aturdimiento (alfa 0,3), parpadean el último segundo y cuentan al terminar.
- F2 (aturdir) conserva las insignias actuales si quedaban; solo crea tanda nueva cuando no queda ninguna.
- Las tandas siguientes arrancan con un ángulo de órbita al azar.
- `jefe_esc` ya está asignado en zona_2.tscn para poder probar ya (la Parte 3 solo verifica la conexión).
- Aún no hay cola de ataques, cooldowns, sets ni Suscriptores: `iniciar_ataques()` es un esqueleto vacío. F3, F8 y F9 son provisionales.

## Archivos nuevos
- zona_2/jefe/JefeAlgoritmo.tscn
- zona_2/jefe/jefe_algoritmo.gd
- zona_2/jefe/ataques/.gitkeep

## Archivos modificados
- zona_2/zona_2.tscn: ext_resource del jefe + `jefe_esc`.

## Pasos manuales en el editor
Ninguno. F6 sobre zona_2.tscn. Godot generará los .uid de los scripts nuevos al abrir el proyecto.

## Teclas de debug (solo con el jefe en pantalla; F1 la maneja oleadas.gd)
F1 invoca · F2 aturde · F3 muestra el nombre de ataque 2 s (provisional) · F4 fase 2 · F5 imprime duración · F6 golpe a una insignia · F7 golpe al cuerpo · F8/F9 pendientes (Parte 4) · F10 revienta las 3 insignias.

## Checklist de prueba
- [ ] F1: el jefe aparece en (880,245) con fundido; el panel dice «JEFE: EL ALGORITMO» y la barra está llena.
- [ ] Tras 2 s hay 3 insignias girando (3, 4, 5) a radio 140; la cachetada al cuerpo no hace nada.
- [ ] Cachetear una insignia baja su número; al llegar a 0 revienta y la barra baja 1. Al reventar la tercera: «Visto» (ojo cerrado, tono azul, spinner) 5 s, y 3 insignias tenues (3, 4, 5) que parpadean el último segundo.
- [ ] Aturdido, cada cachetada al cuerpo baja 1 de vida. F4 → «FASE 2» y las insignias giran más rápido.
- [ ] Meterse en el cuerpo quita ~25 de vida/s (no en la intro). Al llegar a 0: el jefe desaparece, panel oculto, oleadas siguen tras 3 s.
- [ ] F3 muestra «SPAM DE NOTIFICACIONES ◂» bajo el jefe 2 s.

## No verificado (sin ejecutar Godot)
- Que los .tscn escritos a mano abran sin advertencias y que la clase interna `Insignia` compile sin avisos.
- Que el aspecto del placeholder (ojo, tentáculos) sea el deseado.
- Orden de dibujo: el jefe se coloca antes del Jugador (lo hace oleadas.gd); las insignias son hijas del jefe.

## Constantes nuevas (jefe_algoritmo.gd)
VIDA_MAX 60 · FASE2_VIDA 30 · RADIO_CUERPO 100 · DANO_CONTACTO 25 · ALCANCE_JUGADOR 100 · TIEMPO_INTRO 2 · TIEMPO_ATURDIDO 5 · PARPADEO_FINAL 1 · RADIO_ORBITA 140 · RADIO_INSIGNIA 22 · VEL_ORBITA 40 · MULT_ORBITA_F2 1.6 · DANO_INSIGNIA 1 · DANO_ATURDIDO 1 · TANDAS [[3,4,5],[3,4,5],[4,5,6]] · TANDA_REPETIDA [4,5,6] · ALFA_ESPERA 0.3 · RADIO_DIBUJO 108 · colores.
