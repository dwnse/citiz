# Carga combinada local 0.15

Reproducir: `node tools/benchmark-mixed.mjs`. Node 24.19.0, Windows, HTTP/SSE en loopback, directorio temporal.

- 40 clientes, 96 infectados iniciales, 32 residentes y 36 edificios.
- Duración: 137.09 s; 30 ticks/s.
- Tick p95 muestreado: 23.57 ms. Entrada HTTP p95: 56.1 ms.
- Tráfico total recibido: 15818.5 KiB/s (aproximadamente 15.45 MiB/s). 0 errores HTTP/red.
- 54 materiales en puestos al terminar; trabajadores huyen de las amenazas durante la prueba.

Los agentes, bóvedas y edificios tienen salud aumentada en esta escena para mantener la carga. Se envía movimiento a unos 10 Hz y se dispara o recarga cada tercer envío. Se muestrea el último tick en cada lote, sin traza completa. No incluye renderizado ni red externa. El tráfico todavía es alto: no demuestra capacidad de despliegue público ni estabilidad durante horas. El código del benchmark y el reporte JSON conservan el escenario exacto.
