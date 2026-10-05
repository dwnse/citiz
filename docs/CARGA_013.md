# Prueba local de carga 0.13

Ejecutada 2026-10-04T22:44:35.702Z con v24.19.0 en win32. Reproducir: `node tools/benchmark.mjs`.

| Clientes | Zombis iniciales | Duración s | Ticks/s | Tick p95 muestreado ms | Entrada p95 ms | KiB/s recibidos total | Errores HTTP/red |
|---|---|---|---|---|---|---|---|
| 2 | 19 | 16.32 | 30 | 2.34 | 18.87 | 392.3 | 0 |
| 10 | 25 | 16.27 | 30 | 4.6 | 22.9 | 2513.8 | 0 |
| 20 | 49 | 16.1 | 29.9 | 9.14 | 29.41 | 5023.6 | 0 |
| 40 | 96 | 16.46 | 30 | 17.9 | 41.83 | 9919.8 | 0 |

Cada cliente usa HTTP/SSE real, manda movimiento a aproximadamente 10 Hz y dispara cada tercer envío. Se leen los streams continuamente; hay una oleada de nivel 3 en las comunidades ocupadas. Ciento cincuenta muestras del último tick, no una traza de todos los ticks. Latencia medida de extremo a extremo de la petición de entrada en loopback. El tráfico es la suma de bytes de cuerpos SSE recibidos, sin cabeceras TCP/HTTP. El servidor guarda cada 5 segundos. Las pruebas usan carpetas temporales independientes.

No incluye renderizado de 40 navegadores, red externa, pérdida de paquetes, builds máximas ni una sesión prolongada. No demuestra capacidad de producción; permite detectar regresiones y estimar límites locales.
