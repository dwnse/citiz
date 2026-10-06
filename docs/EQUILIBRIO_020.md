# Fase 4 — Equilibrio — 0.20

## Ajustes implementados

| Sistema | Antes | Ahora |
| --- | --- | --- |
| Primera oleada, mundo nuevo | 45 s | 90 s |
| Intervalo diurno / nocturno | 35 / 28 s | 60 / 45 s |
| Nivel general de oleadas | 1,1,2,2,3,3 y repetición | 1,1,1,2,2,2,3… |
| Munición por infectado común | 6 o 12 | 1 o 2 |
| Comida / agua / botiquines por 16 resultados de botín | 8 / 8 / 4 | 2 / 2 / 1 |
| Extracción por mejora de puesto | Siempre 20 s | 20 / 16 / 12 s |
| Investigación y carga de trabajador | 6 madera / 8 piedra | +1 por nivel de investigación, hasta 9 / 11 |

Ciudad y Subterráneo conservan amenaza mínima 2. El límite global de infectados y la condición que retrasa oleadas cuando ya hay demasiados siguen activos: el HUD muestra una previsión, no una aparición garantizada. El contador utiliza la hora del servidor.

Los jefes ordinarios entregan 12 balas, 2 comidas, 2 aguas y 2 botiquines. El Paciente 0 conserva la muestra y su recompensa específica. La protección contra botín duplicado se mantiene.

El botín se calcula a partir del identificador del infectado; los promedios indicados corresponden a recorrer los 16 resultados de la tabla, no a una garantía de recompensa cada 16 bajas.

## Decisiones de equilibrio

La pistola necesita dos impactos contra un infectado normal de nivel 1, pero antes recuperaba nueve balas de media. Ahora recupera 1,5: fabricar, buscar suministros y mantener un taller vuelve a importar. La escopeta sigue pudiendo obtener un saldo positivo contra enemigos débiles con buena precisión y a su alcance corto; el análisis no oculta esa ventaja. Los niveles superiores, errores al disparar y enemigos reforzados aumentan el gasto.

Se amplía el tiempo entre oleadas para acompañar la reducción del botín y permitir construcción y expediciones. La amenaza deja de reiniciarse al nivel uno. Esto es un primer ajuste verificable, no una certificación de dificultad final para todo grupo o estilo de juego.

Las tasas de hambre y sed se conservaron tras revisarlas: desde 100, sin suministros, tardan aproximadamente 41,7 y 23,8 minutos activos en agotarse. No se aceleró ese desgaste mientras se reduce el botín. Enfermería, cocina, consumo y fabricación mantienen sus costes.

## Producción e información al jugador

**O / Comunidad** muestra producción máxima por minuto menos raciones de residentes, y avisa si falta comida o agua. Considera mejoras, riego de un pozo próximo y lluvia. Es una estimación de capacidad: no incluye consumo del jugador, reservas llenas ni tiempo desconectado. No inventa recursos ni modifica existencias.

Ejemplo: dos residentes requieren 1 comida y 1 agua/min. Un huerto regado por un pozo produce 1,25 comidas/min y el pozo 2 aguas/min: saldo teórico +0,25 y +1. Con seis residentes esa instalación es insuficiente.

La ficha de aserradero/cantera explica la carga y tiempo actuales. Mejorar reduce la extracción; investigar aumenta materiales por golpe. El transporte, los bloqueos, las raciones y el agotamiento/regeneración de recursos siguen limitando el rendimiento real. No se promete multiplicar la producción sostenida en proporción al tiempo de extracción.

El HUD añade tiempo previsto y nivel de la próxima oleada. El diario explica el nuevo ritmo, botín y mejoras.

## Evidencia

- 118 pruebas Node aprobadas; cuatro nuevas verifican botín y recompensa única, progresión/intervalos, balance de raciones y producción mejorada real con un recurso consumido una sola vez.
- `npm run check` aprobado.
- Integración Godot 4.5.1 en ambas carpetas: previsión de oleada y balance alimentario visibles, además de combate, construcción, trabajadores, interiores, reconexión y guardado.
- Captura revisada: `population-020.png`, escenario preparado de pruebas a 1280×720.
- Auditoría reproducible: `node tools/audit-balance.mjs`, salida `BALANCE_020.json`. Compara armas contra enemigos normales a 100 % y 70 % de precisión, suministros, oleadas y mejoras. Es aritmética determinista; no simula desplazamiento, puntería humana, combate de jefes, latencia ni una campaña completa.

Pendiente: partidas humanas hasta la cura, contraste entre comunidades, guerra PvP, defensa offline y sesiones largas con distinta cantidad de jugadores. Estos resultados no justifican declarar el juego equilibrado al 100 %.

## Archivos y compatibilidad

Nuevos: `src/balance.mjs`, `test/balance.test.mjs`, `tools/audit-balance.mjs`, auditoría y este documento.

Modificados: `src/world.mjs`, `src/loot.mjs`, `src/workers.mjs`, `src/population.mjs`, `src/structures.mjs`, `src/adventure.mjs`; `server.mjs`, `package.json`, `tools/start-godot.mjs`, `test/protocol.test.mjs`, `test/expansion-rts.test.mjs`; scripts Godot `ui/population.gd`, `ui/hud.gd`, `network/client.gd`, `tests/native_smoke.gd` y copias en `el-cerco-3d-(4.5)/`.

Build 0.20.0, protocolo 1 con capacidad `balanced-survival`, guardado v6. No se reducen inventarios ni botín ya existente. En partidas guardadas se conserva la fecha de la próxima oleada; los intervalos nuevos se aplican después. Los 90 segundos iniciales corresponden a mundos nuevos. Ambos `project.godot` se conservan.

Reinicia el servidor con Ctrl+C y `node tools/start-godot.mjs`; vuelve a abrir Godot.

Siguiente fase propuesta: identidad visual, gráficos y audio. Esperar confirmación del usuario.
