# Escenario y puesta en escena — La Plaza del Reenvío

## Decisión de cámara y movimiento

El mundo será 3D con cámara ortográfica isométrica fija. El personaje se mueve libremente por el plano del suelo (ejes X/Z), dentro de los límites de la plaza. El eje Y se reserva para altura, animaciones y colisiones; no habrá salto en la primera versión.

Esta decisión deja que el jugador esquive en cuatro direcciones y recorra la arena, mientras el homenaje a Space Invaders aparece en las formaciones, el avance enemigo, las oleadas y las lluvias de proyectiles. Las coberturas crean rutas y decisiones de posicionamiento.

## Blockout jugable

`escenario_plaza.tscn` crea una plaza de 30 × 22 unidades con suelo, bordes con colisión, tres coberturas, puestos, una buseta de utilería, mural, iluminación, cámara y puntos de aparición. Los materiales y formas son provisionales para probar lectura y escala; posteriormente se reemplazarán o vestirán con arte final.

- Inicio del jugador: `(0, 0.1, 8.5)`.
- Entradas de formación: `(-10, 0.5, -7.5)`, `(0, 0.5, -8.5)` y `(10, 0.5, -7.5)`.
- Límite recomendado para el centro del jugador: X `[-12.5, 12.5]`, Z `[-9, 9]`.
- Las coberturas están alrededor de Z `3.5`; conviene no hacerlas tan altas que tapen enemigos y proyectiles.

## Secuencias cinemáticas

- **Introducción (3 s):** zoom y desplazamiento de cámara sobre la plaza, con un rótulo de alerta. Empieza al iniciar campaña.
- **Entrada de jefe (2,5 s):** acercamiento breve y título con el nombre del jefe. Se ejecuta antes de activar la oleada final.
- **Saltar:** Esc o botón en pantalla. Al saltarla, la cámara vuelve a la vista normal y el juego continúa.

`CinematicasEscenario` emite `control_jugador_bloqueado(bool)` durante la secuencia y `cinematica_finalizada(tipo)` al terminar. El controlador del personaje deberá conectarse a esas señales cuando se integre.

## Identidad colombiana

Los objetos de utilería —puesto de arepas/tinto, buseta, mural, grafiti y luces de plaza— aportan contexto local sin depender de marcas. Los enemigos de farándula se diseñarán como personajes satíricos originales y reconocibles por arquetipos (político de tarima, estrella del fútbol, influencer viral), con nombres, modelos y frases propios. Eso deja que el humor sea del juego y que los personajes se puedan adaptar al tono del grupo.

## Contrato para integración

- El script del jugador limita su posición llamando a `limitar_posicion_jugador(posicion)` o usando los mismos rangos exportados.
- El spawner puede localizar nodos del grupo `entrada_enemigos`.
- El jugador puede ubicarse en el marcador del grupo `inicio_jugador`.
- El input del jugador será libre en X/Z; la puntería/rumbo de los disparos debe acordarse con el responsable del combate antes de fijar el proyectil definitivo.
- Los bunkers de la escena son geometría de blockout. Jhon puede reemplazarlos por su escena con salud/degradación cuando su sistema esté listo.
