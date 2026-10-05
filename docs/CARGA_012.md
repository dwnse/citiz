# Prueba local de carga 0.12

Ejecutada 2026-10-04T19:30:35.590Z con v24.19.0 en win32. Reproducir: `node tools/benchmark.mjs`.

| Clientes | Zombis iniciales | Duración s | Ticks/s | Tick p95 muestreado ms | Entrada p95 ms | KiB/s recibidos total | Errores HTTP/red |
|---|---|---|---|---|---|---|---|
| 2 | 19 | 5.41 | 29.9 | 5.05 | 19.71 | 385.5 | 0 |
| 10 | 25 | 5.4 | 30 | 7.35 | 26.23 | 2491.6 | 0 |
| 20 | 49 | 5.39 | 30 | 7.12 | 28.49 | 4978.2 | 0 |
| 40 | 96 | 5.65 | 30.1 | 15.04 | 40.42 | 9755.3 | 0 |

Cada cliente usa HTTP/SSE real, manda movimiento a aproximadamente 10 Hz y dispara cada tercer envío. Se leen los streams continuamente; hay una oleada de nivel 3 en las comunidades ocupadas. Cincuenta muestras del último tick, no una traza de todos los ticks. Latencia medida de extremo a extremo de la petición de entrada en loopback. El tráfico es la suma de bytes de cuerpos SSE recibidos, sin cabeceras TCP/HTTP. El servidor guarda cada 5 segundos. Las pruebas usan carpetas temporales independientes.

No incluye renderizado de 40 navegadores, red externa, pérdida de paquetes, builds máximas ni una sesión prolongada. No demuestra capacidad de producción; permite detectar regresiones y estimar límites locales.
