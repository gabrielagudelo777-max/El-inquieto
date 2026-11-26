# Personaje del jugador

La escena activa del jugador vuelve a usar la hoja original `assets/personajes_nuevos/jugador_armadura.png`. `juan/jugador_isometrico.tscn` reúne el cuerpo 2D, su colisión y el sprite. El script conserva movimiento, dash, disparo, vida e invulnerabilidad.

La hoja tiene cuadros de 256 × 256 organizados en ocho filas. Esta etapa muestra un cuadro fijo de la fila de orientación inicial; la siguiente etapa conectará los cuadros a animaciones y a las ocho direcciones para que el personaje pueda verse de frente, de espalda y de lado.

El modelo 3D del caballero y sus commits se conservan en el historial y en `assets/personajes_nuevos/caballero_retro/`, pero ya no se usan en la escena activa de la versión compartida.
