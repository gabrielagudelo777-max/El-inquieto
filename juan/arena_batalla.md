# Arena de batalla

Prototipo 3D de una arena espacial para recorrer y combatir. Toma de *Hades II* la cámara fija elevada, el espacio legible para esquivar y la lectura de amenazas. El arte mantiene los modelos espaciales de Gabriel y usa acentos luminosos cian y ámbar para unir el escenario con el menú.

## Controles

- WASD o flechas: moverse.
- Shift: dash corto.
- Espacio: disparar al objetivo más cercano.
- Esc: regresar al menú.

La primera versión incluye cinco alienígenas que persiguen al astronauta, disparos de energía, daño al traje e indicadores de amenazas e integridad.

## Recursos

- Astronauta y modelos espaciales: `assets/quaternius_ultimate_space/`.
- Criaturas y luces: `assets/quaternius_modular_scifi/`.
- Fondo de nebulosa: `assets/kenney_skyboxes_space/`.
- Marco de interfaz y tipografía: recursos que ya utiliza el menú.
- El paquete 2D de Larzes se usa como referencia de color y rim light; no está incluido en el repositorio.

La escena principal se mantiene en `main.tscn`, que abre la arena desde el botón Jugar del menú.
