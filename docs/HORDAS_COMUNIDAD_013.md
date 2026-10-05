# El Cerco 0.13 — Hordas y gestión de comunidad

Continúa la base de supervivencia de 0.12. Mantiene sus expediciones, 18 planos, armas, investigación, guardado v6 y final con la cura.

## Jefes con habilidades y respuesta del jugador

| Jefe | Habilidad | Preparación | Respuesta |
|---|---|---|---|
| El Cantor | Cura 35 PV a infectados a 9 m, sin superar su máximo | 2,5 s, círculo verde | Interrumpir o separar la horda |
| El Sepulturero | Levanta hasta 2 caídos recientes a 10 m, con media vida | 3 s, círculo violeta | Interrumpir y alejarse de la zona de caídos |
| El Heraldo | Durante 8 s, velocidad ×1,35 y daño ×1,3 a infectados a 10 m | 2,5 s, círculo ámbar | Interrumpir o resistir hasta que caduque |
| El Portador | Descarga de 35 de daño a agentes dentro de 6 m | 2 s, círculo rojo | Salir del círculo o interrumpir |

**80 de daño durante la preparación cancelan la habilidad.** Lo indican el rótulo y la cuenta atrás. Una escopeta puede interrumpir con un impacto a corta distancia; también cuentan disparos, torretas, pinchos e infectados controlados. El Paciente 0 mantiene sus reglas propias y no se interrumpe de esta manera.

El frenesí tiene un marcador naranja en los infectados afectados. Las variantes de jefe alternan entre oleadas y comunidades. El límite de 96 infectados se mantiene, incluso al resucitar. Un cadáver se puede levantar una sola vez, caduca a los 60 segundos y no puede aparecer dentro de obstáculos o sobre agentes. Su segunda muerte no vuelve a dejar botín.

El ruido ahora selecciona objetivos detectables: un agente silencioso más cercano, pero fuera del alcance de percepción, no impide que el infectado oiga a otro más lejano que dispara o corre.

## Pantalla de comunidad

Pulsa **O** o el botón **Comunidad**. Muestra:

- Rescatados, plazas disponibles y trabajadores activos.
- Reservas donadas y segundos de alimentación restantes.
- Cada aserradero y cantera, su ubicación, existencias y estado.
- **Priorizar** para darle el primer trabajador disponible.
- **Pausar** para liberar a ese trabajador.

Puedes ordenar desde el entorno de tu base, hasta radio de construcción + 6 m. Se validan comunidad, distancia y vida en el servidor. Estas opciones también aparecen al inspeccionar el edificio con clic derecho. Un puesto lleno libera al trabajador para otra tarea; uno agotado explica que necesita un recurso vivo cercano.

La pantalla impide enviar movimiento o disparar mientras está abierta. Al cerrar un menú se aplica una breve demora para evitar que el clic de cierre dispare accidentalmente.

### Alimentación

La primera población rescatada dispone de 3 minutos de alimentación inicial. Después, cada minuto se consume **1 comida y 1 agua por cada 2 residentes**, redondeando hacia arriba. Se usan primero las reservas donadas y después existencias de huertos, pozos y recolectores de agua.

Si falta uno de los dos suministros, no se consume el otro: se detiene la producción y se muestra el motivo. No mueren automáticamente los rescatados. Tampoco se consumen raciones si no hay miembros vivos conectados.

Para donar, acércate a un refugio, selecciónalo con clic derecho y pulsa **Donar comida + agua**. Transfiere una unidad de cada suministro desde la mochila; la reserva donada admite 30 de cada uno.

Los rescatados siguen siendo población gestionada, sin personajes que recorran físicamente el mapa. La pantalla y las órdenes son funcionales; la IA de peatones y sus modelos siguen pendientes.

## Correcciones de economía

Dos puestos pueden trabajar cerca del mismo recurso, pero solo uno puede consumir su último golpe. Se revalida el recurso antes de producir, evitando materiales extra o golpes negativos. Las prioridades, pausas de puestos, raciones, efectos y cadáveres conservan estado en el guardado.

## Compatibilidad

Build **0.13.0**, protocolo 1, guardado v6. Los campos nuevos son opcionales: `workforce`, prioridades de puestos, tipos de jefe y cadáveres recientes. Se inicializan con valores definidos; no cambian el inventario ni las cuentas de v6. Las partidas v5 siguen pasando por la migración y el respaldo de 0.12.

Nuevos módulos: `src/enemies.mjs`, `src/population.mjs`, `godot/ui/population.gd` y `test/horde-population.test.mjs`. Integrados en `src/world.mjs`, `src/structures.mjs`, `src/loot.mjs`, `src/adventure.mjs`, `server.mjs`, `godot/world/main.gd`, `godot/player/actor.gd`, `godot/ui/hud.gd`, `godot/network/client.gd` y `godot/tests/native_smoke.gd`. Actualizados paquete, contrato de protocolo, lanzador, benchmark y documentación. Los scripts de la segunda carpeta Godot están sincronizados; respaldo anterior en `.tools/backups/horde-013`.

## Verificado

- **83 pruebas Node aprobadas.** Combate real para interrumpir, curación con límite, resurrección y botín único, caducidad del frenesí, prioridades, raciones atómicas, agotamiento compartido, percepción por ruido y regresiones de supervivencia, cuentas y guardado.
- Godot 4.5.1: integración nativa aprobada, incluyendo pantalla de comunidad, bloqueo de controles, limpieza de filas, rótulos de jefe y marcador de frenesí. Ambas carpetas cargan y conservan identidad, construcción y guardado.
- Captura de juego revisada: `godot-preview.png`. Escena pequeña: ~144 FPS, p95 7,04 ms en RX 580 2048SP a 1280×720, Compatibility; reporte `performance-013.json`.
- Prueba de carga ampliada a ~16 s por tamaño: 2, 10, 20 y 40 clientes HTTP/SSE. Con 40 clientes y 96 infectados iniciales: ~30 ticks/s, p95 muestreado de tick 17,9 ms, entrada p95 41,83 ms y cero errores de red. Detalles en `CARGA_013.md`. No incluye una población construida grande ni 40 clientes gráficos; las correcciones finales de selección por ruido se validaron en pruebas funcionales.

## Inicio y siguiente aceptación

Cierra el servidor anterior con Ctrl+C, ejecuta `node tools/start-godot.mjs` desde CityZ y reinicia Godot. Usa **O** para la comunidad, **J** para expediciones y armas, **B** para construcción y **P** para pausa individual.

Siguiente aceptación: partida humana completa que enlace rescate, alimentación, producción, defensa frente a los cuatro jefes y desenlace. Después, trabajadores físicos, regiones con interiores/túneles, más eventos y tienda cosmética. El arte final y las pruebas prolongadas de red siguen pendientes; esta entrega no se declara juego terminado al 100 %.
