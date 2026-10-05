# Prueba local de carga 0.12

Ejecutada 2026-10-04T19:28:33.815Z con v24.19.0 en win32. Reproducir: `node tools/benchmark.mjs`.

| Clientes | Zombis iniciales | Duración s | Ticks/s | Tick p95 muestreado ms | Entrada p95 ms | KiB/s recibidos total | Errores HTTP/red |
|---|---|---|---|---|---|---|---|
| 2 | 19 | 5.43 | 30 | 20.34 | 29.79 | 605.5 | 0 |
| 10 | 25 | 5.42 | 29.9 | 15.14 | 38.23 | 3577.1 | 0 |
| 20 | 49 | 5.6 | 30 | 19.6 | 57.82 | 7235.8 | 0 |
| 40 | 96 | 6.23 | 30 | 27.58 | 89.09 | 14332.3 | 0 |

Cada cliente usa HTTP/SSE real, manda movimiento a aproximadamente 10 Hz y dispara cada tercer envío. Se leen los streams continuamente; hay una oleada de nivel 3 en las comunidades ocupadas. Cincuenta muestras del último tick, no una traza de todos los ticks. Latencia medida de extremo a extremo de la petición de entrada en loopback. El tráfico es la suma de bytes de cuerpos SSE recibidos, sin cabeceras TCP/HTTP. El servidor guarda cada 5 segundos. Las pruebas usan carpetas temporales independientes.

No incluye renderizado de 40 navegadores, red externa, pérdida de paquetes, builds máximas ni una sesión prolongada. No demuestra capacidad de producción; permite detectar regresiones y estimar límites locales.
