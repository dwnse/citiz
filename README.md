# El Cerco

## Inventario Supervivencia

**I / icono de mochila** abre el inventario con Sam en 3D, equipo, suministros, materiales y accesos rápidos. Consumir, equipar, recargar y fabricar munición usan las reglas y existencias reales del servidor. Orden de casillas guardado por personaje. [Controles, captura y validación](docs/INVENTARIO_SUPERVIVENCIA.md).

## Arte 021 — Fase 1: personajes con esqueleto

Agente y zombi común sustituidos por modelos GLB animados de Quaternius (CC0).
Apuntado estable, piernas independientes del disparo, recarga, daño, muerte y
reaparición conectados al servidor. Implementado en ambas carpetas Godot;
119 pruebas del servidor y verificaciones nativas aprobadas.
[Antes/después, clip, licencias, archivos y límites](docs/ARTE_FASE_1.md).
La fase 2 de arte —resistente, bóveda y tres piezas de base— espera aprobación.

## Actualización 0.20 — Equilibrio

Más preparación entre oleadas, progresión sin reinicio al nivel fácil, botín más limitado y mejoras de extracción efectivas. Comunidad muestra el balance teórico de raciones y el HUD anticipa la oleada. 118 pruebas aprobadas en esa entrega y auditoría reproducible. [Valores, controles y límites](docs/EQUILIBRIO_020.md).

## Actualización 0.19 — Mundo y campaña

Hospitales y laboratorios con salas recorribles: activar la entrada, despejar infectados, asegurar el objetivo y recuperar el informe. Amenaza ligada a las fases del mes, progreso persistente e indicaciones en HUD/diario. Los lugares ocupados conservan su funcionamiento anterior cuando añadir un interior causaría conflictos. [Controles y límites](docs/MUNDO_CAMPANA_019.md). Fase 4 pendiente de confirmación.

## Actualización 0.18 — Gestión RTS

**O / Comunidad** permite elegir un residente y ordenar Mover, Detener, Al refugio o Trabajo automático. Separación al caminar, rutas renovadas ante bloqueos y conservación de carga. 108 pruebas aprobadas e integración Godot en ambas carpetas. [Controles, reglas y límites](docs/RTS_018.md). Fase 3 pendiente de confirmación.

## Actualización 0.17 — Estabilidad y controles

Reconexión automática limitada, aviso de perfil abierto en otra conexión, parada conservada durante peticiones en curso y bloqueo de controles al perder el foco. Distribución más uniforme de envíos y reutilización de datos de edificios por lote. [Cambios, validación y límites](docs/ESTABILIDAD_017.md). La fase de gestión RTS queda pendiente de confirmación.

## Actualización 0.16

Godot recibe cambios incrementales en lugar de estados completos repetidos. Se conservan reconexión, visibilidad de rivales y clientes anteriores. Detalles y mediciones: [RED_INCREMENTAL_016.md](docs/RED_INCREMENTAL_016.md).

## Actualización 0.15

Dos galerías recorribles, gas, válvulas de ventilación y armarios de suministros compartidos. 96 pruebas aprobadas. Ver [COLECTORES_015.md](docs/COLECTORES_015.md) para controles, compatibilidad, archivos y pendientes.

## Actualización 0.14

Trabajadores visibles con rutas y transporte, patios de expedición, señales de radio, colectores entre zonas y aspectos de cuenta. 91 pruebas aprobadas. Rendimiento gráfico mejorado mediante mallas compartidas por parte animada. Detalles, controles y límites: [MUNDO_VIVO_014.md](docs/MUNDO_VIVO_014.md). Reinicia el servidor con `node tools/start-godot.mjs` y vuelve a abrir Godot.

## 0.13 — Hordas con habilidades y gestión de comunidad

Cuatro jefes con preparación visible y habilidades interrumpibles; resurrección sin botín duplicado. **O / Comunidad** abre población, raciones y prioridad de puestos. Los trabajadores consumen suministros y los edificios explican por qué se detienen. Corregida la extracción simultánea del último golpe de un recurso y la selección de objetivos por ruido.

**83 pruebas aprobadas** y verificación Godot en ambas carpetas. [Mecánicas, controles, evidencia y pendientes](docs/HORDAS_COMUNIDAD_013.md). Reinicia Node con `node tools/start-godot.mjs` y vuelve a abrir Godot para cargarlo.

## 0.12 — Supervivencia, expediciones y final jugable

Sprint y esquiva, tres armas, materiales diferenciados, 18 estructuras por categorías, rescate de trabajadores, producción, investigación, día/noche, pausa individual y ajustes. Las seis claves abren el enfrentamiento con el Paciente 0; la cura exige una comunidad superviviente y registra recompensas cosméticas por cuenta sin duplicarlas.

