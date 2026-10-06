# Carga local 0.17 — 5 de octubre de 2026

## Resultado final

| Medida | 0.16 | 0.17 |
| --- | ---: | ---: |
| Clientes | 40 | 40 |
| Infectados iniciales | 96 | 96 |
| Residentes / edificios | 32 / 36 | 32 / 36 |
| Duración real (s) | 158,27 | 140,49 |
| Simulación (ticks/s) | 30 | 30 |
| Entrada HTTP p95 (ms) | 81,39 | 55,42 |
| Tick p95 muestreado (ms) | 26,62 | 21,00 |
| Tráfico total recibido (KiB/s) | 2638,1 | 2585,8 |
| Errores HTTP/red | 0 | 0 |

El p95 de entrada baja aproximadamente un 31,9 % respecto de 0.16 en estas mediciones. El tráfico sigue aproximadamente un 83,7 % por debajo de los 15818,5 KiB/s de 0.15, que enviaba estados completos. No se cambia la frecuencia de simulación para obtener la reducción.

## Método y límites

`node tools/benchmark-mixed.mjs` ejecuta 1200 lotes de movimiento, disparos y recarga, con intervalo objetivo de 100 ms. Usa HTTP/SSE real, directorio temporal, puerto local automático, salud aumentada para sostener la carga y guardado periódico. Windows, Node v24.19.0, sin renderizado. El p95 HTTP mide respuesta a la petición, no el tiempo hasta que el jugador ve el movimiento. `tickMs` es una muestra del coste amortizado de ciclos con pasos de física; no es un perfil completo del procesador ni de todos los ciclos que solo envían estados.

La comparación usa el mismo tipo de escenario, con semillas y evolución diferentes. No demuestra rendimiento idéntico en internet, una mejora garantizada en cada equipo ni estabilidad durante horas. La medición final se ejecutó sin las pruebas de regresión en paralelo.

La primera iteración, `CARGA_MIXTA_017_FIRST.json`, mantuvo tres fases de envío y obtuvo 88,07 ms de entrada p95. Coincidió parcialmente con pruebas de regresión, por lo que no se usa como comparación aislada. La versión final distribuye los clientes entre diez posiciones temporales, evitando agrupar tantos envíos en un paso de física. Los resultados finales están en `CARGA_MIXTA_017.json`.
