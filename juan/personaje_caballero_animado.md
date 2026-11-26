# Personaje animado

`jugador_batalla.tscn` es la escena del jugador en la versión 3D de Juan. Reúne la cápsula de colisión, el script de movimiento y el caballero riggeado. `jugador_batalla.gd` selecciona las animaciones de quieto, caminar, correr, ataque, daño y derrota; el movimiento elige entre las ocho direcciones disponibles.

Esta rama conserva su controlador 3D: movimiento con WASD, dash, disparo automático al enemigo cercano y daño con invulnerabilidad. La integridad del jugador se conecta al sistema de vidas de `DirectorCampana`. No usa las filas de sprites 2D de `jugador_isometrico.gd`, así que la corrección de carga del script 2D en `Desarrollo` no requiere cambios en este controlador.

El modelo `assets/personajes_nuevos/caballero_retro/CaballeroRetro.glb` procede de la demo gratuita [N64/PS1 Animated Heroes](https://swickster.itch.io/n64ps1-animated-heroes). Se conserva el archivo `Usage_Rights.txt` junto al recurso: permite integrarlo en el juego y prohíbe redistribuirlo separado como paquete de assets.
