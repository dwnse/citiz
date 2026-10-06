# Fase 1 — Estabilidad y controles — 0.17

## Alcance

Esta entrega aborda cortes de conexión, órdenes de movimiento descartadas y controles activos al cambiar de ventana o abrir menús. La fase siguiente, gestión RTS, requiere confirmación del usuario antes de empezar.

## Cambios al jugar

- Si se pierde el canal de estados, el cliente intenta recuperar la misma identidad y mundo hasta cinco veces, con esperas de 1, 2, 4, 8 y 8 segundos entre intentos. Los tiempos de las peticiones HTTP se añaden a esas esperas. Cada conexión nueva recibe una base completa.
- El mensaje indica el intento y qué ocurrió. Al agotar los intentos quedan disponibles Reconectar y Partidas. Salir o entrar manualmente cancela la recuperación pendiente. Los errores definitivos al recuperar la cuenta detienen los reintentos.
- Abrir el mismo perfil en otra conexión cierra la anterior con una explicación, sin que ambas ventanas intenten expulsarse continuamente.
- No se repiten disparos, compras o construcciones pendientes al reconectar. Las acciones que el servidor ya aceptó conservan su resultado; las no enviadas se cancelan. El estado recuperado muestra el resultado autoritativo.
- Mientras una petición de movimiento está en curso, se conserva solamente la intención más reciente, incluida la de detenerse. Un rechazo temporal por frecuencia se reintenta sin recuperar una intención anterior.
- Perder el foco de la aplicación bloquea los controles, cancela arrastres y acciones en espera, y solicita detener movimiento y carrera. Los menús y campos de texto bloquean el movimiento; entrar en construcción detiene al personaje y permite mover la cámara.
- Las respuestas HTTP de una conexión anterior no desbloquean ni modifican la cola de la conexión nueva. Reconectar reinicia la carrera para no conservar una tecla Mayús que ya se soltó.

## Servidor

Los envíos de estados siguen a 10 Hz por cliente, distribuidos sobre el programador de 10 ms en lugar de agruparse en tres ticks de física. Tras un retraso se omiten envíos vencidos, sin emitir una ráfaga de estados antiguos. La simulación conserva su frecuencia de 30 Hz.

Las descripciones de edificios y la población de una comunidad se calculan una vez por lote síncrono. El lote se descarta antes de atender nuevas acciones; no reutiliza inventarios privados entre jugadores ni conserva información de un tick anterior.

## Verificación

103/103 pruebas Node aprobadas. Resultados de carga registrados en CARGA_MIXTA_017.md y JSON: 40 clientes, 30 ticks/s, cero errores y entrada HTTP p95 de 55,42 ms frente a 81,39 ms en 0.16. Las pruebas nativas ejercitan cortes reales del canal, recuperación de identidad, sustitución de sesión, cancelación de reintentos, límite de intentos, movimiento seguido de parada, bloqueo de controles y conservación de edificios. El límite de cinco intentos se prueba provocando fallos consecutivos, sin esperar todas las pausas.

## Archivos

La integración nativa final pasó en ambos proyectos con Godot 4.5.1 sin interfaz gráfica, sin errores de script. `npm run check` también pasó. Los scripts de ambas carpetas coinciden.

- `godot/network/client.gd`: recuperación, colas y aislamiento entre conexiones.
- `godot/world/main.gd`: foco y suspensión de controles.
- `godot/tests/native_smoke.gd`: regresiones nativas; scripts sincronizados en `el-cerco-3d-(4.5)/`.
- `server.mjs`: sustitución de sesión, carrera y distribución de envíos.
- `src/world.mjs`, `src/replication.mjs`, `test/replication.test.mjs`: cálculo compartido y prueba de aislamiento.
- `package.json`, `test/protocol.test.mjs`, `tools/start-godot.mjs`, `tools/benchmark-mixed.mjs`: versión y validación.

Protocolo 1 y guardados v6 conservados; ambos `project.godot` permanecen sin cambios. Reinicia el servidor con Ctrl+C y `node tools/start-godot.mjs`; vuelve a abrir Godot.

## Límites

La pérdida de foco detiene las intenciones del jugador; el mundo multijugador continúa y los enemigos pueden atacarlo. En un corte de red, el servidor ya caduca las intenciones de movimiento a los 350 ms. No se garantiza un frenado instantáneo sin conectividad.

Las pruebas locales no certifican 60 FPS constantes, sesiones de horas en internet ni la experiencia humana del ciclo completo. Esas validaciones siguen pendientes. Esta fase no incorpora órdenes nuevas de residentes, contenido de campaña ni arte definitivo.
