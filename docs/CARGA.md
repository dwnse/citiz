# Prueba local de carga 0.5

Ejecutada 2026-10-03T18:00:20.910Z con v24.19.0 en win32. Reproducir: `node tools/benchmark.mjs`.

| Clientes | Zombis iniciales | Duración s | Ticks/s | Tick p95 muestreado ms | Entrada p95 ms | KiB/s recibidos total | Errores HTTP/red |
|---|---|---|---|---|---|---|---|
| 2 | 19 | 5.4 | 29.8 | 2.28 | 17.3 | 120.8 | 0 |
| 10 | 25 | 5.38 | 29.9 | 1.88 | 21.77 | 932.3 | 0 |
| 20 | 49 | 5.39 | 30.1 | 3.53 | 22.6 | 1912.7 | 0 |
| 40 | 96 | 5.38 | 29.9 | 6.99 | 29.7 | 3718.4 | 0 |

Cada cliente usa HTTP/SSE real, manda movimiento a aproximadamente 10 Hz y dispara cada tercer envío. Se leen los streams continuamente; hay una oleada de nivel 3 en las comunidades ocupadas. Cincuenta muestras del último tick, no una traza de todos los ticks. Latencia medida de extremo a extremo de la petición de entrada en loopback. El tráfico es la suma de bytes de cuerpos SSE recibidos, sin cabeceras TCP/HTTP. El servidor guarda cada 5 segundos. Las pruebas usan carpetas temporales independientes.

No incluye renderizado de 40 navegadores, red externa, pérdida de paquetes, builds máximas ni una sesión prolongada. No demuestra capacidad de producción; permite detectar regresiones y estimar límites locales.

