# Parte 4 — Ataques de El Algoritmo (+ constantes.md)

Sobre la Parte 3. Entrego toda la Parte 4 junta (cola, los 5 ataques y el cambio de set) porque ya se pueden probar todos con las teclas de debug. La Zona 1 no se tocó.

## Supuestos aplicados
- Orden de la cola: spam → scroll → shadowban → recomendado → suscriptores. Se saca el primero y se reinserta al final; si está en cooldown o no cumple su condición se prueba el siguiente; si ninguno sirve espera 0,5 s.
- Condiciones: «Recomendado» solo si `jugador.ultimo_liberado != ""`; «Suscriptores» solo si hay menos de 5 zombis vivos. **F3 (forzar) ignora cooldown y condiciones**, igual que con el Influencer.
- Burbujas y clon nacen en el borde del orbe (`RADIO_SALIDA = 110`), no en el centro: con el Set C el centro queda dentro del sofá 1.
- **Gracia de 0,25 s** (cambio mío): al nacer, burbuja y clon solo detectan al jugador (máscara 1) y a los 0,25 s pasan a máscara 5 (jugador + obstáculos). Sin eso, con el jugador arriba, las burbujas nacían rozando la pared de arriba (y=124) y reventaban al instante. Después de la gracia los obstáculos y límites las destruyen como pide la hoja.
- Cinta y Shadowban se insertan con `move_child(x, 1)` (justo encima del Mapa), como la franja de la Zona 1.
- Nombre del ataque («SPAM DE NOTIFICACIONES ◂», etc.) bajo el jefe durante el aviso de los cinco ataques.
- «Recomendado»: la copia semitransparente (icon.svg ×0,4) y la línea roja se dibujan en el borde del orbe hacia el jugador; la línea sigue 0,6 s y se bloquea 0,4 s. El clon es icon.svg ×0,4 teñido de rojo. El punto donde se cargaría la escena según `ultimo_liberado` está marcado con «AQUÍ:» en `disparar_clon()`.
- Cambio de set: igual que el Influencer (0,5 + 0,5 + 0,5 s, cada 2–3 ataques, nunca el mismo set). Las insignias se ocultan mientras dura y reaparecen al terminar o al aturdir.
- F8 y F9 ya no son provisionales: F8 fuerza un cambio de set, F9 fuerza «Suscriptores» (ambos cancelan el ataque en curso y la cola se reanuda al terminar).
- Los `.uid` de los scripts los generó Godot al abrir el proyecto; van incluidos (ahora todos los `.gd` tienen el suyo).

## Archivos nuevos
- zona_2/jefe/ataques/burbuja.tscn + burbuja.gd (+ .uid)
- zona_2/jefe/ataques/cinta.tscn + cinta.gd (+ .uid)
- zona_2/jefe/ataques/shadowban.tscn + shadowban.gd (+ .uid)
- zona_2/jefe/ataques/clon.tscn + clon.gd (+ .uid)
- _entregas/parte4.md, _entregas/constantes.md
- .uid de scripts que no lo tenían: hud.gd, corazon.gd, franja.gd, jefe_influencer.gd, jefe_algoritmo.gd, mapa.gd

## Archivos modificados
- zona_2/jefe/jefe_algoritmo.gd: constantes de los ataques, cola con la Lista, `bucle_ataques`, `siguiente_ataque`, `avisar`, los 5 ataques, `cambiar_set`, `mostrar_insignias`, aviso de «Recomendado» en `_draw`, cooldowns en `_process`, `aturdir()` ahora también corta el cambio de set, y teclas F3/F8/F9.
- Eliminado: zona_2/jefe/ataques/.gitkeep (ya no hace falta).

## Rutas movidas
Ninguna.

## Pasos manuales en el editor
Ninguno. F6 sobre zona_2.tscn.

## Teclas de debug (con el jefe en pantalla y ATACANDO)
F1 invoca · F2 aturde · **F3 fuerza el siguiente ataque de la cola** · F4 fase 2 · F5 duración · F6 golpe a insignia · F7 golpe al cuerpo · **F8 cambio de set** · **F9 Suscriptores** · F10 revienta las 3 insignias.

## Checklist de prueba
- [ ] F1, esperar la intro y dejar correr la cola: aparece cada ataque con su nombre bajo el jefe (spam → scroll → shadowban → recomendado → suscriptores) y entre ataques hay ~1,5 s de pausa.
- [ ] Spam: 2 tandas de 4 burbujas en abanico que te persiguen; tocarlas sube la dopamina +6 sin quitar vida; X las revienta y NO suma a «Liberados». En fase 2 (F4) salen 5 por tanda.
- [ ] Scroll: franja naranja de ~110 px de alto en tu y; 1 s después te arrastra 5 s hacia un lado (se frena contra sofás/macetas); salir de la franja corta el arrastre. Shadowban: círculo punteado → zona violeta de radio 100 que te frena (con el celular abierto, aún más); en fase 2 salen 2 zonas.
- [ ] Recomendado: primero libera un zombi con X (si no, se salta; F3 lo fuerza igual). Línea roja que te sigue y se bloquea; el clon vuela recto, quita 10 de vida y te empuja; X lo revienta.
- [ ] Suscriptores: banner «¡SUSCRÍBETE!» y llegan 4 zombis (5 en fase 2) solo si hay menos de 5. F8: el jefe se desvanece, aparece en otro set (A/B/C) y sigue atacando. Con el Set C (a la izquierda) las burbujas salen bien aunque solape el sofá 1.
- [ ] F2 / romper las 3 insignias durante un ataque: se borran burbujas, clon, cinta y zonas, el banner se oculta, los zombis se quedan. F2 en pleno cambio de set deja al jefe visible y con insignias.

## Verificado (con Godot 4.5 headless, no con el editor 4.7)
- El proyecto importa sin errores de parseo.
- Simulación de 150 s (cola completa, fase 2, 7 cambios de set, 5 aturdimientos, cachetadas al azar): sin errores de script y los 5 ataques se ejecutaron varias veces.
- Pruebas puntuales: dopamina +6 por burbuja y sin daño de vida; la cinta arrastra 140 px/s; Shadowban pone `mult_vel = 0.6` dentro y 1.0 fuera; el clon quita 10 y empuja; la cachetada revienta burbujas sin sumar libres; aturdir deja 0 proyectiles y 0 franjas; la burbuja que choca con un sofá tras la gracia desaparece.

## No verificado
- El aspecto de los placeholders (cinta, zona, burbujas, línea de «Recomendado») y el «feel» del balance: no vi el juego en pantalla.
- Que Godot 4.7 no cambie nada respecto a 4.5 con estos .tscn escritos a mano.
- Con la pausa de 1,5 s y los cooldowns actuales la rotación se puede sentir muy cargada o muy relajada: el balance es tuyo (lista completa en `_entregas/constantes.md`).
