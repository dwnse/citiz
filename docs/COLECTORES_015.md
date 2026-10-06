# El Cerco 0.15 — Galerías recorribles

## Recorrido y supervivencia

Los dos pares de colectores pueden conducir ahora a **Galería de las raíces** y **Cámara del Umbral**. La entrada de superficie lleva a una escalera interior; hay que caminar unos 20 m hasta la escalera opuesta para salir por el otro acceso.

- Entrar cuesta 25 de resistencia. Salir es gratis, incluso con resistencia agotada.
- Espera de 3 segundos entre accesos de una galería, para evitar entradas/salidas accidentales repetidas.
- Paredes, pilares y colisiones son autoritativos. El servidor busca un punto libre de llegada y no cobra si la salida está ocupada.
- El gas consume 20 de resistencia por segundo; la regeneración normal sigue aplicándose. Al agotarse, inflige 4 de daño por segundo antes de blindaje y efectos defensivos.
- **E en la válvula azul** ventila durante 120 segundos. No se puede reiniciar ese plazo pulsando repetidamente.
- **E junto al armario**, con ventilación activa, entrega 12 chatarra, 2 componentes y 12 balas. El armario tiene una espera compartida de 180 segundos; varios jugadores no pueden cobrar el mismo lote.
- El HUD y los rótulos explican gas, válvula, armario y salida. La nube visible desaparece al ventilar.
- Gas solo afecta a jugadores vivos conectados. La pausa individual congela los plazos. Posiciones y estados del recinto sobreviven al guardado.

Son interiores presentados con el techo retirado, dentro del plano compartido del mapa. Todavía no son un nivel subterráneo independiente ni tienen techos que se oculten dinámicamente. Su geometría sigue siendo provisional.

## Partidas existentes

Al inicializar cada galería se comprueba su espacio completo. Si hay obstáculos, recursos, edificios o personajes, se omite esa galería sin borrar nada. Ese par conserva el viaje directo de 0.14, con coste 25 y espera de 15 segundos. Los mundos de legado conservan su mapa original. La decisión de incorporación queda guardada; no se reconstruyen paredes cada fotograma.

Guardado v6 y protocolo 1; build 0.15.0. El cliente exige la capacidad `collectors` para detectar servidores anteriores. Las pruebas usan directorios temporales, no las partidas del usuario.

## Verificación

- 96 pruebas Node aprobadas, con cinco pruebas nuevas de accesos, recorrido, colisiones, botín compartido, ventilación, pausa, migración y posición al reconectar.
- Comprobación sintáctica aprobada, incluyendo `src/collectors.mjs`.
- Integración Godot: dos galerías y ocho accesos recibidos; gas visible antes de ventilar, oculto después; indicador de suministros actualizado. Se conserva la integración de combate, construcción, recarga, cosméticos y reconexión.
- Captura preparada para revisar la geometría: `collectors-015.png`. No representa una partida humana completa.
- `performance-015.json` mide la escena pequeña de integración; no es una garantía de 60 FPS en toda partida.
- `tools/benchmark-mixed.mjs` añade una prueba de dos minutos con clientes HTTP/SSE, IA de infectados, población y guardado periódico. Usa agentes y edificios con salud aumentada para mantener la carga; no sirve para evaluar equilibrio de combate. Resultado: 137,09 s, 40 clientes, 96 infectados iniciales, 32 residentes y 36 edificios; 30 ticks/s, tick p95 muestreado 23,57 ms y cero errores HTTP/red. Tráfico total 15.818,5 KiB/s; sigue siendo alto para internet. Reportes: `CARGA_MIXTA_015.json` y `CARGA_MIXTA_015.md`.

## Archivos

Nuevos: `src/collectors.mjs`, `godot/world/collector.gd`, `test/collectors.test.mjs`, `tools/benchmark-mixed.mjs` y este documento.

Modificados: `src/passages.mjs`, `src/world.mjs`, `src/adventure.mjs`, `server.mjs`, `package.json`, `tools/start-godot.mjs`, `test/living-world.test.mjs`, `test/protocol.test.mjs`, y los scripts Godot `world/main.gd`, `ui/hud.gd`, `network/client.gd`, `tests/native_smoke.gd`.

Scripts Godot sincronizados en `el-cerco-3d-(4.5)/`, conservando ambos `project.godot`. Respaldo anterior del segundo proyecto en `.tools/backups/collectors-015/`.

## Inicio y siguiente aceptación

Cierra el servidor anterior con Ctrl+C, ejecuta `node tools/start-godot.mjs` desde CityZ y vuelve a abrir Godot. Busca los accesos violetas cerca del cruce central; J explica el recorrido.

Siguiente aceptación: una partida humana que conecte construcción, rescate, galerías, asedio y cura; después, sesiones de varias horas y pruebas en red externa. Siguen pendientes el arte definitivo, interiores completos de hospitales/laboratorios, relieve, eventos específicos del mes, órdenes individuales de residentes y separación entre peatones. Esta entrega no se declara juego terminado al 100 %.
