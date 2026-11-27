# Aporte de Juan — dirección de campaña y balance

## Fantasía de juego

El Inquieto defiende una arena futurista contra formaciones que descienden por oleadas. La acción se presenta en 16:9 para PC, con entorno y modelos 3D, cámara elevada fija y movimiento arcade principalmente horizontal (2.5D). El jugador dispara hacia la formación y usa el dash para esquivar.

## Bucle de partida

Menú → introducción breve y saltável → oleada → intermisión → nueva oleada/jefe → victoria o derrota → resumen y reinicio.

Las cinemáticas serán secuencias breves dentro de Godot con cámara, animación, audio y rótulos; nunca bloquearán permanentemente el control y tendrán opción de saltar.

## Alcance acordado para la primera versión jugable

Primero se completa una partida corta de seis oleadas y un jefe final. La campaña de doce oleadas, jefes adicionales, rutas, escudos y skins se tratan como ampliaciones posteriores. El equipo puede reutilizar formaciones y patrones para ampliar la duración sin crear doce sistemas distintos.

## Balance inicial para probar

| Oleada | Enemigos | Goblin de rango | Goblin de área | Intervalo de aparición | Rapidez | Disparo de rango | Proyectil de rango | Puntos | Intermisión |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 12 | 15 % | 0 % | 0,55 s | 2,00 | 2,00 s | 500 velocidad / 10 daño | 100 | 5 s |
| 2 | 30 | 25 % | 0 % | 0,30 s | 2,80 | 1,40 s | 550 velocidad / 12 daño | 100 | 5 s |
| 3 | 55 | 40 % | 0 % | 0,20 s | 3,50 | 1,00 s | 600 velocidad / 14 daño | 120 | 6 s |
| 4 | 85 | 45 % | 15 % | 0,15 s | 4,20 | 0,80 s | 650 velocidad / 16 daño | 120 | 6 s |
| 5 | 120 | 45 % | 30 % | 0,10 s | 5,00 | 0,60 s | 700 velocidad / 20 daño | 150 | 8 s |
| 6 | Jefe (160 de vida) | Refuerzos cercanos y de rango | — | — | Jefe: 4,50 | Refuerzos: 1,00 s | 620 velocidad / 16 daño | 1000 | — |

Esta configuración aplica una subida deliberadamente brusca para que el desplazamiento y el dash sean centrales. Los porcentajes de enemigos alternativos se calculan al aparecer cada unidad. En la oleada 4 hay 15 % de probabilidad de enemigo de área y 45 % de rango; en la oleada 5, 30 % de área y 45 % de rango. Los enemigos normales tienen cinco puntos de integridad, los de área marcan un radio de 190 durante 0,65 s y causan 28 de daño cada 2,8 s. El contacto de un goblin causa 18 de daño; la cadencia y velocidad de proyectil de los goblins de rango se ajustan por oleada.

El jefe combina contacto y dos patrones de misil alternos. El misil teledirigido sigue al jugador con giro limitado, se mueve a 650 y causa 20 de daño al impactar. El misil de asalto se desplaza a 420 hacia la posición fijada al lanzarlo; al llegar, marca un radio de 230 durante 0,7 s y causa 32 de daño si el jugador sigue en la zona. El jefe alterna estos ataques cada 2 s mientras el jugador esté a su alcance y tiene 160 de vida. Aparece una pareja inicial de goblins (uno cercano y uno de rango); después llega otra pareja cada 3,5 s, hasta ocho refuerzos activos. Los refuerzos no cuentan para completar la oleada del jefe.

Estos son valores de dificultad alta para la siguiente revisión jugable, no un balance final. La duración y la dificultad efectiva dependen del tamaño real de la arena, el daño del jugador y el comportamiento del dash; se ajustarán después de jugar la versión integrada.

## Responsabilidad de Juan

- Director de estados y progresión de campaña.
- Definición editable de parámetros de oleada y tabla de balance.
- HUD de vidas, puntaje, récord y oleada.
- Menú de inicio, pausa, intermisión, derrota y victoria.
- Secuencias narrativas y transiciones cortas, saltables.

## Contrato para integración

El spawner escucha `oleada_iniciada(indice, configuracion)` y lee la configuración recibida. Cuando instancia la cantidad solicitada, notifica `registrar_enemigos_generados(cantidad)`. Cada baja llama `registrar_enemigo_derrotado(puntos)` y cada impacto al jugador llama `recibir_impacto(cantidad)`. El HUD escucha las señales del director; no sondea nodos del combate cada frame.

El jefe puede completar una oleada mediante `registrar_enemigo_derrotado(puntos, true)` para que el director espere tanto a que el jefe sea derrotado como a que no queden apariciones pendientes.
