# El Cerco 0.16 — Estados incrementales

## Problema y cambio

La prueba combinada de 0.15 enviaba aproximadamente 15,45 MiB/s entre 40 clientes locales. El servidor repetía el catálogo, obstáculos y entidades completas diez veces por segundo, aunque la mayoría de sus campos no había cambiado.

Godot solicita ahora `/api/events?delta=1&worldId=...`. La primera respuesta contiene el estado completo. Las siguientes incluyen solo campos modificados, entidades nuevas y eliminaciones. Recursos y construcciones que no cambian no se vuelven a enviar.

La simulación sigue a 30 ticks/s y los envíos a 10 Hz por jugador. Los clientes se distribuyen entre tres fases de envío para evitar preparar todos los mensajes en el mismo tick. Las comparaciones reutilizan los campos sin cambios y comparan números directamente, sin convertirlos repetidamente a texto. Los cálculos de objetos comunes se comparten únicamente durante el lote síncrono de envío; se descartan antes de procesar nuevas acciones. El catálogo se construye una vez. No se redondean posiciones ni se altera el combate. Los clientes que no solicitan `delta=1`, incluido el navegador anterior, siguen recibiendo estados completos.

## Integridad y reconexión

- Cada conexión tiene su propia base de comparación, después de aplicar las reglas de visibilidad del jugador. No se comparte la información privada de otro observador.
- `wire:1` distingue el envoltorio de red del guardado v6. `seq` identifica el estado; un parche indica `base`, la secuencia que necesita.
- `set` y `remove` actualizan campos superiores. `objects` modifica campos de objetos como aventura y población.
- `entities` transmite cambios por identificador, elimina objetos que desaparecen y comunica el orden cuando cambia. Se conservan los valores `null` y los borrados de propiedades.
- Cada 100 mensajes se envía otra base completa, aproximadamente cada diez segundos. Reconectar crea un nuevo codificador y comienza con una base completa.
- Si Godot detecta una secuencia faltante, corta el canal y explica que debe reconectarse. No aplica un parche sobre una base incorrecta. La reconexión se hace con el botón existente y conserva la identidad.
- Las bases del servidor contienen datos serializados, no referencias mutables al mundo. Los estados anteriores del cliente no se modifican al reconstruir el siguiente.

## Validación

102 pruebas Node aprobadas, incluyendo pruebas de equivalencia entre estado original y reconstruido durante 150 actualizaciones reales; creación/eliminación de construcciones; valores nulos; borrado de propiedades; cambios de orden; secuencias perdidas; recuperación con base completa; visibilidad de rivales; conexión HTTP/SSE antigua y nueva.

La integración Godot pasó en ambos proyectos con Godot 4.5.1 sin interfaz gráfica. Comprueba el uso efectivo de parches, rechaza secuencias incorrectas y verifica que el estado previo no se modifique. Mantiene las pruebas de personajes, disparos, recarga, construcción, galerías, cosméticos, desconexión, reconexión y lectura del guardado.

La carga final de 40 clientes recibió 2638,1 KiB/s frente a 15818,5 en 0.15: una reducción del 83,3 %. Mantuvo 30 ticks/s y cero errores. El coste de codificación sigue siendo un pendiente: el p95 de entrada HTTP subió de 56,10 a 81,39 ms y el p95 de tick muestreado de 23,57 a 26,62 ms. El informe `CARGA_MIXTA_016.md` detalla la comparación y sus límites.

La comparación de carga está en `CARGA_MIXTA_016.json` y `CARGA_MIXTA_015.json`. Son pruebas locales con salud aumentada para mantener la carga, sin renderizado ni red externa. No demuestran estabilidad de varias horas ni capacidad para producción pública.

## Archivos y compatibilidad

Nuevos: `src/replication.mjs`, `godot/network/replication.gd`, `test/replication.test.mjs` y este documento.

Modificados: `src/structures.mjs`, `server.mjs`, `package.json`, `tools/start-godot.mjs`, `tools/benchmark-mixed.mjs`, `test/protocol.test.mjs`, `godot/network/client.gd`, `godot/tests/native_smoke.gd`, documentación y copias de los scripts en `el-cerco-3d-(4.5)/`.

Build 0.16.0, protocolo 1 con capacidad adicional `delta-snapshots`; guardados v6 conservados. Respaldo anterior de los scripts del segundo proyecto en `.tools/backups/replication-016/`. Ambos `project.godot` permanecen sin cambios.

Reinicia el servidor anterior con Ctrl+C, ejecuta `node tools/start-godot.mjs` y vuelve a abrir Godot. El arranque comprueba la versión antes de abrir los guardados.

## Pendientes

Pruebas en red externa y durante horas, recuperación automática de conexiones, arte definitivo, interiores de hospitales y laboratorios, eventos de campaña, órdenes individuales de residentes y equilibrio del ciclo completo. Esta etapa optimiza la transmisión; no declara terminado el juego al 100 %.
