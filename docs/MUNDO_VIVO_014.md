# El Cerco 0.14 — Población, radio y colectores

Entrega funcional sobre 0.13. No equivale al juego terminado al 100 %.

## Qué cambia al jugar

### Trabajadores físicos

Los rescatados tienen nombre, modelo, herramienta, posición y carga persistentes. Desde un refugio caminan a árboles o rocas asignados por el aserradero o cantera. Extraen durante 20 segundos y llevan 6 de madera u 8 de piedra al puesto. Solo entonces aumenta su reserva. E recoge los materiales del edificio.

- O permite priorizar o pausar puestos. La ficha del edificio muestra desplazamiento, extracción, transporte, falta de raciones o paso bloqueado.
- Si hay infectados a menos de 7 m, buscan refugio e interrumpen su tarea. Conservan la carga. En esta entrega los rescatados no reciben daño directo: la amenaza detiene producción; destruir viviendas reduce las plazas disponibles.
- Portones cerrados y obstáculos bloquean las rutas. No extraen ni depositan a través de paredes. Abrir un paso permite retomar el recorrido.
- Los planos no pueden colocarse sobre trabajadores y los portones automáticos no se cierran sobre ellos.
- Al destruir un puesto, la carga que transportaba su trabajador cae como materiales recogibles, una sola vez.
- Sin miembros vivos conectados, los trabajadores y su producción se detienen. No se acumula producción por tiempo desconectado.
- Una búsqueda de ruta por tick como máximo, con turnos entre residentes; rutas transitorias, posición/carga guardadas. Máximo defensivo de 160 residentes por comunidad.

Los movimientos entre residentes pueden coincidir: no hay separación física entre peatones ni órdenes individuales de movimiento. Las órdenes de esta entrega se dan a los puestos.

### Lugares de expedición

Hospital, estación de bombeo y laboratorio tienen pavimento, marcas, señal propia y patios con entradas. Las paredes añadidas usan la misma geometría en cliente y servidor. El rótulo muestra cuánto falta para volver a registrar la zona.

Al incorporar los patios a una partida existente se omiten los segmentos que colisionarían con construcciones, recursos, personajes o zonas de historia. No se borran esos elementos. Por eso algunos patios tienen paredes incompletas. El mapa de legado conserva su geometría. Son recintos exteriores abiertos, no interiores completos.

### Señales de radio

Tras dos minutos de tiempo jugado aparece una oportunidad de 120 segundos. Las siguientes pueden aparecer cada cinco minutos, alternando destinos de comunidades con agentes vivos conectados:

| Señal | Destino | Recompensa |
|---|---|---|
| La radio de los vivos | Hospital | 3 botiquines + 2 comidas |
| Agua bajo el óxido | Estación | 6 aguas + 20 chatarra |
| El eco del Umbral | Laboratorio | 4 componentes + 24 balas |

Un aviso, un círculo dorado en el minimapa y el diario J indican el destino. E reclama la señal, validando distancia y línea de visión. El premio es único en el mundo y deja ruido durante 20 segundos. Puede recuperarse llevando otro informe o mientras el registro ordinario está en espera. No completa ni reemplaza ese informe. El tiempo de las señales se congela con la pausa individual y sin conectados.

### Colectores

Cuatro accesos violetas enlazan dos pares de puntos del cruce central: (50,96) ↔ (160,114) y (50,114) ↔ (160,96).

E a menos de 3 m cruza al otro acceso. Cuesta 25 de resistencia, tiene 15 segundos de espera y produce ruido durante 20 segundos. El servidor busca una salida libre a menos de 4 m; si no existe, rechaza el viaje sin cobrar resistencia. Son transiciones entre accesos; todavía no hay un túnel interior recorrible.

### Aspectos de cuenta

En J se puede comprar/equipar Guardia (gratis), Brasa (6 monedas), Niebla (6 monedas) y Custodio (12 monedas + 1 sello). Cambian la insignia del personaje, sin modificar combate ni inventario. Los aspectos adquiridos se equipan gratis. Se muestra el activo y se deshabilitan compras sin saldo, con explicación de cómo conseguir recompensas.

Las compras usan el perfil autenticado y se guardan inmediatamente. Repetir una secuencia no cobra otra vez. Las identidades vinculadas al mismo perfil comparten el aspecto, incluidos mundos futuros. Sigue siendo una cuenta local con clave de recuperación; no se ha añadido un proveedor externo de autenticación.