**Reinicia el servidor anterior con Ctrl+C y ejecuta `node tools/start-godot.mjs`; después reinicia Godot.** Los guardados migran a v6 con respaldo v5. No hace falta borrar la partida; si ya terminó, crea otra.

[Controles, mecánicas, pruebas y pendientes de 0.12](docs/SUPERVIVENCIA_012.md). 74 pruebas Node aprobadas e integración Godot. La calidad artística final y una campaña larga con jugadores humanos siguen pendientes.

Las secciones 0.11–0.5 siguientes son un registro histórico. Para las reglas, controles y pendientes vigentes consulta la guía de 0.12 enlazada arriba.

## 0.11 — Reconstruir la bóveda y recursos próximos

Con un superviviente vivo, acércate a las ruinas de tu bóveda y pulsa **K**, o el botón **Reconstruir bóveda**: cuesta 100 materiales, recupera 750 PV y restablece construcción y reapariciones. Mantiene las mejoras del núcleo. Si toda la comunidad ya fue eliminada, la partida sigue terminada.

Al cargar partidas se generan también árboles y rocas recolectables cerca de las bases, con rótulos visibles incluso llevando la pistola. **Q** equipa el hacha-pico y clic mantenido extrae materiales. El cliente avisa si el servidor antiguo no envía recursos. **Cierra el servidor con Ctrl+C, ejecuta `node tools/start-godot.mjs` y vuelve a abrir el juego**. Actualizar archivos sin reiniciar Node no cambia el servidor que ya está ejecutándose.

Verificación: 60 pruebas Node e integración nativa; reconstrucción con permisos y coste, retorno de reaparición, guardado, carga de recursos y presencia visible de modelos de árbol y roca.

## 0.10 — Territorio guiado, regiones y defensas

**B** muestra la parcela con borde azul y centro reservado rojo. **Mostrar un lugar disponible** sitúa el plano en un lugar válido. Catálogo desplazable de **14 estructuras**, con torreta, generador, reciclador, cocina, recolector de agua y sacos defensivos. Los zombis dejan suministros para la mochila: **E** recoge; **H/Y/N** consumen comida, agua o botiquín. Más árboles, rocas y ruinas distribuidos por región. [Reglas y comprobaciones](docs/EXPANSION_010.md).

**Q: pistola / hacha-pico.** Tala árboles y pica rocas con clic mantenido para conseguir materiales de construcción. [Controles, cantidades y regeneración](docs/RECOLECCION.md).

Las ocho construcciones tienen funciones jugables y acciones explícitas en su ficha: [funciones de edificios](docs/FUNCIONES_EDIFICIOS.md). Incluye blindaje en taller, cierre automático de portones, riego de huertos y almacenes compartidos de materiales y munición.

## 0.9: interfaz, mapa y rendimiento

Interfaz con tarjetas, barras de necesidades, acceso visible a construcción y avisos de acciones. El modo construcción centra la cámara en la base y explica los rechazos. Rueda del ratón para acercar/alejar. Oleadas cada 35 segundos. Carreteras deterioradas, señales de comunidades, escombros y ruinas de suministros identificadas. Geometría estática agrupada y objetos persistentes reutilizados. [Cambios y medición de rendimiento](docs/MEJORAS_09.md).

## 0.8: filas, gestión y suministros renovables

En Godot: **Mayús + arrastrar** coloca filas conectadas de defensas; **clic derecho** selecciona edificios para usar, reparar, mejorar o desmontar. Tres niveles por edificio. **V** registra ruinas cercanas: 25 materiales y 6 balas, con espera compartida de dos minutos. Conserva guardados v5. [Reglas y verificación](docs/MECANICAS_08.md).

Las carpetas `godot/` y `el-cerco-3d-(4.5)/` reciben los mismos scripts actualizados. Se conserva la configuración de proyecto de cada una. Reinicia el juego y el servidor para cargar los cambios.

## 0.7: recarga, supervivencia y construcción

Corregida la recarga que se bloqueaba por un contador negativo. Godot incorpora catálogo de ocho estructuras, cuadrícula, encaje por bordes y cámara de construcción RTS. Taller, enfermería, pozo, huerto, almacén, portón y pinchos tienen funciones validadas por servidor. Comida e hidratación visibles y guardado v5 con respaldo de v4. **40 pruebas aprobadas**, más integración nativa con recargas repetidas y estructuras sincronizadas.

[Controles, costes, funciones y límites de 0.7](docs/MECANICAS_07.md). Reinicia Godot para cargar los nuevos scripts.

## Cliente Godot 4 — primer corte 3D

