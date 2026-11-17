# El Inquieto - arquitectura y ruta de trabajo

## Propósito y alcance

Este documento convierte los tres documentos de diseño del equipo y el estado actual del repositorio en un mapa de implementación. Los PDF son propuestas del 13 de noviembre de 2026; sus decisiones abiertas no se tratan como requisitos cerrados.

La ruta inicial será un *vertical slice*: una zona de cuatro salas, con jefe en la sala 4, y una mejora seleccionable después de cada una de las salas 1, 2 y 3. La selección de mejoras en esos tres momentos fue confirmada por Jhon. El número de salas y la ubicación del jefe siguen el plan propuesto y deben mantenerse como objetivo de trabajo mientras el equipo no acuerde un cambio.

## Base técnica revisada

- Repositorio de trabajo: `gabrielagudelo777-max/El-inquieto`, rama `Desarrollo`.
- Base de esta rama: `origin/Desarrollo` en `47dcaa7` (`Renovar la arena y simplificar el HUD`, 16 de noviembre de 2026).
- Motor indicado por el proyecto: Godot 4.7.2.
- La versión activa es un juego 2D con presentación isométrica (`Node2D`, `CharacterBody2D`, `TileMapLayer`). El menú contiene un fondo 3D, separado de la arena jugable.
- El repositorio `el-inquieto-videojuego` contiene otro prototipo de sigilo. No forma parte de esta ruta.
- El prototipo local de Jhon de nave y formaciones queda preservado en la rama local `jhon/clase-1`; no se integra automáticamente al juego actual.

## Qué existe y qué falta

| Área | Estado actual del repositorio | Objetivo del vertical slice |
|---|---|---|
| Entrada | `project.godot` abre `escenas/main_menu.tscn`; `main.tscn` instancia la arena isométrica. | Conservar el flujo de menú y entrar a la primera sala. |
| Mundo | `juan/arena_isometrica.gd` construye una arena y su presentación desde código. | Reutilizar la base visual y separar sala/configuración de la lógica de encuentros. |
| Campaña | `juan/director_campana.gd` coordina estados y seis `OleadaConfig`. | Usar un flujo de cuatro salas, tres encuentros con recompensa y un jefe final. |
| Aparición | El bucle de aparición y el contador de enemigos están dentro de `arena_isometrica.gd`. | Llevar la responsabilidad del encuentro a un controlador pequeño con inicio y cierre explícitos. |
| Jugador | `juan/jugador_isometrico.gd` mueve, esquiva, dispara al enemigo más cercano y administra integridad. | Exponer estadísticas y señales para aplicar mejoras sin poner reglas dentro del HUD. |
| Enemigos | `juan/enemigo_isometrico.gd` persigue y daña por proximidad; el jefe comparte ese comportamiento base. | Configurar enemigos y dar al jefe del slice al menos un patrón propio y legible. |
| Recompensas | Existe `escenas/upgrade_card.tscn`, pero no se encontró un catálogo ni aplicación de mejoras conectados al flujo. | Presentar opciones después de las salas 1-3, validar la elección y aplicarla una sola vez por sala. |
| Interfaz | `juan/ui_campana.gd` presenta estados del director y HUD mediante señales. | La UI muestra opciones y comunica el ID elegido; no calcula ni aplica efectos. |
| Guardado | No se encontró guardado de progreso activo en la ruta del slice. | Mantener el progreso temporal en memoria durante una partida. Evaluar guardado local después del slice. |

## Árbol objetivo de archivos

Conservamos los módulos actuales del equipo y agregamos solo los sistemas de Jhon necesarios para el slice. Los nombres son tentativos; antes de renombrar recursos existentes se revisarán sus referencias en Godot.

```text
res://
├── project.godot
├── main.tscn
├── escenas/
│   ├── main_menu.tscn / main_menu.gd
│   └── upgrade_card.tscn
├── assets/
│   ├── arena_isometrica/
│   ├── personajes_nuevos/
│   └── fonts/
├── gabriel/
│   └── jugador.gd / jugador.tscn       # prototipo/presentación; confirmar uso en el flujo activo
├── juan/
│   ├── arena_isometrica.gd / .tscn     # composición visual de la arena
│   ├── director_campana.gd             # coordinador actual del flujo de partida
│   ├── ui_campana.gd / .tscn            # HUD, menús y pantallas
│   ├── jugador_isometrico.gd           # movimiento y acciones del personaje actual
│   ├── enemigo_isometrico.gd
│   ├── proyectil_isometrico.gd / .tscn
│   ├── oleada_config.gd
│   └── oleadas/                         # datos existentes; migrar con referencias verificadas
└── jhon/
    ├── datos/
    │   ├── sala_config.gd              # Resource: identidad, tipo y encuentro de una sala
    │   └── recompensa_config.gd         # Resource: ID, título, descripción y efecto
    ├── encuentros/
    │   └── controlador_encuentro.gd    # aparición, enemigos activos y señal de sala limpia
    ├── recompensas/
    │   └── sistema_recompensas.gd      # opciones válidas y aplicación de la elección
    └── jefes/
        └── controlador_jefe.gd          # patrones y fases; entra en la clase 5
```

