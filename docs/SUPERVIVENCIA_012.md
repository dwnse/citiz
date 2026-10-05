# El Cerco 0.12 — Supervivencia, comunidad y desenlace

## Arranque

1. En la consola del servidor anterior, pulsa **Ctrl+C**.
2. Desde la carpeta CityZ ejecuta `node tools/start-godot.mjs`.
3. Abre `godot/project.godot` o `el-cerco-3d-(4.5)/project.godot` y ejecuta la escena principal.
4. Elige una partida activa. Una partida ya derrotada conserva su resultado; usa **Nueva partida** para comenzar otra.

El lanzador detecta un servidor HTTP que siga abierto antes de abrir el guardado. El cliente explica si falta la versión de supervivencia. No se han detenido procesos del usuario ni reemplazado sus partidas durante las pruebas.

Motor verificado: Godot 4.5.1, Compatibility, Windows. Se conservan ambos `project.godot`, incluidas sus opciones originales. Los scripts sustituidos de la segunda carpeta tienen respaldo en `.tools/backups/survival-012`.

## Ciclo jugable

**Reunir → construir → explorar → regresar → investigar → defender → resolver el sello.**

- Árboles: madera; rocas: piedra; ruinas y estaciones: chatarra; laboratorios de expedición: componentes.
- Los materiales antiguos se conservan como **recuperados**, que sustituyen ingredientes de construcción. El antiguo campo `wood` es el total, para conservar compatibilidad con reglas anteriores.
- Cada plano muestra su receta. Las filas se cobran completas o se rechazan sin consumir piezas parciales.
- Almacenar y recuperar conserva el tipo de material. Desmontar un almacén deja su contenido en el suelo.
- Reparación, munición, combustible y mejoras antiguas usan materiales generales; consumen primero recuperados, después madera, piedra, chatarra y finalmente componentes. La receta de armas e investigación reserva sus componentes antes de cobrar materiales generales.
- Guía inicial: recolección, primera construcción, suministros, expedición y entrega. Conserva el progreso al reconectar.

### Exploración

Hay 12 señales de expedición en el mapa de cuatro regiones. Son los cuadrados turquesas del minimapa; árboles y rocas cercanos también aparecen marcados.

| Lugar | Recompensa | Al entregar el informe |
|---|---|---|
| Hospital de campaña | 2 comidas, 2 botiquines | 1 rescatado; requiere plaza en refugio |
| Estación de bombeo | 3 aguas, 20 chatarra | 1 informe de investigación |
| Laboratorio Umbral | 3 componentes, 18 balas | 1 informe de investigación |

Todos los informes dan 1 investigación y 15 recuperados al entregarlos con E junto a la bóveda viva. Puedes llevar un informe; cada señal comparte una espera de 180 segundos. El registro requiere proximidad y línea libre. Los puntos son puestos de expedición señalizados, todavía no interiores explorables.

### Comunidad y construcción

Catálogo de **18 estructuras**, filtrado por Defensa, Supervivencia e Industria. Se conservan muros conectados, portones, filas, inspección y validación del territorio.

| Edificio nuevo | Función |
|---|---|
| Refugio | Aloja 2 rescatados |
| Aserradero | Un trabajador y árbol vivo a 10 m: 6 madera cada 20 segundos |
| Cantera | Un trabajador y roca viva a 10 m: 8 piedra cada 20 segundos |
| Laboratorio del Sello | Investigación y síntesis de la cura |

La producción consume golpes del recurso, se detiene al agotarlo y almacena hasta 60 materiales. E recoge. Solo funciona con miembros vivos conectados. La asignación de trabajadores es automática, por orden de edificios, y está limitada por supervivientes y alojamiento. Por ahora los trabajadores son población gestionada; no tienen personajes que caminen por la base.

Investigar cuesta 2 informes, 2 componentes y 20 materiales. Hay 3 niveles: cada uno añade 1 recurso a cada golpe manual y 4 de daño a las torretas.

### Combate y tiempo

- Mayús: correr, velocidad ×1,45. Gasta 18 resistencia/s solo al moverse; recuperación 12/s.
- Espacio: esquiva de 0,35 s, velocidad ×2,2 y mitad del daño recibido; cuesta 25 resistencia, enfriamiento de 3 s. Respeta obstáculos.
- Pistola: 12 balas, alcance 28, recarga 1,4 s.
- Escopeta: 6 balas, alcance 11, daño 90, recarga 2,2 s. Es un disparo concentrado, todavía sin perdigones individuales.
- Rifle: 20 balas, alcance 38, daño 42, recarga 2 s.
- J abre el diario y los botones de armas. La primera fabricación exige taller cercano: escopeta 60 materiales + 2 componentes; rifle 90 + 4. Cambiar devuelve el cargador a la reserva y exige recargar.
- Corredores rápidos y quebrantadores resistentes acompañan a los infectados comunes. El tamaño y los rótulos ayudan a distinguirlos.
- Disparar, correr y registrar expediciones generan ruido: los infectados detectan desde más lejos.
- Ciclo ambiental de 10 minutos: 6 de día y 4 de noche. Cambia la luz; de noche las oleadas pasan de 35 a 28 s y aumenta la detección. La lluvia duplica la velocidad del recolector de agua.
- El diario muestra también la fase del calendario de 30 días reales. Sus nombres no equivalen todavía a cinco campañas con contenido diferente.

### Final del Sello

Las seis claves permiten despertar al **Paciente 0**. Tiene 1800 PV y una descarga anunciada; bajo media vida acelera y descarga con mayor frecuencia.

