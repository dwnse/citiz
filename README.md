# El Cerco

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

## Controles

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

La primera oleada llega a los 45 segundos de la primera inscripción. Las siguientes llegan cada 95 segundos mientras haya conexión; el nivel aumenta cada dos oleadas y vuelve a ciclar. El jefe de nivel 3 anuncia un ataque de radio 6: sal del círculo rojo. Los infectados muertos dejan materiales y munición. La bóveda permite reaparecer; al morir se pierde el 20 % de materiales. Sin bóveda no hay reaparición.

## Verificar

```powershell
npm run check
npm test
```

La suite usa almacenamiento temporal, dos clientes HTTP/SSE independientes y un reinicio del servidor. No altera la partida de desarrollo. Véase [pruebas reproducibles](docs/PRUEBAS.md).

## Mundos locales independientes y configuración

La sala permite hasta ocho mundos independientes por proceso. Nuevos: cuatro comunidades y cupo total 40. Legado: una comunidad y cupo 10. Las claves del navegador se conservan por mundo. Los archivos antiguos migran a v4 dejando una copia exacta `world.json.v1.bak` o `world.json.v2.bak` o `world.json.v3.bak`, según su formato de origen.

Para un directorio independiente en otro proceso, desde otra terminal:

```powershell
$env:PORT='3001'
$env:DATA_DIR='data-mundo-2'
npm start
```

Nunca ejecutes dos procesos con el mismo `DATA_DIR`. `MODE=development` habilita Nueva partida; `MODE=production` bloquea la creación desde HTTP. Ambos siguen limitados a loopback: el perfil production no ofrece aún seguridad ni despliegue de un servicio público.

## Estado real

Implementadas las mecánicas de etapas 1–3 y la base funcional de etapa 4: sala, navegación, radio ampliable, cuatro territorios/comunidades, cupos, asedios y eliminación. Los territorios aún usan geometría temporal: Subterráneo es una zona oscura del mismo plano, no una red de túneles; faltan puntos de interés elaborados, rutas alternativas diseñadas y balance humano de guerra. La etapa 5 tiene base funcional en 0.6; etapa 6 pendiente. El plazo y la expiración no completan fases, historia, victoria y recompensas.

Solo se escucha en `127.0.0.1`. No es un servicio listo para Internet ni un ejecutable nativo. La navegación usa cuadrícula, dos búsquedas máximas por mundo y tick y caché de 1,5 s; puede atacar muros si no encuentra ruta. Árboles decorativos sin colisión. Se midieron 40 clientes de transporte en loopback, no 40 navegadores renderizando ni una partida prolongada. El guardado puede perder hasta cinco segundos tras una caída abrupta y no tiene diario transaccional. No hay cuentas de producción, cosméticos ni premios.

Consulta [decisiones](docs/DECISIONES.md), [plan](docs/PLAN.md), [protocolo](docs/RED.md) y [registro de entrega](docs/ENTREGA.md).
