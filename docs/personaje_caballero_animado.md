# Personaje del jugador

La escena activa del jugador vuelve a usar la hoja original `assets/personajes_nuevos/jugador_armadura.png`. `juan/jugador_isometrico.tscn` reúne el cuerpo 2D, su colisión y el sprite. El script conserva movimiento, dash, disparo, vida e invulnerabilidad.

La hoja tiene cuadros de 256 × 256 organizados en ocho filas de orientación. El jugador reproduce los primeros cuatro cuadros de la fila correspondiente mientras se mueve, siguiendo el mismo intervalo de 0,14 s y el cálculo de dirección que usan los enemigos. Al correr y esquivar, el ciclo se acelera; al detenerse, queda en el primer cuadro de la última orientación para conservar la vista de frente, espalda o lado.

El modelo 3D del caballero y sus commits se conservan en el historial y en `assets/personajes_nuevos/caballero_retro/`, pero ya no se usan en la escena activa de la versión compartida.
