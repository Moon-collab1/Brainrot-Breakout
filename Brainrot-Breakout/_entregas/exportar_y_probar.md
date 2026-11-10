# Exportar, probar en celular y checklist manual

No se incluye `export_presets.cfg`: se crea en el editor (Project → Export). Lo siguiente es lo que se configura en cada caso.

## Antes de exportar (ambos casos)
1. Abre el proyecto en Godot 4.7 y comprueba que `controles_tactiles.gd` tenga `FORZAR_TACTIL = false`.
2. Editor → Manage Export Templates → Download and Install (la versión debe ser exactamente la del editor).
3. Renderer: el proyecto ya usa GL Compatibility (`rendering_method` y `rendering_method.mobile`). No lo cambies.
4. Para la entrega, exporta SIN «Export With Debug»: así `OS.is_debug_build()` es falso y las teclas F1-F9 no hacen nada.

## (a) Web
1. Project → Export → Add… → Web.
2. Opciones: Thread Support = desactivado (así no hacen falta cabeceras COOP/COEP ni HTTPS), Extensions Support = desactivado, Progressive Web App = opcional (si lo activas, pon Orientation = Landscape).
3. Export Project (no «Export PCK/ZIP»), en una carpeta vacía, con el nombre `index.html`. Desmarca «Export With Debug».
4. Probar en local: `python3 -m http.server 8060 --directory <carpeta_export>` y abrir `http://localhost:8060`. Para el celular: misma red Wi-Fi, abrir `http://<IP-del-PC>:8060` en Chrome/Safari del celular.
5. itch.io: comprime la carpeta (con `index.html` en la raíz del zip) → New project → Kind of project = HTML → sube el zip → «This file will be played in the browser» → Viewport 1152x648 → activa «Fullscreen button» (y «Mobile friendly» si aparece).
6. GitHub Pages: sube el contenido de la carpeta a una rama (`gh-pages` o `/docs`), agrega un archivo vacío `.nojekyll`, activa Pages en Settings y abre `https://<usuario>.github.io/<repo>/`.
7. Notas: la detección táctil usa `JavaScriptBridge` (ya existe); en iOS/Android el navegador no bloquea la orientación, por eso el juego se pausa y pide girar el celular en vertical. Hay que mirar si «∞» se ve bien.

## (b) Android (APK)
1. Instala JDK y Android SDK (Android Studio o solo las command-line tools). Las versiones exactas de platform-tools, build-tools y platform están en la página oficial «Exporting for Android» de tu versión de Godot; usa esas.
2. Editor → Editor Settings → Export → Android: Java SDK Path y Android SDK Path. (El editor puede crear el debug keystore; si no, crea uno con `keytool`.)
3. Project → Export → Add… → Android. Deja «Use Gradle Build» desactivado (usa la plantilla ya instalada).
4. Keystore de release (una sola vez, guárdalo fuera del repositorio):
   `keytool -v -genkey -keystore brainrot.keystore -alias brainrot -keyalg RSA -keysize 2048 -validity 10000`
   En el preset: Keystore → Release, Release User (alias) y Release Password. Mejor por variables de entorno (`GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `..._USER`, `..._PASSWORD`) para no guardar la clave en `export_presets.cfg`.
5. Package → Unique Name (por ejemplo `com.equipo.brainrotbreakout`), Name = Brainrot-Breakout, Architectures = arm64-v8a (basta para celulares actuales; agrega armeabi-v7a solo si necesitas equipos viejos).
6. Permisos: no marques ninguno; el juego no necesita cámara, almacenamiento ni red. Si el preset trae INTERNET marcado, desmárcalo.
7. Pantalla: `project.godot` ya tiene `handheld/orientation=4` (horizontal por sensor), así que en el APK la pantalla no pasa a vertical. Si quieres, activa Immersive Mode en el preset.
8. Export Project → `.apk` (Release, sin «Export With Debug»).
9. Instalar: pasa el APK al celular y ábrelo (permite «instalar apps desconocidas»), o con cable: activa «Depuración USB» y usa el botón de Android arriba a la derecha del editor (Remote Debug). `adb install brainrot.apk` también sirve.

## Checklist de prueba manual (editor)
Preparación: en `controles_tactiles.gd` pon `FORZAR_TACTIL = true` (volver a `false` al terminar); Project Settings → Input Devices → Pointing → «Emulate Touch From Mouse» activado. Usa el mouse como dedo: joystick = arrastrar en la mitad izquierda; botones abajo a la derecha. Para ir directo al jefe usa F1 (solo en el editor); F2 aturde, F3 fuerza el siguiente ataque, F4 pasa a fase 2.
Para cada zona abre la escena (F6) y comprueba además: «ZONA n · NOMBRE · OLEADA n» sin cortarse, «JEFE: …» sin pisar la barra, cachetada y celular con los botones.

- [ ] Zona 1: igual que antes. Banner «¡SÍGUEME!» del Llamado.
- [ ] Zona 2: banner «¡SUSCRÍBETE!». «JEFE: ALGORITMO». Al vencerlo carga la zona 3 a los 2,5 s y conserva «Liberados».
- [ ] Zona 3 (Capataz): Embestida (la marca sigue 0,6 s y se bloquea; queda aturdido 2 s al chocar y ahí se le pega), Lluvia de cajas (marca antes de caer, máximo 6), Cintas aceleradas (arrastran al jugador y a los zombis, invierten cada 2,6 s), Turno doble. «JEFE: CAPATAZ».
- [ ] Zona 4 (Gemelo): zombis solo salen dentro del ascensor. Reflejo, Clones de espejo, Sacudida de cables (la cámara tiembla, los pasamanos saltan y se redibujan en su nueva altura), Apagón: pantalla oscura con círculo de luz y el HUD y los botones táctiles NO se oscurecen. Ventana «¡DESINCRONIZADO!» cada 2 ataques.
- [ ] Zona 5 (Dr. Dopamina): Nube tóxica, Jeringazo (queda agotado 3 s), Cerebros mutantes y Control invertido: banner «¡INVERTIDO!» cabe en el cuadro; el joystick va al revés 4 s (5 s en fase 2) y luego vuelve. «JEFE: DOPAMINA».
- [ ] Zona 6 (Núcleo-∞): Rejilla láser, Tormenta de datos, Apagón del celular: banner «¡SIN CELULAR!»; el celular se cierra y el botón CELULAR no lo abre durante 6 s. Ventana de daño cada 3 ataques. Al morir: «¡GANASTE!» + «Usaste el celular con cuidado», y a los 6 s vuelve a zona 1. Mirar «NÚCLEO-∞».
- [ ] Ventana angosta/ancha: cambia el tamaño de la ventana a ~2:1 y mira la franja vacía y que el HUD siga en los bordes.
- [ ] Hacer la ventana más alta que ancha: debe pausar y pedir girar; al volver a horizontal continúa.
- [ ] Release: exporta sin debug y confirma que F1-F6 no hacen nada.
