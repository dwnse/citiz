# Red y almacenamiento v3

## Protocolo 0.6

La acción cast recibe power (heal, haste, fury, resist, control o shield) y seq. El servidor comprueba aprendizaje, vida, maná y recarga. interact resuelve radio, bóveda, mago o sello por proximidad, sin aceptar claves del cliente. story en la instantánea contiene señales desbloqueadas, fragmentos de la comunidad, sello y mensaje. Guardado v4: migración v3 con backup exacto world.json.v3.bak. Los formatos v1/v2 conservan sus propias copias.


## Cambios de protocolo 0.5

`/api/worlds` lista capacidad por mundo (40 nuevos, 10 legado) y comunidades con nombre, región, ocupación, eliminación y existencia de núcleo. `POST /api/join` acepta `communityId` solo para inscripción; si la clave ya existe devuelve su comunidad original. La plaza se reserva sin await intermedio entre comprobación y registro. La integración prueba dos peticiones simultáneas a la última plaza.

`POST /api/action` incorpora `deposit`, y `interact` puede robar recursos de núcleo rival. Las reglas consultan presencia SSE autoritativa, facción, distancia, ventana persistente y secuencia. `shoot` resuelve el primer obstáculo/entidad de la trayectoria: aliados bloquean sin recibir daño; rival y estructura requieren asedio válido. El cliente no manda impacto, daño, saldo ni comunidad propietaria del muro.

Snapshot incluye `communities`, `communityId`, `siege` y `connectedCount`; `vault` significa el núcleo de la comunidad del cliente. Zombis/muros/botín/disparos se filtran a 75 unidades; rivales a 70 y sin munición/materiales privados. Compañeros y núcleos comunitarios mantienen visibilidad global. Geometría del mapa es pública. Las instantáneas completas siguen consumiendo mucho tráfico; compresión y deltas pendientes.

Almacenamiento v3: comunidades con núcleo, depósito y eliminación; jugador/muro/zombi con comunidad; tamaño de mapa y reglas de asedio persistidas. La migración de v1/v2 crea backup exacto de origen y transforma mundos anteriores a una comunidad de legado, mapa 100 y asedio desactivado. v3 recarga `world.vault` como alias del núcleo primario; no modifica la fecha ni los IDs. El array de mundos y mapa de cuentas siguen siendo locales en el mismo archivo. No hay transacciones entre servicios ni premios implementados.

Simulación: acumulador de tiempo monotónico, pasos de 1/30 s, hasta cinco pasos por llamada y tiempo recuperable acotado tras un bloqueo largo. La emisión envía la última instantánea al cruzar intervalos de tres ticks. Relojes de mundo/asedio utilizan fecha persistida y hora del servidor. `/api/metrics` muestra coste medio del tick del último lote y bytes SSE acumulados, no métricas de Internet.

## Historial del protocolo 0.4

## Responsabilidades

`public/`: cámara, entrada, interfaz, arte, sonido y previsualización. Nunca aplica daños o gastos confirmados. `src/world.mjs`: reglas autoritativas sin DOM. `server.mjs`: HTTP, sesiones, cuentas locales, difusión y almacenamiento. Cuentas/directorio están lógicamente separados por rutas y datos, pero todavía no son servicios independientes.

## Mensajes

| Ruta | Método | Datos y efecto |
|---|---|---|
| `/api/worlds` | GET | Directorio de mundos, nombre, plazas, conectados, fecha restante y estado |
| `/api/worlds` | POST | `{name}` crea mundo separado, solo desarrollo, máximo ocho |
| `/api/join` | POST | `{name,worldId}` crea identidad; `{key,worldId}` reconecta. Devuelve id, clave, mundo y secuencia; cookie HttpOnly SameSite Strict |
| `/api/events` | GET SSE | Una conexión por identidad; estado a 10 Hz, id propio y presencia |
| `/api/input` | POST | `{x,y,angle}` finitos; normalización y velocidad en servidor; caduca a los 350 ms |
| `/api/action` | POST | `{type,seq,...}`; secuencia estrictamente creciente por jugador persistida |
| `/api/metrics` | GET | Duración del último tick, bytes emitidos acumulados, conexiones, infectados y ticks |

Acciones: `shoot(angle)`, `reload`, `build(x,y,rot)`, `repair(id)`, `dismantle(id)`, `interact`, `craft`, `intro`, `upgrade`. La presentación de la introducción solo marca su lectura. Disparo valida cadencia, cartuchos, recarga, ángulo, paredes/rocas/núcleo y distancia de impacto. No hay mensajes para fijar vida, dinero o inventario. Clientes sin SSE activa no ejecutan acciones. Origen ajeno rechazado; cuerpo limitado a 2 KiB; entradas de movimiento limitadas a 50 Hz y acciones a 40 por segundo por identidad. Falta protección operativa de Internet.

Cada sesión identifica jugador y mundo. La clave de un mundo no puede usarse para ingresar en otro. El cliente añade `worldId` a acciones e intenciones y a la apertura SSE; si otra pestaña cambia la cookie a otro mundo, se rechaza el desajuste. Reingresar invalida sesiones antiguas de la misma identidad. Dos jugadores requieren perfiles separados. Una interrupción de cinco segundos devuelve a la sala para reingresar explícitamente, sin disputar automáticamente la sesión a otra ventana.

Cada cliente recibe **todas las entidades de este pequeño mundo y los inventarios de sus miembros**; no se envían las claves de cuentas. No hay filtrado por proximidad ni información privada de facción porque hay una sola comunidad. Debe cambiar antes de PvP. Las instantáneas grandes se cortan ante contrapresión de salida; SSE intenta reconectar. El cliente muestra RTT aproximado de solicitudes y FPS local; el servidor no ofrece aún percentiles históricos.

