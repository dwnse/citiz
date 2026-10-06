# Fase 3 — Mundo y campaña — 0.19

## Contenido y controles

Los mundos nuevos incorporan ocho recintos: hospital y laboratorio en cada región, con dos salas, paso central y dos accesos. Se presentan sin techo sobre el mismo plano del mapa. Los muros tienen colisión autoritativa; mobiliario, camillas y terminales son representación provisional sin colisión propia. Las estaciones de bombeo conservan su funcionamiento.

1. Entra y pulsa **E** cerca de la señal amarilla: radio del hospital o energía del laboratorio.
2. Elimina los infectados del encuentro y alcanza la señal turquesa interior.
3. Permanece a menos de 2 m y con visión directa del objetivo, sin infectados a menos de 6 m: 12 segundos junto al paciente o 20 junto al archivo. Apartarte conserva el progreso.
4. Pulsa **E** junto al objetivo preparado para recoger suministros e informe. Regresa a tu bóveda para entregarlo; el rescate requiere una plaza libre en un refugio. Usa el sistema de informes, sin escolta física.

El HUD indica amenaza, progreso y siguiente paso. J muestra encuentros activos y los últimos ocho completados. Hay 180 segundos de tiempo jugado desde la activación, incluida la recogida. Al vencer se cancela el encuentro y se retiran sus infectados restantes; puede iniciarse de nuevo. Tras cobrar, el lugar conserva su espera compartida de 180 segundos.

## Campaña y reglas

| Días reales del mundo | Fase | Infectados |
| --- | --- | ---: |
| 1–3 | Llegada | 2 |
| 4–10 | Exploración | 3 |
| 11–20 | Guerra | 4 |
| 21–27 | Asedio final | 5 |
| 28–30 | El sello cede | 6 |

Los títulos y resistencia de enemigos cambian por fase. Hospital: desde «Una voz entre camillas» hasta «Nadie queda atrás». Laboratorio: desde «Archivo dormido» hasta «Antes del silencio», con infectados corredores. Ambos comparten la estructura de despejar y mantener presencia, con objetivo, duración y presentación distintos. No hay decisiones narrativas ramificadas en esta entrega.

La primera comunidad que activa el encuentro puede reclamar su informe. Se validan vida, secuencia, proximidad y visión. El límite global continúa en 96 infectados; si no hay cupo o puntos libres para todos los enemigos, se rechaza el inicio sin generar un encuentro parcial. Las señales de radio siguen siendo oportunidades separadas con recompensa única; no sustituyen el informe del encuentro.

## Guardados y migración

Se omite el interior si el área ya contiene recursos, construcciones, personajes, obstáculos ajenos o un punto de historia incompatible. La decisión se guarda una vez y el lugar conserva la expedición anterior; no se retiran elementos existentes. Los mapas de legado no reciben interiores. Una partida antigua puede tener menos recintos que una nueva.

El generador evita colocar recursos y ruinas en los interiores incorporados y sus accesos. Encuentro, comunidad, progreso y enemigos se guardan en v6. Su reloj se congela con pausa individual o sin conectados; con otros jugadores conectados el mundo continúa. El plazo de treinta días sigue siendo real.

## Validación

114 pruebas Node: seis nuevas cubren acceso, recursos, migración sin borrados, combate/presencia, recompensa única, propiedad/visión, fases, expiración, persistencia, desconexión, cupo y pausa. Las anteriores conservan expediciones sin interior y señales de radio.

Godot 4.5.1: integración aprobada en ambas carpetas, interior y pistas recibidos, señal inicial y objetivo activo, además de combate, construcción, residentes, reconexión y guardado. Captura preparada y revisada: `interior-019.png`. No equivale a una expedición humana completa: las reglas del encuentro se verifican con pruebas del servidor.

Quedan pendientes arte definitivo, relieve, mayor variedad de salas, narrativa ramificada, escoltas físicas, equilibrio del mes y sesiones humanas prolongadas. No se garantiza la calidad gráfica de la referencia ni 60 FPS constantes.

## Archivos y arranque

Nuevos: `src/expeditions.mjs`, `test/expeditions.test.mjs`, este documento y captura. Modificados: `src/adventure.mjs`, `src/world.mjs`, `src/harvesting.mjs`; scripts Godot `world/expedition.gd`, `world/main.gd`, `ui/hud.gd`, `network/client.gd`, `tests/native_smoke.gd` y copias en `el-cerco-3d-(4.5)/`; versión y contrato en `package.json`, `server.mjs`, `tools/start-godot.mjs`, `test/protocol.test.mjs`; adaptación de la prueba antigua en `test/adventure.test.mjs`.

Build 0.19.0, protocolo 1 con capacidad `expedition-interiors`, guardado v6. Ambos `project.godot` se conservan. Reinicia con Ctrl+C y `node tools/start-godot.mjs`, y vuelve a abrir Godot.

Fase 4 propuesta: equilibrio de supervivencia, combate, producción y progresión. Esperar confirmación del usuario antes de comenzar.