## Verificación y rendimiento

- **91 pruebas Node aprobadas**, incluyendo rutas cerradas, extracción sin atravesar muros, guardado de carga, destrucción de puesto, pausa/offline, recompensa única, caducidad de señales, costes de colectores y compras sin doble cobro.
- `npm run check` aprobado.
- Integración Godot 4.5.1: dos clientes HTTP/SSE, personaje y herramienta visibles, construcciones compartidas, recargas, compras cosméticas, trabajador con carga, marcador de expedición, reconexión y lectura del guardado. Ambos proyectos comprobados.
- Capturas: `world-014.png`, `journal-014.png`, `godot-preview.png`. La captura del patio usa un trabajador y una posición de cámara preparados para revisar el render; no representa una partida humana completa.
- RX 580 2048SP, Compatibility, 1280×720: escena pequeña alrededor de 144 FPS.
- Misma escena de estrés gráfico (96 infectados, 80 muros, 32 residentes): **50,14 → 119,20 FPS medios**, p95 de fotograma **22,59 → 10,39 ms**, llamadas de dibujo **3.600 → 2.163**. Se fusionan vértices de cada parte rígida del personaje en una malla; se conservan colores, silueta, animación de piernas y sombras. Datos: `performance-014-stress-before.json` y `performance-014-stress.json`.
- El estrés añade entidades para renderizar; no ejecuta su IA. No demuestra 60 FPS constantes en toda partida.
- Simulación aparte: 60 segundos simulados, 32 trabajadores, 48 edificios, cuatro agentes conectados, sin infectados ni red: tick medio **2,11 ms**, p95 **6,36 ms**, 288 materiales entregados. Reproducible con `node tools/benchmark-workers.mjs`; `performance-workers-014.json`.

## Compatibilidad e inicio

Build 0.14.0; protocolo 1 y guardado v6. Trabajadores, carga, señales, patios y propiedad de aspectos son campos adicionales. No se han abierto ni sustituido las partidas del usuario para hacer las pruebas: se usaron directorios temporales.

Los scripts de `godot/` y `el-cerco-3d-(4.5)/` están sincronizados. Sus archivos `project.godot` se conservan. Copias de los scripts anteriores de la segunda carpeta: `.tools/backups/living-world-014/`.

Para cargar los cambios: cerrar el servidor anterior con Ctrl+C, ejecutar `node tools/start-godot.mjs` desde CityZ y volver a abrir el juego. El lanzador detecta un servidor antiguo antes de abrir sus guardados.

## Archivos de implementación

Nuevos:

- `src/workers.mjs`, `src/incidents.mjs`, `src/landmarks.mjs`, `src/passages.mjs`.
- `godot/world/expedition.gd` y su copia en el segundo proyecto.
- `test/living-world.test.mjs`, `tools/benchmark-workers.mjs`.

Modificados:

- `server.mjs`, `package.json`, `src/world.mjs`, `src/adventure.mjs`, `src/structures.mjs`, `src/population.mjs`, `src/navigation.mjs`, `src/harvesting.mjs`, `src/rewards.mjs`.
- `world/main.gd`, `world/art.gd`, `player/actor.gd`, `ui/hud.gd`, `ui/population.gd`, `ui/minimap.gd`, `network/client.gd`, `tests/native_smoke.gd` en ambos proyectos Godot.
- `test/adventure.test.mjs`, `test/horde-population.test.mjs`, `test/protocol.test.mjs`, `tools/start-godot.mjs`.
- README, plan, pruebas y contrato de red; capturas y reportes indicados arriba.

## Próxima aceptación y pendientes reales

1. Partida humana completa: rescatar, alimentar, abrir rutas, transportar recursos, defender la base, usar colectores, asediar y sintetizar la cura. Las pruebas automáticas no sustituyen esa evaluación de controles y equilibrio.
2. Prueba prolongada combinando IA de hordas, población, muchas bases y clientes en red externa. La medición local de render y la simulación de trabajadores están separadas.
3. Interiores y túneles recorribles, relieve, encuentros y decisiones específicos de las fases del mes. Las tres señales de radio son un primer ciclo de eventos.
4. Arte definitivo próximo a la referencia: modelos, animaciones, materiales, regiones y audio propios. Los patios y personajes actuales conservan geometría provisional.
5. Órdenes individuales de residentes, separación entre peatones y equilibrio de peligro/protección offline; recuperación externa de cuentas y endurecimiento de almacenamiento para despliegue público.