## Persistencia

`data/world.json`: contenedor `version:2`, array `worlds` y mapa local `accounts` de clave a `{id,worldId}`. IDs UUID para mundo, jugadores, muros, botín, infectados y eventos. Guarda plazas, secuencias, inventario, vida, bóveda, mejoras, rocas, oleadas, plazo y estado final. `vault.upgrades` es opcional: ausente equivale a cero. No hay cofres, magos o premios todavía.

Cada 5 s: escribe `world.json.tmp`, sincroniza sus datos con fsync, luego renombra a `world.json`. Cierre normal guarda. Tras reinicio, la sesión HTTP se recrea con la clave local y conserva la secuencia del jugador. El plazo no se reinicia; si ya venció, el primer tick cierra el mundo.

Una caída abrupta puede revertir hasta 5 s de progreso; no hay journal ni garantía transaccional ante corte eléctrico. El archivo corrupto o una versión desconocida abortan el arranque. `src/storage.mjs` migra v1 a v2 tras crear copia exacta `.v1.bak`: conserva IDs, fechas, inventarios y construcciones; convierte claves y deja rocas vacías en el mundo antiguo. Las rutas se calculan en memoria, no se guardan ni se sincronizan. La prueba de migración compara el backup y reconecta usando la clave previa.

Las claves locales están en texto en el archivo de desarrollo. Producción requiere cuentas reales, tokens con caducidad, TLS, límites, validación exhaustiva del estado cargado, transacciones y auditoría. El servicio actual permanece en loopback.


## Extensión 0.12

Transporte protocolo 1; guardado v6; /api/protocol anuncia build y features. Nuevas intenciones secuenciadas: sprint {enabled}, dodge, pause, expedition, deliver, weapon {weapon}. El uso del laboratorio se envía como use {id}, con validación completa en el servidor.

/api/join admite accountKey (una clave previa del mismo perfil) al entrar a otro mundo; key sigue reconectando la identidad de ese mundo. Repetir accountKey en un mundo ya inscrito recupera la misma plaza. Las claves nunca viajan en snapshots. El snapshot incluye adventure, recetas, inventario material y cosmetics solo del observador. Los recursos y construcciones se limitan a 85 m, cubriendo el radio máximo de construcción alcanzable desde la base.

El almacenamiento v6 incorpora perfiles cosméticos separados y un registro por mundo para impedir recompensas duplicadas. No hay autenticación de terceros ni recuperación externa de claves en esta versión.


## Extensión 0.13

Build 0.13.0 anuncia boss-variants y population. staff {id} prioriza un puesto y unstaff {id} lo pausa; requiere propiedad y presencia en la base. supply_workers {id} dona una comida y agua al refugio propio cercano. Los snapshots incluyen un resumen de población de la comunidad del observador y cadáveres próximos con existencia limitada. Efectos, raciones y tiempos de cadáveres se congelan durante pausa individual; el plazo real del mundo no.


## Extensiones 0.14

Build 0.14.0 añade capacidades `workers`, `incidents`, `cosmetics`. `workers` contiene residentes visibles a 75 m (posición, estado, carga); las rutas no se serializan. `adventure.incident` comunica la señal activa y `adventure.passages` los accesos. `interact` usa el colector a 3 m; `travel` también permite la acción explícita, con validación autoritativa. `cosmetic` recibe `style` y la secuencia habitual, utiliza exclusivamente el perfil de la sesión y guarda inmediatamente. `cosmetics` devuelve catálogo, propiedad, saldo y aspecto activo. Ninguna compra modifica estadísticas de combate.


## Extensiones 0.15

Capacidad `collectors`; `adventure.collectors` expone recintos, válvulas y esperas compartidas. `adventure.passages` contiene accesos interiores con coste 0 y entradas con coste 25. `interact` ventila o registra el armario, validando proximidad, visión, estado y secuencia. El servidor valida salida libre antes de cobrar. Estado opcional `collectors` en guardado v6.


## Extensión 0.16: delta-snapshots

`GET /api/events?delta=1` negocia mensajes `{wire:1,seq,state}` completos o `{wire:1,seq,base,set,remove,objects,entities}` parciales. Cada conexión empieza completa y recibe otra base cada 100 mensajes. Los mensajes se calculan sobre la vista filtrada del observador. `entities` usa identificadores, campos modificados, borrados y orden opcional; `objects` cambia campos de objetos superiores. Cliente Godot rechaza saltos de secuencia. Sin el parámetro se conserva el formato anterior. El servidor distribuye clientes en tres fases manteniendo 10 Hz por conexión. Guardado v6 sin cambios.

## Extensión 0.17: recuperación y programación de envíos

Al reemplazar una conexión se envía `event: session-replaced` con `data: {}` antes del cierre. Godot cancela la recuperación automática y muestra que el perfil está abierto en otra conexión. Un corte ordinario inicia hasta cinco reintentos usando la identidad guardada; abandonar o entrar manualmente invalida los callbacks anteriores y cancela los reintentos. Las acciones pendientes no se reenvían.

La distribución de tres fases de 0.16 se sustituye por diez posiciones temporales dentro de 100 ms, atendidas por el programador de 10 ms. Se conservan 10 Hz por conexión y 30 Hz de física; tras un bloqueo se omiten envíos vencidos. El estado de carrera se reinicia al ingresar. Guardado v6 y protocolo 1 conservados.