### Regla para no duplicar sistemas

`DirectorCampana` ya es el coordinador real de estados, pausa, campaña y resultado. Para el slice será la única fuente de verdad del flujo. No crearemos otro `RunManager` en paralelo. Jhon desarrollará los sistemas de encuentros y recompensas y acordará con el equipo las señales/métodos que necesiten añadirse al director. Si más adelante el equipo decide renombrarlo o dividirlo, se hará como refactor explícito.

`arena_isometrica.gd` debe quedarse a cargo de construir la escena y conectar nodos. El controlador de encuentro informará `encuentro_iniciado` y `encuentro_limpiado`; el director decide la transición de campaña; el HUD representa el estado. Ningún script de UI decide cuándo una sala terminó ni aplica daño/mejoras.

## Flujo de estados del slice

```text
MENÚ
  └─ iniciar → PREPARACIÓN / INTRO
       └─ sala 1: ENCUENTRO
            └─ sala limpia → RECOMPENSA
                 └─ elección validada → sala 2: ENCUENTRO
                      └─ sala limpia → RECOMPENSA
                           └─ elección validada → sala 3: ENCUENTRO
                                └─ sala limpia → RECOMPENSA
                                     └─ elección validada → sala 4: JEFE
                                          ├─ jefe derrotado → VICTORIA
                                          └─ jugador sin vida → DERROTA

PAUSA conserva el estado al que debe volver.
DERROTA / VICTORIA permiten reintentar o volver al menú.
```

La recompensa se presenta después de cada una de las tres primeras salas, según la decisión de Jhon. La mejora se guarda en el estado de la partida y modifica estadísticas usadas en encuentros posteriores; no se persiste entre partidas en este alcance.

## Contratos de integración

| Emisor | Evento/dato | Receptor | Regla |
|---|---|---|---|
| Jugador | `integridad_cambiada(actual)` y `murio` | Director y HUD | El jugador determina su integridad; el director cambia el estado al agotarse las vidas según la regla acordada. |
| Encuentro | `encuentro_iniciado(id)` / `encuentro_limpiado(id)` | Director | Solo se limpia cuando todos los enemigos configurados fueron derrotados y no quedan apariciones pendientes. |
| Enemigo/jefe | `derrotado(puntos, es_jefe)` | Controlador de encuentro | Cada enemigo se cuenta una vez; el jefe notifica su derrota de forma explícita. |
| Director | `estado_cambiado`, `sala_cambiada`, `recompensas_disponibles` | HUD y pantallas | La UI escucha datos, presenta opciones y emite la selección. |
| Pantalla de recompensa | `recompensa_elegida(id)` | Sistema de recompensas/director | El ID se valida contra las opciones ofrecidas; no se confía en texto visual enviado por la UI. |
| Sistema de recompensas | `recompensa_aplicada(id)` | Estado de partida/jugador | Cada elección se aplica una vez; sus efectos duran hasta terminar o perder la partida. |

Los nombres definitivos se ajustarán al código actual y se documentará cualquier cambio antes de integrar escenas de otros integrantes.

## Ruta por clases

Las clases corresponden al plan de trabajo de ocho sesiones. La división respeta los roles propuestos, ajustada al repositorio actual. El criterio de cierre es observable y acotado; no significa que toda la expansión quede implementada.

