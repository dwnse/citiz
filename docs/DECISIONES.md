# Decisiones

## Decisiones 0.6

Los seis magos enseñan a cada agente y comparten claves dentro de su comunidad. Las pistas indican coordenadas; los recorridos cortos usan corredores reservados. Esta movilidad y el prólogo mediante radio y diálogo son provisionales. El servidor valida vida, aprendizaje, maná, secuencia y recarga. Los vencimientos absolutos persisten al reiniciar. Temple reduce daño antes del escudo y blindaje. Vínculo exige línea de visión, excluye jefes y termina al morir o desconectarse el controlador. Abrir el sello no concede victoria ni premios.


## Incremento 0.5 — decisiones actuales que sustituyen prototipos previos

- Nuevos mundos: cuatro comunidades de diez, 40 inscritos permanentes, mapa 220 × 220. Centros (50,50), (50,160), (160,50), (160,160); territorios máximos de radio 36 no se solapan. Selección de facción solo al inscribirse; reconectar no cambia bando ni libera plaza. Comunidad sin núcleo no admite nuevos agentes.
- Bosque/montaña varían nivel 1–3; montaña genera aproximadamente 65 % de los infectados. Ciudad/subterráneo reciben al menos nivel 2. Número depende de conectados y se limita a 96 infectados globales. Materiales y munición de suministros iniciales difieren por región. No hay comida como sistema independiente todavía.
- Regiones con paletas, vegetación y recursos diferentes, minimapa y rocas propias. Subterráneo es una representación provisional sobre el mismo plano; túneles, accesos, POI y rutas alternativas necesitan diseño posterior. No presentar esto como mapa final.
- Muros con `communityId`; servidor comprueba propietario para reparación, reciclaje y territorio. Vías protegidas x=50, x=160 y y=105. Los aliados bloquean proyectiles sin recibir daño.
- **Propuesta reversible de asedio:** preset development, demora 120 s, ciclo 300 s, ventana 90 s. Preset production, demora 10 días, ciclo 24 h, ventana 2 h. Parámetros copiados al mundo al crear; cambiar presets no altera una partida existente.
- PvP, daño a estructuras rivales y robo solo en ventana activa y con al menos un defensor vivo conectado. Es protección frente a rivales; la IA no se pausa por desconexión y puede dañar bóvedas. Esta asimetría se documenta y queda pendiente de balance, no se oculta como protección offline completa.
- Tesorería inicial 100 materiales por comunidad. T deposita 20 propios; E junto a núcleo enemigo vivo roba hasta 20 cada 3 s. El servidor controla saldo, distancia, ventana, presencia y secuencia. Muerte sin núcleo es definitiva. Una facción con último vivo desconectado no se elimina todavía; presión antiabandono pendiente de fase final.
- Migración v1/v2 a v3 con backup exacto. Mundos antiguos mantienen mapa 100, única comunidad de legado, posiciones, claves y asedios desactivados. Los nuevos campos no reinventan ni reinician la historia de la partida.
- En memoria `world.vault` sigue siendo alias del núcleo primario para compatibilidad interna; al cargar v3 se vuelve a vincular al objeto de `communities[0]`. La instantánea del cliente expone como `vault` su núcleo propio.
- Envío de zombis/muros/botín/disparos hasta 75 unidades; rivales visibles hasta 70 sin inventario privado. Bases y estados comunitarios son públicos; compañeros de comunidad siguen sincronizados. No hay compresión ni deltas.
- Reloj de simulación por acumulador, pasos fijos a 30 Hz y recuperación acotada después de un bloqueo del proceso. Se corrigió el uso ingenuo de setInterval(33 ms), que en esta máquina producía 22–24 Hz. Prueba breve de 40 clientes: ~30 Hz; detalles y limitaciones en CARGA.md.

## Historial de decisiones anteriores

## Confirmado por el usuario

PC primero; cámara alta con personaje completo; supervivencia, zombis, construcción, bóveda y cooperación; autoridad del servidor; mundo de 30 días reales; cuatro comunidades de diez y máximo 40 inscritos sin liberar plazas al desconectar. Seis magos, Paciente 0, cura y victoria de una única comunidad constituyen el objetivo final. Economía cosmética de cuenta separada del poder temporal. El estilo cartoon sombrío es dirección propuesta por el usuario.

## Propuesta implementada y reversible

