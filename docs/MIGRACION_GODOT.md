# Migración de El Cerco a Godot 4

## Auditoría previa — 2026-10-03

Base inspeccionada: versión 0.6.0, ES modules, Node >=22, sin dependencias npm. `npm run check` correcto y `npm test` 30/30 antes de modificarla. No se encontró Godot en PATH ni en las ubicaciones superiores consultadas de Downloads/Program Files. El cliente se dirige a Godot 4.5; la verificación con motor se registra al final, sin inferirla de una revisión textual.

| Sistema actual | Archivos | Datos y reglas | Destino / motivo |
|---|---|---|---|
| Autoridad y transporte | server.mjs | 30 Hz, SSE 10 Hz, sesiones, intención, límites HTTP, 8 mundos | Mantener Node. Cliente HTTP/SSE nativo en godot/network |
| Simulación | src/world.mjs | Movimiento, pistola 12/60, daño 34, recarga 1,4 s, muerte, oleadas, inventario, muros | Mantener autoridad; Godot envía intención y presenta estados |
| Navegación y colisión | src/navigation.mjs | A*, presupuesto de 2 búsquedas/tick, rocas, muros y núcleos | Mantener servidor; volúmenes 3D equivalentes en cliente |
| Guardado | src/storage.mjs | JSON v4, v1–v3 con backups, fsync/rename cada 5 s | Sin cambio de esquema; Godot guarda únicamente clave local por perfil/mundo |
| Comunidades | src/communities.mjs | 4 × 10 plazas persistentes, bases, propiedad, asedio, eliminación | Mantener Node y exponer selección/HUD en Godot |
| Historia | src/story.mjs | Radio, 6 magos, claves comunitarias, poderes individuales, maná | Mantener reglas; representación, diario y controles nativos |
| Presentación | public/game.js, index.html, style.css | Canvas, cámara, controles, interfaz, sonido sintético | Sustituir progresivamente por escenas/scripts Godot; conservar web |
| Verificación | test/*.test.mjs, tools/benchmark.mjs | 30 pruebas, carga histórica 0.5 | Mantener y añadir prueba del contrato nativo; no atribuir carga histórica a Godot |
| Assets | docs/el-cerco-preview.png | Captura documental; no modelos/texturas externos | Mallas primitivas y materiales propios de Godot, sustituibles luego |

Datos encontrados sin imprimir claves: `data/world.json` v3, 1 mundo; `data-demostracion/world.json` v4, 7 mundos. Se conservan. Un servidor de ensayo debe usar otro DATA_DIR. La migración existente conserva copia exacta al abrir versiones antiguas. El cliente nuevo no reescribe saves del servidor.

## Arquitectura elegida: A, Node autoritativo

Portar toda la simulación ahora duplicaría reglas ya probadas de recursos, muerte, cupos y persistencia. Godot convierte coordenadas (x,y) del servidor a (x,0,z) y muestra estados recibidos. La colisión de juego sigue resuelta por Node; los cuerpos estáticos del cliente representan los mismos obstáculos, no una segunda autoridad. No se aceptan posiciones ni daños calculados por Godot.

HTTP/SSE conserva compatibilidad web y facilita probar dos clientes. Tiene más tráfico y latencia que un protocolo de deltas; no hay predicción local. La cifra 40 es un límite de inscripción, no una promesa de rendimiento 3D. La prueba histórica de 40 clientes fue breve, local y sin 40 renderizadores. Mundos de 30 días conservan fecha absoluta; la persistencia aún puede perder hasta 5 s ante una caída.

## Riesgos y paridad pendiente

La eliminación actual exige núcleo destruido y ningún miembro vivo, no solo la muerte de un miembro; se conserva para no cambiar reglas silenciosamente. Paciente 0, cura, recompensas, cosméticos, túneles reales, animaciones finales y economía transaccional no existen. El servidor solo escucha en loopback. No hay despliegue público ni autenticación de producción.

Primero se verifica el corte de movimiento/combatir/construir/reconectar. La representación de funciones existentes no implica aceptación visual ni paridad completa. Las funciones nuevas del desenlace quedan después de esa aceptación.

## Contrato de red nativo v1

Cliente estándar Godot 4.5.1; HTTPRequest para mensajes cortos y HTTPClient para leer el flujo SSE incremental. Referencias oficiales: [HTTPClient 4.5](https://docs.godotengine.org/en/4.5/classes/class_httpclient.html), [HTTPRequest 4.5](https://docs.godotengine.org/en/4.5/classes/class_httprequest.html), [Plane 4.5](https://docs.godotengine.org/en/4.5/classes/class_plane.html). Los bytes del flujo se conservan hasta completar el evento para no romper caracteres UTF-8 entre fragmentos HTTP.

| Método / ruta | Solicitud | Respuesta y reglas |
|---|---|---|
| GET /api/protocol | Ninguna | protocol=1, saveVersion=4, tickHz=30, snapshotHz=10. El cliente rechaza otro contrato |
| GET /api/worlds | Ninguna | Directorio, comunidades, cupos, fase |
| POST /api/worlds | {} | Nuevo mundo solo en development; máximo ocho |
| POST /api/join | worldId, communityId, name, key opcional | id, key, seq, worldId, communityId y cookie de sesión. Clave por perfil/puerto/mundo |
| GET /api/events | Cookie y worldId en query | SSE: data seguido de JSON completo y dos saltos de línea. Actualización nominal 10 Hz |
| POST /api/input | x, y, angle, worldId | Intención normalizada por servidor, no posición. Cliente envía cada 65 ms con una petición en curso como máximo |
| POST /api/action | type, seq, worldId y parámetros | Cola ordenada; secuencia creciente. ok=false significa rechazo de regla sin confirmación visual de éxito |

Acciones conectadas: shoot(angle), reload, build(x,y,rot), repair(id), dismantle(id), interact, craft, upgrade, deposit y cast(power). Costes, daño y muerte se calculan en Node. La instantánea conserva esquema de mundo v4; los aliados incluyen inventario y los rivales siguen filtrados. Coordenadas Node (x,y) → Godot (x,0,z); el rayo del ratón intersecta el plano y=0. La cámara mantiene orientación fija para WASD relativo a pantalla.

Errores HTTP: 400 JSON/entrada/inscripción inválida, 401 sesión o clave inválida, 403 origen/mundo/permisos, 404 recurso inexistente, 409 cupo/mundo cerrado o límite de directorio, 413 cuerpo >2048, 429 frecuencia. Un 200 con ok=false también rechaza una acción. Tras cinco segundos sin estados se corta el canal; no se simula movimiento local y la intención remota caduca a los 350 ms. Reconectar reenvía la clave y recupera seq. No hay reintento infinito que expulse otra ventana con la misma identidad.

No se ha alterado el formato persistido v4 ni los inventarios anteriores. El lanzador de ensayo añade solo al mundo aislado un marcador opcional godotTrainingSeeded para no duplicar sus tres zombis y cuatro muros al reiniciar. No es una migración de los mundos anteriores ni una API pública de generación de recursos.

## Etapas y resultados observados

### 1. Auditoría

Leídos package.json, servidor, world, navigation, storage, communities, story, cliente web, pruebas y documentación. Datos inspeccionados solo para versión y número de mundos. Antes del cambio: check correcto y 30/30 tests. Archivo creado: este inventario, antes de implementar el cliente.

### 2. Base Godot

Proyecto independiente godot/project.godot, escena world/main.tscn, escenas player/player.tscn y zombies/zombie.tscn. Cámara ortográfica elevada con seguimiento, terreno y colisiones equivalentes, iluminación, materiales y siluetas de geometría nativa. AnimationPlayer genera quieto, correr, apuntar, disparar, daño y ataque. No hay archivos Blender ni arte final.

Se descargó la distribución oficial portátil Godot 4.5.1 a .tools/ (ignorada por Git), sin instalar globalmente. El intento restringido no pudo escribir el directorio de usuario y terminó con un fallo nativo del motor. Con permiso para ejecutar fuera del entorno restringido, la escena abrió y el renderizado funcionó. Se usó Compatibility/OpenGL 3.3 en Radeon RX 580 2048SP. La primera importación también registró permisos insuficientes de caché; no se presenta ese intento como una validación limpia.

### 3–4. Corte jugable, red y guardado

Prueba real mediante tools/verify-godot.mjs: dos instancias del cliente nativo en un proceso Godot, servidor temporal separado y escena principal completa. Resultado NATIVE_SMOKE failures=0. Verificados: dos presencias, tres infectados, modelos en escena, proyección del ratón sobre suelo, binding físico W, posiciones compartidas, muro compartido con coste único, rechazo de secuencia duplicada, munición, daño visible al segundo cliente, recarga, desaparición de presencia al desconectar, reingreso con identidad/facción/materiales/muro y persecución/daño del infectado. Tras guardar, Node volvió a leer dos identidades y un muro desde disco. Las pruebas existentes verifican migraciones con backup y reinicio HTTP.

Con --capture se renderizó la partida y se escribió docs/godot-preview.png, revisada visualmente. Esto verifica una escena ejecutada, no una maqueta; tampoco equivale a una sesión manual de dos ventanas ni a probar todas las teclas y combinaciones. El plano usa validación espejo y la autoridad vuelve a comprobarlo. Falta aceptación manual de su colocación con ratón y de sensación de control.

Comandos ejecutados:

```powershell
npm run check
npm test
& '.\.tools\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe' --headless --path godot --editor --import --quit
& '.\.tools\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe' --headless --path godot --quit-after 90
node tools/verify-godot.mjs '.\.tools\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe'
node tools/verify-godot.mjs '.\.tools\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe' --capture
```

Regresión final Node: **31/31 aprobadas**, sintaxis correcta. Se añadió test/protocol.test.mjs. La prueba nativa sin renderizado pasó; la ampliación de comprobaciones de apuntado y daño se ejecutó también con renderizado real. No se midieron 40 clientes Godot.

### 5. Paridad por módulo

| Módulo | Funcional en el corte | Pendiente / cómo se verificó |
|---|---|---|
| world | Movimiento, disparo/recarga, daño, construcción, muerte y respawn gobernados por Node | Prueba nativa de movimiento, combate, muro y daño; muerte/respawn en tests Node. Recorrido manual pendiente |
| navigation | Misma autoridad A*, muros/rocas/bóvedas representados con colisión nativa | Tests Node de rutas/colisión; sin navegación Godot paralela |
| storage | Guarda/relee v4 y restaura identidad por clave | Ida/lectura de prueba nativa y migraciones/reinicio existentes; transacciones aún pendientes |
| communities | Directorio y selección, pertenencia, bóvedas, acciones U/T/PvP, reloj de asedio y minimapa | Minimapa/reloj revisados en captura; guerra humana pendiente; no se cambió eliminación |
| story | Radio, magos visibles, diario, E, poderes 2–7, maná/recargas y VFX básicos conectados | Tests de reglas Node; recorrido mágico nativo completo y revisión visual de sus efectos pendientes |
| public/game.js | Cámara, apuntado, modelos, controles principales, inventario, vida, minimapa y disparo sintetizado | Acabado audiovisual y aceptación manual pendientes. Cliente web conservado |

No se descartó ninguna regla del servidor. Canvas y DOM no se trasladaron literalmente: se sustituyen por nodos y mallas. Etapa 6 no iniciada; siguiente paso exacto: probar dos ventanas según godot/README.md, verificar plano/daño/reingreso manualmente y recorrer la progresión de magos/poderes antes del desenlace.

Continuación de interfaz: añadidos ui/minimap.gd y combat/audio.gd; modificados ui/hud.gd y world/main.gd. Se repitió la integración con renderizado tras añadir minimapa, asedio, indicadores de magia y VFX: cero fallos. Se revisó la captura nueva, con dos agentes, tres infectados, daño recibido y muro. Los efectos mágicos están implementados, pero esa prueba de combate básico no los ejercita. Sonido sintetizado con PCM de 8 bits con signo, conforme a [AudioStreamWAV](https://docs.godotengine.org/en/4.5/classes/class_audiostreamwav.html); revisión auditiva manual pendiente.

## Archivos de esta entrega

- Modificados: .gitignore (caché/motor local), server.mjs (GET /api/protocol), README.md (entrada a Godot).
- Nuevos: godot/project.godot; godot/README.md; world/main.tscn, main.gd, shapes.gd; player/player.tscn, actor.gd; zombies/zombie.tscn; camera/follow.gd; network/client.gd; building/placement.gd; combat/presentation.gd y presentation.tres; ui/hud.gd; tests/native_smoke.gd (todos estos bajo godot/). Archivos .gd.uid generados por el editor para sus scripts.
- Nuevos fuera del cliente: tools/start-godot.mjs, tools/verify-godot.mjs, test/protocol.test.mjs, docs/MIGRACION_GODOT.md, docs/godot-preview.png.
- Continuación: godot/ui/minimap.gd y godot/combat/audio.gd; sus referencias están integradas en HUD y escena principal.
- Motor portátil y su caché en .tools/; caché de importación godot/.godot/ y data-godot/ excluidos de Git. No se borró el cliente web ni sus guardados.


## Actualización 0.12 / guardado v6

Inventario tipado, expediciones, armas, investigación, población, combate final y cosméticos son autoritativos en Node. Godot tiene catálogo por categorías, recetas predictivas, objetivos, marcadores, armas del diario y ajustes. Se mantienen ambos proyectos nativos y la interfaz web histórica; los sistemas nuevos se presentan en Godot.

Se transforma v5 a v6 con copia exacta world.json.v5.bak; el material anterior se convierte en recuperado sin perder valor. Las cuentas se asocian a perfiles con saldo y registro de premios por mundo. Una identidad nueva en otro mundo puede acreditar el perfil previo; no traslada recursos ni habilidades. Las identidades antiguas de mundos distintos no se fusionan automáticamente.

Pruebas de migración, cuenta entre mundos, replay, recompensa única y reinicio: test/rewards.test.mjs. Descripción completa: SUPERVIVENCIA_012.md. Las configuraciones project.godot originales se conservan.
