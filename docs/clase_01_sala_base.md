# Clase 1 - sala base, cámara y control

## Objetivo de la clase

Dejar una sala cerrada que el jugador pueda recorrer sin atravesar sus límites, con una cámara que permita leer el espacio. Para Jhon, esta clase cubre el estado mínimo de partida y la transición al siguiente encuentro.

La clase no busca rehacer lo que ya está en el repositorio. Primero comprobamos el flujo activo; solo corregimos lo que falle o lo que impida integrar el slice.

## Estado actual encontrado en el repositorio

1. `project.godot` usa Godot 4.7.2 y establece `escenas/main_menu.tscn` como escena de inicio.
2. El botón de iniciar del menú lleva a `main.tscn`, que instancia `juan/arena_isometrica.tscn`.
3. `juan/arena_isometrica.gd` crea el jugador, la cámara, la arena y las paredes. El perímetro tiene colisión; el jugador también limita su posición al área jugable.
4. `juan/jugador_isometrico.gd` mueve al personaje con WASD/flechas, esquiva con Shift y dispara con Espacio. La cámara es hija del jugador y sigue su posición.
5. `juan/director_campana.gd` ya mantiene estados y avanza de una configuración a otra: `MENU`, `INTRO`, `COMBATE`, `INTERMISION`, `PAUSA`, `DERROTA` y `VICTORIA`, además de la presentación del jefe.
6. El avance actual está modelado como seis oleadas en la misma arena. Todavía no es la campaña de cuatro salas del *vertical slice*.

Esto es una inspección del código; todavía falta observar el comportamiento en Godot para saber si cámara, límites y movimiento se sienten bien.

## Recorrido y ajuste realizado con Jhon

En la prueba manual dentro de Godot se observó:

- El menú llega a la arena y la cámara sigue al jugador.
- WASD mueve al jugador; Shift activa un impulso corto; Espacio dispara. El ritmo de disparo queda pendiente de balance y no se modifica en este ajuste.
- Antes del cambio, W mostraba la cara del personaje y S mostraba su espalda, al contrario de la orientación deseada.
- En `jugador_isometrico.gd` se centralizó la selección de fila en `_fila_para_direccion()`. Se suma media vuelta (cuatro pasos de ocho) para alinear la orientación del sprite con la dirección de movimiento y disparo. Jhon confirmó que el cambio quedó bien en Godot.
- Se conectó la acción `correr` ya existente en InputMap (Ctrl) con velocidad y cadencia de animación de carrera; el menú de controles y los créditos ahora describen el juego activo como arena 2D isométrica.
- La cámara se considera correcta según la prueba de Jhon.
- Jhon confirmó en el árbol Remoto de Godot los cuatro `PilarDeCobertura`: sus `ColisionBase` verdes aparecen en ejecución y detienen al jugador. Las ruinas y braseros ornamentales siguen siendo decoración transitable.

La esquiva todavía se siente como un salto y se revisará en el siguiente ajuste de control, separando la animación del balance de velocidad. No se cambió su duración ni su enfriamiento en este paso.

## Responsabilidad de Jhon

En esta clase Jhon no debe crear un segundo `RunManager`: `DirectorCampana` ya es la fuente de verdad para el estado de partida. El trabajo es entender y estabilizar su contrato para el flujo:

```text
menú → preparación/intro → encuentro activo → encuentro limpio → siguiente encuentro
```

Por ahora conservamos los nombres `oleada` y `OleadaConfig` en el código existente. Los convertiremos a salas/configuraciones nuevas cuando el equipo esté listo para hacer esa migración con todas sus referencias. No cambiamos nombres solo para que coincidan con el documento.

## Secuencia de trabajo

### Paso 1 - abrir la copia correcta

- En GitHub Desktop, el proyecto de trabajo debe ser `El-inquieto` y la rama `codex/jhon-systems`.
- En Godot 4.7.2, abre `C:/Users/jhonj/OneDrive/Documentos/ChatGPT/INQUIETO/project.godot`.
- Ejecuta con F5 para iniciar desde el menú configurado. F6 ejecuta solo la escena abierta y no valida el flujo completo.

### Paso 2 - registrar el recorrido inicial

Sin editar scripts todavía, observa estos puntos y anota cualquier fallo:

- El menú abre y el botón de campaña entra a la arena.
- El jugador aparece dentro del perímetro y la cámara conserva una lectura clara.
- WASD y flechas mueven al jugador; Shift esquiva; Espacio dispara al objetivo actual.
- Las paredes y los pilares bloquean al jugador.
- Al limpiar la primera oleada aparece la intermisión y luego comienza la siguiente.
- El panel Output de Godot no muestra errores al iniciar ni durante ese recorrido.