- Repositorio inicialmente vacío. Node.js 24.19.0 disponible; Godot no encontrado en PATH. Para poder ejecutar y verificar hoy, cliente Canvas 2.5D y servidor JavaScript sin dependencias. Simulación independiente de renderizado para una eventual migración a un cliente 3D. Esta decisión no compromete un motor comercial definitivo.
- Renderizado isométrico ortográfico: cámara sigue al agente, suelo visible, personajes enteros pequeños y profundidad por orden de dibujo. Arte y sonido sintéticos temporales propios.
- Simulación a 30 Hz; instantáneas SSE a 10 Hz; intención de movimiento HTTP cada 65 ms. Suficiente como transporte inicial en loopback; reevaluar WebSocket/UDP y predicción con latencia real.
- Corte vertical: una comunidad de hasta 10 plazas permanentes, bosque de 100 × 100 unidades y un tipo de muro. Sin PvP en este corte. No presentar este límite provisional como el objetivo final de 40.
- Umbral de activación: primera inscripción. Entrada tardía abierta mientras haya cupo y mundo activo. Duración persistida; primer ingreso fija inicio. Se puede cambiar esta política antes de la etapa 4.
- Pistola de 12 cartuchos, 60 en reserva, 34 de daño, intervalo de 250 ms y recarga de 1,4 s. Blindaje absorbe hasta 60 % del golpe mientras tenga puntos. Parámetros pendientes de balance.
- Materiales iniciales 100. Construir 20; reparar muro 10; reciclar devuelve 10; fabricar 18 balas cuesta 15; reparar 100 PV de bóveda cuesta 15. Inventario abstracto, sin peso ni slots.
- Reaparición a los 6 s con bóveda viva; pérdida del 20 % de materiales; no se renueva munición ni blindaje. Sin bóveda, muerte definitiva. Los desconectados permanecen inscritos y conservan vida; no aparecen como objetivo atacable. No se considera a un desconectado muerto para eliminar la comunidad.
- Radio 18, máximo 80 muros. Corredor público vertical de ancho 6 y zona central de radio 4 libres. Estas restricciones garantizan acceso en este mapa sencillo; no sustituyen un análisis de conectividad de mapas futuros.
- Oleadas 1,1,2,2,3,3, repetidas. Jefe de resistencia alta con área telegrafiada durante 2 s. Sin selección entre las cuatro habilidades propuestas todavía.
- Reloj mundial corre sin usuarios; nuevas oleadas requieren conectados, los infectados existentes siguen atacando la bóveda. Es una regla provisional de desarrollo, pendiente de decidir junto a ventanas de asedio.
- Identidad local por clave aleatoria guardada en el navegador; sesión HTTP de memoria. Una conexión por identidad. No equivale a autenticación de cuentas de producción.
- `DATA_DIR` y `PORT` separan instancias locales. Producción no habilitada; sigue ligada a loopback. Nunca reutilizar el mismo almacenamiento entre procesos.

## Pendiente de prueba o decisión de mayor impacto

- Sensación de movimiento y apuntado con latencia real, recepción de daño y economía de oleadas.
- Motor 3D definitivo, distribución nativa, móviles y accesibilidad; no instalar motores sin necesidad inmediata.
- Asedios anunciados, ventanas, defensa offline, pérdidas, robo y condiciones de presión territorial. No fijados ni simulados en el prototipo.
- Magia, PvP, cuatro comunidades, mapa regional, misión de apertura y recompensa exclusiva. Conservar estas decisiones abiertas hasta un corte con dos comunidades.
- Capacidad 40: medir CPU, tráfico, percentiles de latencia y relevancia espacial antes de afirmarla.
- Persistencia transaccional, migraciones, recuperación de corrupción y adjudicación única de premios. No hay premios implementados que puedan darse por seguros.

## Incremento 0.4 — sustituye los supuestos anteriores donde corresponda

- Un proceso aloja un directorio de hasta ocho mundos separados. Crear y elegir se hace en la sala; cupo por mundo sigue siendo diez y una sola comunidad. No equivale a cuatro comunidades de diez.
- Migración explícita del contenedor v1 a v2 con copia exacta `world.json.v1.bak`. Los mundos antiguos conservan geometría sin añadir rocas sobre contenido guardado. Claves locales se traducen a `{id,worldId}`. Los nuevos mundos añaden rocas con colisión y bloqueo de disparos.
- A* de cuadrícula cardinal, máximo 2400 expansiones por búsqueda, dos búsquedas por mundo/tick y caché de 1,5 s. Se comprueban segmentos antes de seguirlos. Si no hay ruta, un infectado cercano puede romper un muro. Caché solo en memoria; no se transmite ni persiste.
- Radio de territorio mejorable 18 → 24 → 30 → 36, costes 60/90/120; servidor exige cercanía, vida de núcleo y fondos. `vault.upgrades` es un campo opcional v2; ausente significa cero. No amplía el máximo de 80 muros.
- Aparición busca posición libre alrededor del punto inicial/retorno; la reparación ya no resucita una bóveda destruida.
- `MODE=production` deshabilita crear mundos vía HTTP; no habilita exposición pública ni añade cuentas de producción. La producción real sigue pendiente.
- Guardado escribe y hace fsync del archivo temporal antes de rename. Sigue sin journal y con ventana de pérdida de cinco segundos. No se ha probado corte eléctrico.