Nuevo proyecto independiente en [godot/project.godot](godot/project.godot), verificado con **Godot 4.5.1**. Conserva el servidor Node y la versión web. Para jugar: ejecuta `node tools/start-godot.mjs`, importa el proyecto Godot y pulsa F5. La partida de ensayo usa puerto 3002 y `data-godot/`.

[Instrucciones Windows y dos clientes](godot/README.md) · [Auditoría, contrato de red, pruebas y paridad pendiente](docs/MIGRACION_GODOT.md).

31 pruebas Node aprobadas e integración nativa con dos clientes, combate, construcción y reconexión. Incluye minimapa, reloj de asedio, indicadores de poderes, efectos mágicos básicos y disparo sintetizado. Migración parcial: faltan aceptación manual completa, pulido audiovisual y validación de toda la progresión nativa.

## Versión 0.6: historia y magia

Recupera la radio con **E**, alcanza tu bóveda y pulsa **E**. Después, **J** muestra las señales de seis magos. Cada encuentro enseña un poder al agente y aporta una clave a su comunidad. Las seis permiten abrir el sello central con **E**. El combate contra el Paciente 0 sigue pendiente.

| Tecla | Poder | Maná | Recarga | Efecto |
|---|---|---|---|---|
| 2 | Alivio | 20 | 12 s | Recupera 25 PV |
| 3 | Ímpetu | 25 | 18 s | Velocidad ×1,6 durante 6 s |
| 4 | Fulgor | 30 | 22 s | Pistola de 34 a 48 de daño durante 8 s |
| 5 | Temple | 25 | 20 s | Reduce daño un 40 % durante 8 s |
| 6 | Vínculo | 40 | 30 s | Hasta 3 infectados visibles a 12 unidades durante 8 s; excluye jefes |
| 7 | Amparo | 35 | 24 s | Absorbe 40 de daño durante 6 s |

Maná: +4/s mientras el agente esté vivo, conectado y conozca algún poder. Los encuentros no se agotan para otros jugadores. Guardado v4 con copia exacta del formato anterior, incluidas partidas v3. Verificación actual: **30 pruebas aprobadas** y revisión visual de radio y diario. Prólogo audiovisual, recorrido manual completo y etapa 6 pendientes.


## Versión 0.5: comunidades y asedios

Los mundos nuevos tienen **cuatro comunidades de diez plazas** en un mapa continuo de 220 × 220 unidades. Elige Bosque, Montaña, Ciudad o Subterráneo antes de entrar. La elección queda vinculada al agente de esa partida; al reconectar conserva facción, inventario y plaza. Los mundos anteriores se guardan como legado de una comunidad, sin mover bases ni añadir territorios a la fuerza.

Cada comunidad construye, repara y desmantela únicamente sus muros. **T** deposita 20 materiales en la bóveda propia. **E** junto a una bóveda rival roba hasta 20 del depósito durante un asedio, con intervalo de tres segundos. Los disparos alcanzan rivales, muros y núcleos durante la ventana válida; los aliados no reciben fuego amigo. Para dañar o robar a una comunidad debe tener al menos un miembro vivo conectado. Esta protección es contra jugadores: la horda continúa siendo peligrosa fuera del asedio y con defensores desconectados.

Configuración local: primera ventana a los dos minutos, dura 90 segundos y se repite cada cinco minutos. El HUD muestra el reloj. El perfil `production` propone primera ventana el día 11 y luego dos horas al día; es una propuesta configurable en `src/communities.mjs`, no una regla definitiva ni un despliegue público. Los parámetros quedan persistidos en cada mundo al crearlo.

Sin núcleo, sus miembros dejan de reaparecer. La comunidad se elimina cuando no quedan miembros vivos, incluyendo los desconectados. Quedar solo no otorga victoria: Paciente 0 y la cura siguen pendientes.

**Medición histórica de 0.5:** 21 pruebas de reglas/integración y prueba local de 2/10/20/40 clientes. Ver [carga medida](docs/CARGA.md). Con 40 y 96 zombis: aproximadamente 30 ticks/s, entrada p95 de 29,7 ms y cero errores en una prueba breve de loopback. No es una garantía de producción.

Prototipo de supervivencia cooperativa para PC. Motor propio 2.5D en Canvas, cámara isométrica elevada y servidor autoritativo Node.js. No requiere instalar paquetes ni un editor de motor. Arte geométrico temporal dibujado por código, sin recursos externos.

## Iniciar

Requiere Node.js 22 o posterior (verificado con 24.19.0).

```powershell
npm start
```

Abre http://127.0.0.1:3000. Elige una partida en la sala, escribe un nombre y entra. **Nueva partida** crea otro mundo sin borrar los anteriores; **Volver a partidas** permite cambiar de mundo. Para un segundo agente abre esa misma dirección en una **ventana privada u otro perfil de navegador** y elige el mismo mundo. Dos pestañas normales comparten sesión. Si el puerto está ocupado, usa `$env:PORT='3001'` antes de arrancar. La demostración de esta entrega está en http://127.0.0.1:3001.

