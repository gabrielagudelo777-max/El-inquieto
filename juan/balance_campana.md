# Aporte de Juan — dirección de campaña y balance

## Fantasía de juego

El Inquieto defiende una arena futurista contra formaciones que descienden por oleadas. La acción se presenta en 16:9 para PC, con entorno y modelos 3D, cámara elevada fija y movimiento arcade principalmente horizontal (2.5D). El jugador dispara hacia la formación y usa el dash para esquivar.

## Bucle de partida

Menú → introducción breve y saltável → oleada → intermisión → nueva oleada/jefe → victoria o derrota → resumen y reinicio.

Las cinemáticas serán secuencias breves dentro de Godot con cámara, animación, audio y rótulos; nunca bloquearán permanentemente el control y tendrán opción de saltar.

## Alcance acordado para la primera versión jugable

Primero se completa una partida corta de seis oleadas y un jefe final. La campaña de doce oleadas, jefes adicionales, rutas, escudos y skins se tratan como ampliaciones posteriores. El equipo puede reutilizar formaciones y patrones para ampliar la duración sin crear doce sistemas distintos.

## Balance inicial para probar

| Oleada | Enemigos | Frecuencia de goblin de rango | Intervalo de aparición | Rapidez | Disparo de rango | Puntos | Intermisión |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 6 | 0 % | 0,90 s | 1,20 | — | 100 | 5 s |
| 2 | 8 | 20 % | 0,80 s | 1,30 | 2,80 s | 100 | 5 s |
| 3 | 10 | 30 % | 0,75 s | 1,40 | 2,60 s | 120 | 6 s |
| 4 | 12 | 40 % | 0,70 s | 1,50 | 2,40 s | 120 | 6 s |
| 5 | 14 | 50 % | 0,65 s | 1,60 | 2,20 s | 150 | 8 s |
| 6 | Jefe (28 de vida) | Aparecen ambos refuerzos | — | 1,70 | Refuerzos: 3,20 s | 1000 | — |

Son valores de partida, no de balance final. En las oleadas 1–5 sube gradualmente la cantidad, la rapidez y la proporción de enemigos de rango. El intervalo de disparo se aplica al goblin de rango y se acorta por oleada. Durante el jefe aparece una pareja inicial de goblins (uno cercano y uno de rango); después puede llegar otra pareja cada 10 s, hasta cuatro refuerzos activos. Los refuerzos no adelantan la derrota del jefe ni prolongan la oleada una vez derrotado. El jefe conserva por ahora su ataque de contacto; su ataque a distancia se agregará en una etapa posterior. La duración final dependerá del tiempo real de combate y se medirá en pruebas.

## Responsabilidad de Juan

- Director de estados y progresión de campaña.
- Definición editable de parámetros de oleada y tabla de balance.
- HUD de vidas, puntaje, récord y oleada.
- Menú de inicio, pausa, intermisión, derrota y victoria.
- Secuencias narrativas y transiciones cortas, saltables.

## Contrato para integración

El spawner escucha `oleada_iniciada(indice, configuracion)` y lee la configuración recibida. Cuando instancia la cantidad solicitada, notifica `registrar_enemigos_generados(cantidad)`. Cada baja llama `registrar_enemigo_derrotado(puntos)` y cada impacto al jugador llama `recibir_impacto(cantidad)`. El HUD escucha las señales del director; no sondea nodos del combate cada frame.

El jefe puede completar una oleada mediante `registrar_enemigo_derrotado(puntos, true)` para que el director espere tanto a que el jefe sea derrotado como a que no queden apariciones pendientes.
