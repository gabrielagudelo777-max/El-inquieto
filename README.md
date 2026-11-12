# El Inquieto: Asalto

Proyecto de videojuego arcade para PC desarrollado con Godot 4.7.2. La propuesta combina una arena 3D estilizada, cámara elevada fija y acción 2.5D inspirada en los juegos clásicos de oleadas.

## Abrir el proyecto

1. Instala o abre Godot 4.7.2.
2. Importa este repositorio seleccionando `project.godot`.
3. Abre `res://main.tscn` y ejecútala con F6 o F5.

## Diseño y controles previstos

- Cámara isométrica fija sobre una arena 3D.
- Movimiento libre en el plano del suelo: WASD o flechas; el personaje puede ir a izquierda, derecha, adelante y atrás dentro de la arena.
- El eje Y queda para altura y colisiones; el primer prototipo no incluye salto.
- Disparar: Espacio.
- Dash: Shift.
- Pausa: Esc.

El repositorio se está construyendo desde cero. Las áreas de campaña e interfaz, combate y movimiento/arte se integran en la rama compartida `Desarrollo`; `main` se reserva para versiones revisadas y estables.

El blockout de escenario y las secuencias de introducción y jefe están en `juan/escenario_plaza.tscn` y `juan/cinematicas.gd`. La escena es una base visual; el jugador y los sistemas de combate se integran en sus respectivos aportes.