La muestra se recoge con E, incluso junto al sello. Si su portador muere, queda en el suelo. Para sintetizar la cura en un Laboratorio del Sello se necesita:

1. Ser la única comunidad inscrita que sigue sin eliminar.
2. Que esa comunidad haya derrotado al Paciente 0.
3. Sus seis claves, la muestra y 3 informes disponibles.
4. No haber alcanzado los 30 días reales.

Si se elimina a la comunidad que derrotó al origen, la muestra queda invalidada y el sello permite un nuevo enfrentamiento. Así otra comunidad puede completar el desenlace.

El resultado y el título **Custodio del Sello** se guardan. Una cuenta ganadora con contribución recibe 12 monedas y 1 sello cosmético, una sola vez por mundo. Cuentan bajas, expediciones, pasos de la guía o poderes aprendidos. El perfil se comparte entre mundos nuevos usando la identidad local; materiales y poder empiezan de cero. No hay aún tienda cosmética, pagos ni autenticación externa.

## Controles y accesibilidad

| Control | Acción |
|---|---|
| WASD / ratón | Movimiento / apuntado |
| Mayús / Espacio | Carrera / esquiva |
| Q / clic | Cambiar arma-herramienta / disparar o extraer |
| R / C | Recargar / fabricar munición |
| B / G | Construcción / girar |
| Mayús y arrastrar | Fila de defensas en modo construcción |
| Clic derecho | Inspeccionar edificio |
| E / V | Interactuar / registrar ruinas |
| H / Y / N | Comida / agua / botiquín |
| J | Diario, expediciones, armas y saldo cosmético |
| P | Pausa jugando solo |
| Ajustes | Volumen, sombras, límite de FPS y pantalla completa |

La pausa congela producción, oleadas, enfriamientos y movimiento; otro jugador conectado la cancela. El plazo de 30 días reales sigue corriendo. Abrir un menú no pausa automáticamente una partida multijugador. Volumen, sombras y límite de FPS se guardan localmente.

## Guardados y arquitectura

Servidor Node autoritativo; Godot dibuja y envía intenciones. Guardado **v6**, protocolo de transporte 1 y build 0.12.0. Al cargar v5 se crea `world.json.v5.bak` antes de migrar inventarios y perfiles. Las migraciones anteriores siguen funcionando. El saldo, el registro de recompensas y el resultado se guardan juntos mediante el reemplazo atómico existente del JSON. La prueba de reinicio confirma que un premio no se repite.

Nuevos módulos: `src/inventory.mjs`, `src/adventure.mjs`, `src/rewards.mjs` y `godot/ui/settings.gd`. Cambios en world, structures, harvesting, loot, story, storage, navigation, server, HUD, minimapa, colocación, modelos y cliente de red. La versión web anterior permanece en el proyecto, pero la interfaz de los sistemas nuevos está en Godot.

## Verificación y rendimiento

- `npm test`: **74/74**. Incluye materiales y filas atómicas, pausa, armas, trabajadores, final, autoría, plazo, migración v6, cuentas entre mundos y recompensa única.
- `npm run check`: análisis de sintaxis del servidor y módulos principales.
- Integración nativa en ambos proyectos: dos clientes HTTP/SSE, personaje visible, movimiento, disparo y recargas, herramienta, recursos, 18 planos, categorías, esquiva, modelos nuevos, guardado y reconexión.
- Captura real: `docs/godot-preview.png`.
- RX 580 2048SP, 1280×720, Compatibility: escena pequeña ~144 FPS de media, p95 ~7,03 ms.
- Escena sintética con 96 infectados y 80 muros: ~73 FPS de media, p95 ~16,76 ms. Mide renderizado de entidades añadidas estáticamente; no añade su IA ni demuestra 60 FPS constantes.
- Carga del servidor con 40 clientes HTTP/SSE y 96 infectados: ~30 ticks/s, sin errores de red en la prueba breve. Tras optimizar rutas y filtrar recursos próximos, p95 muestreado del tick pasó de 27,58 a 15,04 ms y tráfico de ~14 a ~9,5 MiB/s agregados. Véanse `CARGA_012.md` y `CARGA_012_antes.md`. La prueba precede a la última integración de perfiles cosméticos; no mide una campaña terminada ni la entrega masiva de premios.

Son mediciones locales breves. Quedan pruebas prolongadas, red externa y equilibrio de una campaña con jugadores humanos. El límite de 40 sigue siendo un objetivo de despliegue a validar.

## Siguiente etapa y límites

Esta entrega completa un recorrido funcional hasta la cura. **No equivale al acabado final del juego.**

1. Partida manual completa de progresión y asedio; ajustar costes, presión nocturna, ritmo y defensa offline.
2. Arte final propio: personajes, animación esquelética, interiores y relieve. La referencia visual sigue por encima de los modelos provisionales.
3. Trabajadores visibles, órdenes individuales y necesidades de población; regiones con túneles y rutas alternativas reales.
4. Variedad adicional de habilidades de jefes, eventos y contenido específico para las fases del mes.
5. Tienda de cosméticos, acceso de cuenta independiente del archivo local y recuperación de identidad.
6. Tráfico diferencial y pruebas de horas con 40 clientes gráficos en red externa.

Identidad propuesta: supervivencia militar alrededor de una catástrofe médica y mágica; bóvedas cian, metal recuperado y madera, seis voces que reconstruyen el experimento, investigación ligada a expediciones y un final que exige reconstruir la cura. Esta dirección guía el contenido implementado; aún requiere una pasada artística completa para distinguirse visualmente al nivel solicitado.