| Clase | Trabajo de Jhon | Integración del equipo | Criterio de cierre |
|---|---|---|---|
| 1. Sala base y flujo | Acordar estado mínimo y datos/índice de sala; definir transición sin duplicar `DirectorCampana`. | Gabriel mantiene movimiento/cámara; Juan conecta HUD y escena. | Se puede iniciar la partida y avanzar al primer encuentro en una arena con límites claros. |
| 2. Vida, daño y esquiva | Definir una sola autoridad para vida/daño, invulnerabilidad y muerte; exponer señales estables. | Gabriel aporta animación/efectos; Juan presenta feedback de HUD. | Jugador ataca, esquiva, recibe daño y llega a derrota de forma consistente. |
| 3. Encuentro y enemigos | Crear el controlador de encuentro; configurar apariciones, conteo activo y condición de sala limpia. | Gabriel integra movimiento/animación; Juan ajusta ritmo y HUD. | El encuentro inicia y cierra sin enemigos invisibles ni contadores bloqueados. |
| 4. Recompensas | Crear `RecompensaConfig`, ofrecer opciones y aplicar una elección por cada sala 1-3. | Juan construye tarjeta/pantalla; Gabriel integra respuesta visual. | Una elección cambia una estadística que se puede comprobar en la sala siguiente. |
| 5. Jefe de la zona 1 | Configurar al jefe de sala 4 con estados/patrones y condición inequívoca de derrota. | Gabriel integra arena y telegráficos; Juan balancea y presenta vida de jefe. | El jugador puede leer el ataque y ganar o perder el encuentro del jefe. |
| 6. Diseño de expansión | Documentar cómo los recursos describirían 12 salas y tres jefes; no construir tres zonas completas todavía. | Gabriel diferencia lenguaje visual; Juan define progresión y balance. | Hay una configuración de expansión revisable sin bloquear el slice. |
| 7. Cierre de partida | Integrar pausa, derrota, victoria y reinicio usando el estado central existente. | Juan conecta pantallas; Gabriel integra transiciones y audio. | Se puede iniciar, pausar, terminar y volver a jugar sin escena bloqueada. |
| 8. Integración | Revisar contratos, rutas de recursos y criterios de la entrega; preparar compilación reproducible. | Todo el equipo resuelve integración. | La ruta completa del slice se puede recorrer y sus elecciones/combates se entienden. |

El desglose de tareas, recorrido inicial y criterios de cierre de la primera clase está en [clase_01_sala_base.md](clase_01_sala_base.md).

## Decisiones todavía abiertas

1. **Apuntado:** el jugador actual dispara automáticamente al enemigo más cercano. Los documentos piden validar si se conserva, se apunta con movimiento o con mouse. No cambiar el sistema de apuntado dentro del trabajo de recompensas.
2. **Número de encuentros y balance:** salud, daño, frecuencia de aparición, invulnerabilidad y duración se fijan al probar el slice; los valores actuales son provisionales.
3. **Recursos de campaña:** decidir cómo representar sala/jefe en datos sin romper los seis `.tres` existentes ni sus referencias.
4. **Pausa y selección:** definir si se permite pausar sobre la pantalla de recompensa.
5. **Guardado local:** se deja después del slice salvo que la entrega académica lo exija.
6. **Assets/licencias:** verificar licencia y atribución de cada asset antes de distribuir; el repositorio ya registra fuentes para parte del arte de la arena.
7. **Hito académico:** confirmar con el equipo si el 19 de noviembre de 2026 sigue vigente.

## Observaciones de integración pendientes

- El jugador ya consulta la acción `correr` de InputMap (Ctrl); menú, HUD y README usan el mismo control.
- La arena actual llama “sala” a los seis tramos, aunque los datos se llaman oleadas y todos reutilizan la misma escena. La conversión a cuatro salas debe reflejarse en datos, estado y HUD, no solo en etiquetas.
- `upgrade_card.tscn` existe, pero antes de reutilizarlo hay que inspeccionar su estructura y decidir qué datos expone para la selección.
- Se retiró el prototipo de batalla 3D (`arena_batalla`, `jugador_batalla`, `enemigo_batalla`, `proyectil_batalla`) porque no tenía referencias desde el flujo principal. También se retiró `escenas/control.tscn`, una plantilla vacía sin referencias. Los assets compartidos y las escenas del equipo se conservan.
- La rama local `jhon/clase-1` conserva un prototipo previo de nave. Mantenerlo como referencia separada mientras construimos sobre el commit actual de `Desarrollo`.

## Orden de implementación acordado

Primero se revisará este mapa con Jhon y se confirmará el control de apuntado y los contratos del jugador. Luego se construirá el flujo de salas y encuentros, después recompensas, y al final el jefe y el cierre de partida. Cada módulo se integrará con señales/métodos públicos pequeños; se evitarán renombres masivos y lógica de reglas dentro de la UI.