Alternativa verificada para dos clientes en el mismo navegador: uno en `http://127.0.0.1:3001` y otro en `http://localhost:3001`; el navegador separa sus identidades por host. Selecciona el mismo mundo en ambos. Cambia el puerto en las dos direcciones si usas otro.

No necesitas `npm install`. Para detener, Ctrl+C en la terminal. El servidor guarda al cerrar y cada cinco segundos; vuelve a iniciarlo y entra desde el mismo perfil para recuperar al agente.

## Controles del cliente web anterior

| Acción | Control |
|---|---|
| Caminar en dirección de pantalla | WASD / flechas |
| Apuntar / disparar | Ratón / clic izquierdo mantenido |
| Recargar | R |
| Plano de muro / cancelar | B / 1 o Escape |
| Girar plano / construir | G / clic izquierdo |
| Recoger botín o reparar bóveda cercana | E |
| Fabricar 18 balas por 15 materiales | C |
| Reparar muro cercano por 10 materiales | F |
| Desmantelar muro cercano, devuelve 10 | X |
| Mejorar territorio junto a la bóveda | U |
| Depositar 20 materiales en bóveda propia | T |
| Ayuda | H |

Muros: coste 20, alcance de colocación 9, territorio inicial de radio 18. U a menos de 6 unidades de la bóveda mejora el radio a 24, 30 y 36 por 60, 90 y 120 materiales. No se construye en el corredor central, sobre rocas ni a menos de 4 unidades de la bóveda. El plano verde anticipa las reglas; el servidor vuelve a verificarlas. Las rocas bloquean movimiento y disparos; los zombis buscan rutas para rodearlas.

El mundo comienza con una espera de 45 segundos para la primera oleada; el lanzador de entrenamiento puede ajustarla a 35. Las siguientes llegan cada 35 segundos de día o 28 de noche mientras haya conexión; el nivel aumenta cada dos oleadas y vuelve a ciclar. El jefe de nivel 3 anuncia un ataque de radio 6: sal del círculo rojo. Los infectados muertos dejan suministros y munición. La bóveda permite reaparecer; sin ella no hay reaparición hasta reconstruirla con un superviviente vivo.

## Verificar

```powershell
npm run check
npm test
```

La suite usa almacenamiento temporal, dos clientes HTTP/SSE independientes y un reinicio del servidor. No altera la partida de desarrollo. Véase [pruebas reproducibles](docs/PRUEBAS.md).

## Mundos locales independientes y configuración

La sala permite hasta ocho partidas activas por proceso. Las terminadas conservan sus guardados y perfiles, pero no ocupan ese límite: siempre puedes crear otra cuando haya una plaza activa disponible. Nuevos: cuatro comunidades y cupo total 40. Legado: una comunidad y cupo 10. Las claves del navegador se conservan por mundo. Los archivos antiguos migran a v6 dejando una copia exacta `world.json.vN.bak`, donde N es la versión de origen (1–5). Sin clientes conectados se detiene la simulación, incluidos los ataques de infectados; la caducidad de 30 días sigue vigente.

Para un directorio independiente en otro proceso, desde otra terminal:

```powershell
$env:PORT='3001'
$env:DATA_DIR='data-mundo-2'
npm start
```

Nunca ejecutes dos procesos con el mismo `DATA_DIR`. `MODE=development` habilita Nueva partida; `MODE=production` bloquea la creación desde HTTP. Ambos siguen limitados a loopback: el perfil production no ofrece aún seguridad ni despliegue de un servicio público.

## Estado real

La versión 0.12 incluye un recorrido funcional desde la supervivencia hasta Paciente 0 y la cura, con victoria condicionada y recompensas persistentes. La aceptación manual de una campaña completa sigue pendiente. Los territorios usan geometría temporal: Subterráneo es una zona oscura del mismo plano; faltan túneles, interiores, rutas alternativas y balance humano de guerra.

Solo se escucha en `127.0.0.1`. El cliente Godot se ejecuta desde el proyecto; todavía no se distribuye un ejecutable exportado ni un servicio público. La navegación usa cuadrícula y puede atacar muros si no encuentra ruta. Se midieron 40 clientes de transporte en loopback; falta una partida prolongada con 40 clientes gráficos en red externa. El guardado puede perder hasta cinco segundos tras una caída abrupta y no tiene diario transaccional. Hay perfiles locales y premios cosméticos persistentes, pero faltan autenticación externa y tienda.

Consulta [decisiones](docs/DECISIONES.md), [plan](docs/PLAN.md), [protocolo](docs/RED.md) y [registro de entrega](docs/ENTREGA.md).