Este recorrido nos da una referencia del estado actual antes de tocar código. No se añaden pruebas automatizadas en esta clase.

### Paso 3 - dibujar el flujo actual de estados

Con el recorrido observado, documentamos si cada transición funciona y su emisor/receptor:

| Momento | Fuente actual | Receptor actual | Resultado esperado |
|---|---|---|---|
| Iniciar campaña | Botón del menú / `UICampana` | `DirectorCampana.comenzar_campana()` | Comienza intro y después el primer encuentro. |
| Iniciar oleada | `DirectorCampana` | `oleada_iniciada` | Arena configura cantidad y ritmo de aparición. |
| Limpiar oleada | Enemigos derrotados | `registrar_enemigo_derrotado()` | El director entra a intermisión o termina campaña. |
| Avanzar | Temporizador de intermisión | `_iniciar_siguiente_oleada()` | Se activa la siguiente configuración. |

### Paso 4 - corregir solo los problemas de clase 1

Si el recorrido revela un fallo, primero identificamos qué archivo es dueño de la responsabilidad. Las reglas de estado y avance viven en `DirectorCampana`; la composición de sala/cámara vive en `arena_isometrica.gd`; el control del jugador vive en `jugador_isometrico.gd`; el HUD solo presenta los cambios.

Antes de tocar un archivo de otro integrante, registramos el cambio de interfaz que necesita y evitamos duplicar estado, contadores o temporizadores.

## Criterios de cierre

- [ ] Godot abre la copia correcta en la rama acordada.
- [ ] Se puede llegar desde el menú al primer encuentro.
- [ ] Movimiento y esquiva responden dentro de la sala.
- [ ] Paredes y pilares impiden atravesar límites.
- [ ] La cámara mantiene al jugador y el área relevante legibles.
- [ ] Al limpiar un encuentro, la partida avanza sin quedarse en estado bloqueado.
- [ ] Las transiciones de estado tienen una fuente de verdad y el HUD no contiene reglas de campaña.
- [ ] No se renombraron ni eliminaron recursos de oleadas durante este paso.

## Fuera de esta clase

El sistema de recompensas, la migración de seis oleadas a cuatro salas, los patrones propios del jefe, el balance final y el guardado local pertenecen a clases posteriores. Si durante el recorrido aparece una falla relacionada con vida, daño o jefe, la anotamos para la clase correspondiente y no ampliamos el alcance de esta clase sin necesidad.

## Siguiente paso con Jhon

La carga de `main.tscn` en Godot 4.7.2 se comprobó sin errores de script o recursos. La arena crea los pilares en `_ready()`, por lo que no aparecen en el árbol **Local** de `arena_isometrica.tscn` antes de ejecutar. Jhon ya verificó en **Remoto** que los cuatro colliders verdes bloquean.

Comprobación restante de Clase 1:

1. En una partida nueva, caminar hacia los límites exteriores de la sala y confirmar que el jugador permanece dentro.
2. Derrotar los seis enemigos de la primera oleada y observar que el director entra a intermisión y luego inicia la segunda oleada.
3. Revisar **Salida** por errores durante ese recorrido.

Luego se completa el recorrido de una oleada y se observa la intermisión y el comienzo de la siguiente. Así se cierra la Clase 1 con estado y transición comprobados, sin migrar todavía los seis recursos de oleada a las cuatro salas del slice.

## Cierre verificado con Jhon

- Las flechas ↑ y ↓ funcionaban; ← y → no. Se volvieron a registrar desde Input Map en Godot y Jhon confirmó que las cuatro flechas ya responden. WASD también funciona.
- Ctrl corre, Espacio dispara y Shift activa un impulso rápido.
- Jhon confirmó que los cuatro pilares bloquean al jugador y que no puede salir del perímetro de la sala.
- Al derrotar la oleada, aparece la pantalla «Sala completada» con cuenta regresiva para abrir el portal y avanzar. En la captura se observa `OLEADA 01 / 06` y el mensaje de sala completada.
- Jhon confirmó que la consola Salida no muestra errores durante la prueba.

**Resultado:** recorrido funcional de Clase 1 verificado. La esquiva se registra como impulso rápido y queda para el siguiente ajuste de control; el ritmo de disparo y la migración de oleadas a salas siguen fuera del alcance de esta clase.
