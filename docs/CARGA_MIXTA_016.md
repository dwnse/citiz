# Carga combinada 0.16 — 5 de octubre de 2026

## Resultado

La transmisión incremental reduce un 83,3 % el tráfico recibido en esta prueba local de 40 clientes. La simulación mantiene 30 ticks/s y no registra errores. La latencia de entrada aumenta; queda pendiente reducir el coste de preparar los parches.

| Medida | 0.15 | 0.16 |
| --- | ---: | ---: |
| Clientes HTTP/SSE | 40 | 40 |
| Infectados iniciales | 96 | 96 |
| Residentes / construcciones | 32 / 36 | 32 / 36 |
| Duración real (s) | 137,09 | 158,27 |
| Ticks/s | 30 | 30 |
| Tick p95 muestreado (ms) | 23,57 | 26,62 |
| Entrada HTTP p95 (ms) | 56,10 | 81,39 |
| Tráfico recibido total (KiB/s) | 15818,5 | 2638,1 |
| Errores | 0 | 0 |

## Método y límites

`tools/benchmark-mixed.mjs` conecta 40 clientes reales al servidor temporal por HTTP/SSE, envía movimiento, disparos y recargas, y ejercita IA, residentes y guardado. Aumenta la salud de jugadores y construcciones para sostener la carga. Ejecuta 1200 lotes con un intervalo objetivo de 100 ms; las esperas de respuesta prolongan la duración efectiva. El tiempo HTTP incluye procesamiento y transporte local, no mide la latencia visual del jugador.

Ambas mediciones usan el mismo tipo de escenario inicial, pero no reproducen exactamente la misma semilla ni evolución del mundo. Windows, Node v24.19.0, conexiones locales, sin renderizado. Los resultados no certifican 60 FPS, estabilidad durante horas ni capacidad en una red externa.

Datos: `CARGA_MIXTA_015.json` y `CARGA_MIXTA_016.json`. Las iteraciones preliminares se conservan en `CARGA_MIXTA_016_FIRST.json` y `CARGA_MIXTA_016_SECOND.json`: sirvieron para detectar y reducir el coste de serialización redundante. La medición final incorpora comparaciones numéricas, reutilización del catálogo, caché limitada al lote de envío y distribución de clientes en tres fases.

## Reproducir

Desde la raíz del proyecto: `node tools/benchmark-mixed.mjs`. Usa datos temporales y un puerto local asignado automáticamente. Sobrescribe el informe JSON de esta versión; no utiliza los guardados del usuario.
