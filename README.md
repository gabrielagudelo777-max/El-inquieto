# El Inquieto: Asalto

Videojuego arcade para PC desarrollado con Godot 4.7.2. La partida activa es una arena 2D con presentación isométrica, movimiento libre y combate automático contra enemigos por oleadas. El menú usa un fondo 3D, pero la arena jugable actual es 2D.

## Abrir el proyecto

1. Abre el proyecto seleccionando `project.godot` en Godot 4.7.2.
2. Ejecuta con F5 para iniciar desde el menú.
3. El botón **Jugar** abre `res://main.tscn` y la arena isométrica.

## Diseño y controles previstos

- Cámara que sigue al personaje en una arena 2D isométrica.
- Movimiento: WASD o flechas; Ctrl corre.
- Disparar: Espacio.
- Dash: Shift.
- Pausa: Esc.

El flujo jugable actual usa seis oleadas en una misma arena. El vertical slice planificado migrará a cuatro salas y tres elecciones de mejora antes del jefe final; esa migración todavía no está implementada.

La escena inicial configurada es `escenas/main_menu.tscn`; `main.tscn` instancia `juan/arena_isometrica.tscn`. `juan/escenario_plaza.tscn` es un prototipo 3D separado y no se carga en la partida activa.
