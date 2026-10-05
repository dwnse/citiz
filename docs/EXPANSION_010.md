# Construcción guiada y expansión 0.10

## Dónde construir

B aleja la cámara y muestra la parcela completa. El límite exterior azul marca el radio de 18 m, ampliable con U cerca de la bóveda. El círculo rojo de 4 m mantiene libre el núcleo. Carreteras públicas, ruinas, recursos vivos, edificios y ocupantes impiden colocar allí. El plano verde es la confirmación local de posición válida; el servidor comprueba de nuevo al confirmar.

El botón «Mostrar un lugar disponible» busca espacio para el edificio seleccionado, centra allí la cámara y mueve el cursor al plano. No construye ni cobra automáticamente. Si faltan materiales, la bóveda está destruida o el jugador está demasiado lejos, explica el impedimento. Las muertes temporales desactivan construcción hasta reaparecer.

## Catálogo

Los ocho edificios anteriores conservan su función. Desplaza el catálogo con el ratón para encontrar los seis nuevos. Las teclas 1–8 corresponden a los ocho originales; los nuevos se seleccionan con clic. Clic derecho abre la ficha y E ejecuta su acción principal cerca del edificio.

| Nuevo edificio | Coste | Función |
|---|---:|---|
| Torreta | 80 | Detecta infectados a 14 m, consume una bala por disparo cada segundo y causa 24/30/36 de daño según nivel. Necesita generador a 8 m y hasta 60 balas almacenadas; E transfiere hasta 30 de la reserva. No atraviesa muros/ruinas ni ataca infectados controlados. |
| Generador | 70 | E consume 20 materiales y da energía a edificios aliados a 8 m durante 90/120/150 s según nivel. No cobra si ya está activo. |
| Reciclador | 65 | Con energía, E convierte 10 balas de reserva en 3 materiales, con espera de 10 s. El rendimiento evita multiplicar materiales fabricando y reciclando munición. |
| Cocina | 55 | Consume una comida y un agua de la mochila para recuperar hasta 60 alimento y 15 PV. |
| Recolector de agua | 30 | Produce un uso cada 45 s al nivel inicial, máximo cinco. E recupera 40 hidratación. |
| Sacos defensivos | 10 | Barrera económica de 100 PV que bloquea movimiento y disparos. Se repara y mejora. |

## Recursos y exploración

La generación regional tiene mayor densidad de árboles en bosque, más piedra en montaña, menos recursos naturales en ciudad y predominio de piedra en subsuelo. Los obstáculos, carreteras y edificios existentes se respetan; las cantidades finales dependen de esos espacios. Se añaden hasta dos ruinas de suministros por comunidad, fuera de la base. V permite registrar estas ruinas con la espera compartida existente. Los mundos de legado conservan su geometría de ruinas anterior.

La ampliación regional se añade una sola vez (`resourceLayout: 2`), conserva árboles/rocas anteriores y su agotamiento y evita duplicados. Se aplica también a partidas existentes. Las mallas de los recursos se agrupan y solo se muestran los recursos próximos para contener el coste gráfico.

## Botín de infectados

Todas las vías de muerte —pistola, infectados controlados, pinchos y torretas— usan la misma tabla y dejan un único botín. Los nuevos botines no contienen materiales de construcción: incluyen munición y, según el infectado, comida, agua o botiquín. Se recogen con E y se acumulan en la mochila. H consume comida (+35 alimento), Y agua (+40 hidratación) y N botiquín (+30 PV). No se gasta si la necesidad está completa. Las armas adicionales siguen pendientes; no se muestran armas ficticias como botín.

Los botines que ya estaban guardados conservan su contenido. Los suministros iniciales y las ruinas mantienen sus recompensas de materiales. Todos los nuevos campos de mochila, energía y munición se guardan como ampliaciones opcionales de v5.

## Verificación

57 pruebas Node aprobadas. Incluyen torretas con/sin energía, consumo de balas, bloqueo de disparos, exclusión de controlados, botín único, mochila, consumo, cocina, distribución regional y rechazo explicativo de construcción. Integración Godot aprobada: 14 planos, búsqueda de parcela válida, construcción, recarga, recolección, reconexión y persistencia.

Muestra local de cinco segundos con renderizado real a 1280×720, RX 580 2048SP, dos clientes en un proceso, tres infectados y cinco edificios: 135,01 FPS medios, fotograma p95 8,425 ms. Incluye la región ampliada y modo construcción. No certifica batallas de 40 jugadores. Captura revisada en `godot-preview.png`; medición en `performance-010.json`.

Actualiza ambas carpetas Godot y reinicia servidor y cliente para aplicar el catálogo y las reglas nuevas. No se borran partidas.
