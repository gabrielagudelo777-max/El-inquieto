# Plan de trabajo — campaña, interfaz y balance

## Alcance

Cerrar primero la Fase 1 descrita en la matriz de diseño y dejar la Fase 2 preparada para una segunda etapa. El trabajo se integra en la arena que ya abre el botón Jugar. Los cambios se documentan en la carpeta `juan` y se publican en las ramas `Juan` y `Desarrollo`.

El pulido de animaciones del jugador y los enemigos, y el ajuste del cooldown del arma quedan bajo responsabilidad de Jhon. La campaña debe poder mostrar el estado del cooldown, pero no cambiar su valor ni rehacer esas animaciones sin coordinación.

## Orden de ejecución

1. **Integrar la campaña en la arena** — conectar `DirectorCampana`, las seis configuraciones existentes, aparición escalonada de enemigos, derrota, victoria, pausa e intermisiones. Mantener el combate y la arena actuales como base.
2. **Completar el HUD de la Fase 1** — mostrar vidas, integridad/escudo, puntaje, multiplicador, oleada, tiempo transcurrido y estado/vida del jefe. La cadencia del arma se leerá desde el jugador; su balance lo define Jhon.
3. **Cerrar navegación y resultados** — alta de récord en el menú, transiciones de inicio, pausa, derrota, victoria y reinicio; definir la elección de ruta de la tercera oleada según la matriz.
4. **Consolidar el balance** — crear recursos editables de campaña, alinear cantidades, intervalos, puntos y tiempos de intermisión con `balance_campana.md`, y documentar los valores de partida.
5. **Revisión de integración** — revisar las escenas conectadas y documentar pendientes. No se marcará una función como terminada solo porque exista un script o una escena aislada.
6. **Fase 2, después de cerrar la vertical slice** — bienvenida y cuenta local, seis módulos del menú, loadout, tienda, perfil, logros, monedas/cristales, poderes activos y pasivas, continuación con cristales, rutas/desafíos e Inquieto Extremo.

## Estado inicial del repositorio

- Ya existen `DirectorCampana`, `UICampana`, seis recursos `OleadaConfig` y una tabla de balance. No están insertados en la escena principal jugable.
- `main.tscn` inicia cinco enemigos fijos; no hay spawner de oleadas conectado.
- El menú tiene Jugar, Controles, Créditos y Salir. Jugar abre la arena.
- El HUD de campaña contempla vidas, puntaje, récord y oleada, pero está desconectado y no incluye todos los indicadores de Fase 1.
- No se encontraron pantallas de loadout, tienda, perfil ni logros.

## Decisión pendiente antes de implementar el encuentro de jefes

La tabla pide barras para tres jefes en la Fase 1, mientras que el balance actual define una sola oleada final llamada «El Asediador». Antes de construir esos encuentros hay que aclarar si son tres barras simultáneas, tres jefes en oleadas distintas o una barra para el jefe de la vertical slice y las otras dos como expansión.

## Seguimiento

- [ ] Integrar director y aparición de oleadas en la arena.
- [ ] Conectar bajas, daño, vidas, derrota y victoria.
- [ ] Completar HUD de Fase 1.
- [ ] Incorporar récord y flujo de pausa/resultados en navegación.
- [ ] Consolidar balance en recursos editables.
- [ ] Revisar y cerrar pendientes de Fase 1.
- [ ] Planificar e implementar Fase 2.
