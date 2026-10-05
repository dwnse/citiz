# Entrega del corte vertical

## Continuación 0.12 — entrega actual

Supervivencia con materiales diferenciados, sprint y esquiva, tres armas, 18 construcciones, expediciones, población y producción, investigación y ciclo ambiental. El recorrido del Sello incluye Paciente 0, muestra, cura y recompensas únicas por cuenta. Guardados v6 con respaldo de versiones anteriores.

Verificación al retomar la entrega el 4 de octubre de 2026: 74/74 pruebas Node aprobadas. El comando de sintaxis incluye ahora también adventure, inventory, rewards, harvesting y loot. Instrucciones, verificación nativa y límites en [SUPERVIVENCIA_012.md](SUPERVIVENCIA_012.md) y [PRUEBAS.md](PRUEBAS.md).

Para jugar, inicia `node tools/start-godot.mjs` y abre uno de los proyectos Godot. Si el lanzador detecta un servidor anterior, cierra su consola con Ctrl+C y repite el arranque. Las pruebas utilizan guardados temporales.

Pendientes: campaña humana completa con asedio y cura, balance prolongado, arte final, trabajadores visibles, túneles, tienda y red externa con 40 clientes gráficos.

## Continuación 0.6 — registro histórico

Prólogo breve de radio y bóveda, seis magos con pistas y recorridos cortos, diario J, seis poderes (2–7), maná, recargas y claves comunitarias para abrir el sello. Guardado v4 con copia exacta del formato anterior. Demostración reiniciada en http://127.0.0.1:3001.

Sintaxis y 30/30 pruebas aprobadas. Revisión visual de radio/diario. Pendientes: Paciente 0, cura, premios, desarrollo audiovisual y recorrido manual completo. La carga de 40 clientes anterior corresponde a 0.5.

Archivos nuevos: src/story.mjs y test/story.test.mjs.

Archivos modificados: package.json, src/world.mjs, src/storage.mjs, public/index.html, public/style.css, public/game.js, test/expansion.test.mjs, README.md, docs/PLAN.md, docs/DECISIONES.md, docs/RED.md, docs/PRUEBAS.md, docs/ENTREGA.md y docs/el-cerco-preview.png.

Siguiente etapa: Paciente 0 con fases persistentes, muestra/cura, condiciones de victoria y recompensas idempotentes. Geografía elaborada, balance humano y almacenamiento transaccional siguen pendientes.


## Continuación 0.5 — registro histórico

Se añadieron cuatro comunidades, cuatro territorios provisionales, cupos permanentes 4 × 10, selección de facción, bóvedas propias, propiedad de muros, minimapa, disparos entre rivales bajo asedio, robo y depósito, reloj visible, eliminación por comunidad y migración v3 de partidas antiguas a legado. El radio mejorable sigue llegando a ×2. Se corrigió la temporización para mantener el ritmo de simulación con la granularidad del temporizador de Windows.

Verificación: 21 pruebas automatizadas y comprobación visual de selección/aparición/construcción en Ciudad. Prueba gradual de 2/10/20/40 clientes reales HTTP/SSE documentada en CARGA.md. Con 40: ~30 ticks/s, 29,7 ms p95 de entrada y cero errores en prueba breve. El tráfico sigue alto; no se garantiza producción. Las partidas anteriores conservan backup v2 y su estado, sin forzarlas al mapa nuevo.

Archivos creados en esta continuación:

- `src/communities.mjs`
- `test/communities.test.mjs`
- `tools/benchmark.mjs`
- `docs/CARGA.md`
- `docs/CARGA.json`

Archivos modificados:

- `package.json`
- `server.mjs`
- `src/world.mjs`
- `src/navigation.mjs`
- `src/storage.mjs`
- `public/index.html`
- `public/style.css`
- `public/game.js`
- `test/expansion.test.mjs`
- `README.md`
- `docs/DECISIONES.md`
- `docs/PLAN.md`
- `docs/RED.md`
- `docs/PRUEBAS.md`
- `docs/ENTREGA.md`
- `docs/el-cerco-preview.png`

