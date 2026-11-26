# Personaje del jugador

El jugador ahora se instancia desde `juan/jugador_isometrico.tscn`. La escena conserva el cuerpo y la colisión 2D que usa la arena, y muestra el modelo 3D dentro de un `SubViewport` transparente. Así el caballero puede usar sus animaciones sin cambiar el movimiento ni las colisiones de la campaña.

## Animaciones conectadas

- Quieto: `Idle`.
- Movimiento: `Walk_*`.
- Carrera y esquive: `Run_*`.
- Disparo: `Sword_Shield_Slash_Down`.
- Daño y derrota: `Take_Damage` y `Death`.

La dirección de movimiento selecciona los clips de ocho direcciones incluidos en el modelo.

## Recurso y licencia

El modelo `assets/personajes_nuevos/caballero_retro/CaballeroRetro.glb` proviene de [N64/PS1 Animated Heroes](https://swickster.itch.io/n64ps1-animated-heroes), demo gratuita del autor swickster. La demo incluye caballero y goblin en GLB y FBX. Su archivo `Usage_Rights.txt` permite integrar y modificar los recursos en juegos y proyectos terminados; prohíbe redistribuirlos como archivos independientes. Se conserva ese archivo junto al modelo.
