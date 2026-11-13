# Aporte de Juan — dirección de campaña y balance

## Fantasía de juego

El Inquieto defiende una arena futurista contra formaciones que descienden por oleadas. La acción se presenta en 16:9 para PC, con entorno y modelos 3D, cámara elevada fija y movimiento arcade principalmente horizontal (2.5D). El jugador dispara hacia la formación y usa el dash para esquivar.

## Bucle de partida

Menú → introducción breve y saltável → oleada → intermisión → nueva oleada/jefe → victoria o derrota → resumen y reinicio.

Las cinemáticas serán secuencias breves dentro de Godot con cámara, animación, audio y rótulos; nunca bloquearán permanentemente el control y tendrán opción de saltar.

## Alcance acordado para la primera versión jugable

Primero se completa una partida corta de seis oleadas y un jefe final. La campaña de doce oleadas, jefes adicionales, rutas, escudos y skins se tratan como ampliaciones posteriores. El equipo puede reutilizar formaciones y patrones para ampliar la duración sin crear doce sistemas distintos.

## Balance inicial para probar

| Oleada | Apariciones/enemigos | Intervalo de aparición | Rapidez de formación | Intervalo entre disparos enemigos | Puntos | Intermisión |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 6 | 0,90 s | 1,20 m/s | 3,00 s | 100 | 5 s |
| 2 | 8 | 0,80 s | 1,30 m/s | 2,80 s | 100 | 5 s |
| 3 | 9 | 0,75 s | 1,40 m/s | 2,60 s | 120 | 6 s |
| 4 | 10 | 0,70 s | 1,50 m/s | 2,40 s | 120 | 6 s |
| 5 | 12 | 0,65 s | 1,60 m/s | 2,20 s | 150 | 8 s |
| 6 | Jefe | — | patrón propio | patrón propio | 1000 | — |

Son valores de partida, no de balance final. En las oleadas 1–5 la presión aumenta en pasos pequeños: hay más enemigos, aparecen algo más rápido y disparan con menor intervalo. El jefe tiene comportamiento propio y no se modela como un enemigo común con más puntos. La duración final dependerá del tiempo real de combate, la puntería y los patrones; se medirá en pruebas antes de prometer un tiempo de campaña.

## Responsabilidad de Juan

- Director de estados y progresión de campaña.
- Definición editable de parámetros de oleada y tabla de balance.
- HUD de vidas, puntaje, récord y oleada.
- Menú de inicio, pausa, intermisión, derrota y victoria.
- Secuencias narrativas y transiciones cortas, saltables.

## Contrato para integración

El spawner escucha `oleada_iniciada(indice, configuracion)` y lee la configuración recibida. Cuando instancia la cantidad solicitada, notifica `registrar_enemigos_generados(cantidad)`. Cada baja llama `registrar_enemigo_derrotado(puntos)` y cada impacto al jugador llama `recibir_impacto(cantidad)`. El HUD escucha las señales del director; no sondea nodos del combate cada frame.

El jefe puede completar una oleada mediante `registrar_enemigo_derrotado(puntos, true)` para que el director espere tanto a que el jefe sea derrotado como a que no queden apariciones pendientes.