Arranque: `npm start` (puerto 3000 por defecto). Demostración mantenida en `http://127.0.0.1:3001`. Para aprovechar las cuatro comunidades, crear/elegir un mundo nuevo de cupo 40; los mundos de cupo 10 son legado.

Límites: territorios esquemáticos, sin túneles reales ni POI finales; asedio humano completo sin certificar; balance de PvP/defensa offline pendiente; la horda no recibe la protección offline de rivales. No hay magia, seis magos, Paciente 0, cura, economía cosmética ni premios. **Siguiente paso:** recorrido humano de guerra y comenzar la etapa 5 con pistas, magos y poderes validados por servidor; ampliar la geografía y optimizar tráfico como trabajo paralelo lógico, sin afirmar terminada la etapa 4 de producción.

## Continuación 0.4

Implementado: sala con creación y selección de mundos, identidades por mundo, migración v1 → v2 con backup, rocas con colisión, rutas de zombis con presupuesto y turnos de búsqueda, aparición libre y mejoras del radio hasta ×2. Reparar ya no revive una bóveda destruida. Sintaxis y 14 pruebas aprobadas. Recorrido visual de sala, fabricación, muro, disparo y recarga ejecutado; además, dos clientes gráficos verificaron construcción compartida y reconexión con plaza conservada. Detalles en PRUEBAS.md.

Archivos cambiados en esta continuación:

- `package.json`
- `server.mjs`
- `src/world.mjs`
- `src/navigation.mjs` (nuevo)
- `src/storage.mjs` (nuevo)
- `public/index.html`
- `public/style.css`
- `public/game.js`
- `test/expansion.test.mjs` (nuevo)
- `README.md`
- `docs/DECISIONES.md`
- `docs/PLAN.md`
- `docs/RED.md`
- `docs/PRUEBAS.md`
- `docs/ENTREGA.md`
- `docs/el-cerco-preview.png`

La demostración sigue en `http://127.0.0.1:3001`; `npm start` usa 3000 por defecto. No se borraron las partidas anteriores. Se conserva la limitación de una comunidad de diez por mundo. **Siguiente paso:** segundo territorio/comunidad con propiedad de construcciones, combate y reglas de asedio; después cuatro regiones y cupo 40. La etapa 4 está parcialmente implementada, las etapas 5–6 no.

## Registro histórico de la entrega 0.3

## Cambios

Etapa 1: proyecto ejecutable, bosque pequeño, cámara elevada, personaje, pistola, zombis, bóveda, muro con plano y controles. Etapa 2: servidor autoritativo, conexiones simultáneas, validación y reconexión. Etapa 3: botín, inventario, fabricación, reparación, oleadas y jefe, guardado y carga. Las mecánicas están implementadas, pero la aceptación manual completa de etapas 1–3 sigue abierta según PRUEBAS.md; no se declara finalizado el juego completo.

## Arranque y estado

`npm start` y navegador en `http://127.0.0.1:3000`. Una instancia separada de demostración puede arrancarse con `PORT=3001` y `DATA_DIR=data-demostracion`; se dejó iniciada durante esta entrega. Sin dependencias npm. Código de sintaxis comprobada y siete pruebas aprobadas.

## Lista exacta de archivos creados

- `.gitignore`
- `package.json`
- `README.md`
- `server.mjs`
- `src/world.mjs`
- `public/index.html`
- `public/style.css`
- `public/game.js`
- `test/world.test.mjs`
- `docs/DECISIONES.md`
- `docs/PLAN.md`
- `docs/RED.md`
- `docs/PRUEBAS.md`
- `docs/ENTREGA.md`
- `docs/el-cerco-preview.png`

Datos de ejecución excluidos de Git: `data/world.json`, `data-demostracion/world.json` y archivos temporales de guardado si una escritura está en curso. La prueba automática crea y limpia un directorio temporal aislado.

## Pendiente y siguiente paso

Terminar el recorrido manual documentado, ajustar control/balance y luego implementar navegación por cuadrícula y el directorio local de mundos de etapa 4. Antes de cuatro regiones y guerra, verificar dos comunidades, inscripción, eliminación y ventanas de asedio. Etapas 4–6 no implementadas; no hay magos, poderes, Paciente 0, cura ni premios. Los supuestos de motor, economía, muerte y reloj están en DECISIONES.md.
