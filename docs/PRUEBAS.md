# Verificación

## Arte 021 — Fase 1

119/119 pruebas Node y sintaxis aprobadas. Integración nativa general y prueba
específica de animación con dos escenas conectadas: cero fallos en las dos
carpetas Godot. Se verificaron ocho direcciones, apuntado, movimiento con disparo,
recarga, persecución, contacto, daño, muerte y reaparición. Capturas y clip real
en [ARTE_FASE_1.md](ARTE_FASE_1.md), junto con licencias, escenarios y límites.
RX 580 2048SP a 1280×720: 144,28 FPS en muestra pequeña; 117,02 FPS en render
estático con 96 infectados, 80 muros y 32 residentes, sin IA para los añadidos.

## Verificación 0.20 — Fase 4

118/118 pruebas Node aprobadas; comprobación sintáctica aprobada. Integración Godot 4.5.1 en ambas carpetas con previsión de oleada, balance de raciones y regresiones anteriores. Captura `population-020.png` revisada. Auditoría teórica en `BALANCE_020.json`, reproducible con `node tools/audit-balance.mjs`. No equivale a una campaña humana ni certifica equilibrio final. Valores, metodología y límites en EQUILIBRIO_020.md.

## Verificación 0.19 — Fase 3

114 pruebas Node aprobadas. Integración Godot 4.5.1 en ambas carpetas: recintos y pistas, señal de entrada y objetivo activo, además de las regresiones anteriores. Captura preparada `interior-019.png` revisada a 1280×720. Las reglas de combate/presencia, recompensa, persistencia, migración, fases y pausa se validan en servidor; no se ha completado una expedición humana ni una campaña completa. Detalles en MUNDO_CAMPANA_019.md.

## Verificación 0.18 — Fase 2

108/108 pruebas Node aprobadas, cero fallos. Integración nativa Godot 4.5.1 aprobada en ambas carpetas: listado individual, detener, selección/cancelación de destino y regreso a automático, además de las regresiones anteriores. Captura `population-018.png` revisada: panel y botones legibles a 1280×720. Datos y límites de la prueba de 32 trabajadores en RTS_018.md y performance-workers-018.json. La evasión no garantiza resolver toda congestión; no se ha certificado una campaña humana completa.

## Verificación 0.17 — Fase 1 — 2026-10-05

`npm run check` aprobado; 103/103 pruebas Node, cero fallos. La prueba nueva verifica reutilización de edificios y población dentro de un lote, aislamiento entre comunidades y renovación de datos tras cambios.

Integración nativa aprobada con Godot 4.5.1 sin interfaz gráfica, tanto en `godot/` como en `el-cerco-3d-(4.5)/`. Verifica parada tras movimiento en curso, bloqueo al perder foco, reinicio de carrera al reconectar, corte real del canal y recuperación automática, conservación de identidad y edificios, cancelación al salir, sustitución de sesión sin bucles, límite de cinco reintentos y reconexión manual posterior. Se mantienen las pruebas de recarga, combate, construcción, recolección, galerías y guardado. Los scripts de ambas carpetas coinciden.

Carga final aislada: 40 clientes, 96 infectados iniciales, 32 residentes y 36 edificios durante 140,49 s; 30 ticks/s, cero errores, entrada HTTP p95 de 55,42 ms y 2585,8 KiB/s recibidos. Comparación y límites en `CARGA_MIXTA_017.md`. No acredita sesiones largas en red externa ni 60 FPS constantes. Fase 2 pendiente de confirmación del usuario.

## Verificación 0.16 — 2026-10-05

102/102 pruebas Node aprobadas. Integración nativa sin interfaz gráfica aprobada en `godot/` y `el-cerco-3d-(4.5)/`, con Godot 4.5.1: reconstrucción de estados incrementales, secuencias, borrados, combate, recargas repetidas, construcción, recolección, galerías, reconexión y persistencia. No equivale a una sesión humana completa.

Carga local con 40 clientes: 30 ticks/s, cero errores y tráfico reducido un 83,3 %. El p95 de entrada HTTP aumentó de 56,10 a 81,39 ms. Detalles y límites en `CARGA_MIXTA_016.md`; no se certifican FPS mediante esta prueba sin renderizado.

## Verificación 0.6 — 2026-10-03

npm run check correcto; npm test: 30/30 aprobadas, cero fallos. Nueve pruebas nuevas: orden del prólogo, claves y visitas repetibles, maná/recarga/secuencia/vida, velocidad y daño con vencimiento, resistencia/absorción, control con límite y desconexión, línea de visión, movilidad reservada y migración v3/v4.

Navegador: sala 0.6, ingreso en Cerco 6, E recupera radio y cambia objetivo, J muestra diario y mensaje. Revisión visual del diálogo y HUD. Los tests de encuentros posicionan agentes como fixtures; no prueban una travesía humana. Pendientes recorrido manual completo, combate mágico multijugador y balance. CARGA.md corresponde a 0.5, no certifica carga de 0.6.


## Incremento 0.5 — evidencia más reciente

21 pruebas de reglas e integración aprobadas: se suman cupos 4 × 10 permanentes, última plaza concurrente HTTP, propiedad de muros, ventanas de asedio, defensa offline contra rivales, robo con cadencia y secuencias, destrucción de núcleo y eliminación por comunidad, ausencia de victoria automática, fuego amigo, información privada y migración v2/v3. La prueba v1 se actualizó al formato de destino v3 y sigue verificando clave, fecha, inventario y backup exacto.

Se ejecutó `node tools/benchmark.mjs` con 2, 10, 20 y 40 clientes HTTP/SSE, movimiento y disparos, y oleadas de nivel 3. Resultado en CARGA.md/JSON. Una primera medición detectó 22–24 ticks/s por temporización; el acumulador corregido produjo ~30. La última medición de 40: 29,9 ticks/s, entrada p95 29,7 ms, 3718,4 KiB/s recibidos totales y cero errores. Prueba breve, sin promesa de capacidad pública.

Revisión del navegador: crear **Cerco 5** mostró 0/40 y las cuatro comunidades. Elegir Pacto del Asfalto situó el agente en Ciudad, con bóveda propia, color, minimapa y reloj de asedio. Construir allí descontó 20 materiales (100 → 80) y colocó muro en ese territorio. Registro de errores consultado: vacío. Los mensajes de combate/robo/eliminación se verificaron en pruebas del servidor; aún no hay una sesión humana completa de guerra.

### Reproducción de asedio

1. Crear mundo nuevo; entrar con dos perfiles en facciones diferentes. Cada uno aparece cerca de su núcleo y debe caminar al enemigo usando el minimapa.
2. Antes de 02:00, disparos contra rival o núcleo no causan daño. No se puede construir, reparar o reciclar en propiedad ajena.
3. En ventana activa (90 s), con ambos vivos conectados, disparar daña rivales y defensas. E a menos de 6 unidades del núcleo enemigo roba hasta 20 materiales; otra E inmediata no vuelve a cobrar.
4. Desconectar el defensor bloquea daño/robo de rivales. No protege contra zombis ya presentes.
5. Destruir núcleo y matar sus miembros: no reaparecen y solo su comunidad se elimina. Mantener otro miembro vivo desconectado conserva la comunidad. La superviviente no recibe victoria ni monedas todavía.
6. Reiniciar conserva facción, tesorería, núcleos, construcciones, vidas, plazas y horario. Reingresar no cambia de bando.

## Incremento 0.4 — evidencia más reciente

- `npm run check` aprobado para servidor, simulación, navegación, almacenamiento y cliente.
- `npm test`: **14 pruebas aprobadas, 0 fallos**, unos 4,8 segundos. Incluye las siete anteriores y siete casos nuevos de navegación, colisiones, aparición, mejora de territorio, aislamiento entre mundos, migración y bloqueo de creación en producción.
- Navegador: se creó **Bosque 2** desde Nueva partida y se entró. Fabricación llevó reserva de 60 a 78 y materiales de 100 a 85. Colocar un muro dejó 65 materiales. Un disparo dejó 11 cartuchos; recargar restauró 12 y redujo reserva a 77. Se observó la primera oleada, daño, muerte y vuelta a la sala. Registro de errores consultado: vacío en ese momento.
- La partida anterior apareció como **Bosque original**, preservada y terminada. Se comprobó la interfaz de selección entre ambos mundos.
- Comprobación adicional con **dos clientes gráficos**: Alfa en `127.0.0.1:3001` y Bravo en `localhost:3001`, ambos en Bosque 3. El muro construido por Alfa apareció en la vista de Bravo; Alfa pasó de 100 a 80 materiales. La sala mostró 2 inscritos y 1 conectado tras salir Bravo. Reingresó como Bravo sin añadir otra plaza. Captura de ambos agentes y el muro en `el-cerco-preview.png`. Se cerró la pestaña auxiliar y se dejó Bosque 4 sin inscritos para el usuario.
- La mejora de bóveda se verificó mediante acciones de servidor y persistencia en pruebas; no se ha completado todavía su recorrido manual en navegador.
- Las pulsaciones rápidas de movimiento enviadas por automatización no bastaron para certificar un recorrido manual; movimiento y colisiones sí se prueban en la simulación y en HTTP.
- Se verificó la conexión, construcción y reconexión con dos clientes gráficos; no se completó una defensa coordinada de oleadas, pruebas de carga a 40 ni cortes eléctricos. Las cifras instantáneas del HUD no son un benchmark.

### Reproducción de lo añadido

1. Desde la sala, Nueva partida; aparece seleccionada y con cero inscritos. Entrar con un nombre.
2. Crear otra partida después de Volver a partidas: debe empezar con inventario/base independientes. Volver a la primera conserva al agente.
3. Acercarse a una roca: bloquea caminar y disparar. Un infectado con destino al otro lado debe rodearla.
4. Junto a la bóveda, U descuenta 60 materiales y amplía radio a 24; siguientes mejoras cuestan 90 y 120 y terminan en radio 36. Fuera de alcance o sin recursos no cobra.
5. Reiniciar el servidor y volver a entrar: ambos mundos, mejoras e identidades se conservan. Un archivo v1 recibe copia exacta `.v1.bak` antes de migrar.

## Registro histórico de 0.3

## Ejecutado

- `npm run check`: sintaxis de servidor, simulación y cliente aprobada. JavaScript nativo, sin paso de compilación ni empaquetado binario.
- `npm test`: **7 pruebas aprobadas, 0 fallos**. Última ejecución tras corregir alcance de ataque de bóveda y ampliar integración: aproximadamente 5,1 s.
- El entorno aislado impidió crear el proceso de pruebas (`spawn EPERM`); se ejecutó con el permiso de terminal correspondiente. No se sustituyó por una afirmación de funcionamiento.
- Servidor HTTP iniciado y página abierta en el navegador integrado. Entrada al mundo, HUD, estado en línea, menú inicial y plano de construcción observados. Reconexión desde el navegador tras reiniciar recuperó el agente y la partida avanzada. Registro de errores del navegador consultado: vacío en ese momento.
- La partida de prueba avanzó hasta oleadas y caída de la bóveda. Se observó daño/reaparición. Esto es una comprobación funcional parcial, no una sesión de balance ni una prueba completa de habilidad humana.

## Flujos automáticos cubiertos

1. Colocación válida cobra una vez; repetición, corredor, distancia y coordenada inválida no cobran ni construyen.
2. Pistola causa daño, cadencia impide segundo disparo, pared detiene proyectil, recarga transfiere reserva.
3. Movimiento normalizado y sin efecto cuando el jugador está desconectado.
4. Muerte sin bóveda no reaparece; comunidad termina; expiración real cierra admisiones.
5. Un infectado recorre distancia hasta la bóveda y la destruye sin atravesar la colisión. Esta prueba detectaría el error corregido de alcance menor que la colisión.
6. Diferencia de resistencia entre niveles, presencia del jefe en nivel 3 y coste de reaparición.
7. Dos conexiones HTTP/SSE: distintas identidades, rechazo de acciones sin conexión, movimiento, fabricación, intento de falsificar vida/materiales, rechazo de secuencia repetida, construcción y daño observados por el segundo cliente, desconexión, reinicio con mismos inventarios/muro/fecha/secuencia y nueva sesión con misma identidad.

Las pruebas del jefe validan creación, no todos los patrones de combate. No hay prueba de recompensas duplicadas porque no hay recompensas implementadas.

## Recorrido de aceptación manual reproducible

1. `npm start`, abrir el puerto indicado. Entrar con nombre; ver agente completo desde arriba y salud 100. WASD debe mover según pantalla, cámara sigue. Ratón apunta; clic consume un cartucho; R recarga.
2. Caminar hacia la bóveda. E junto a un paquete recoge recursos; E junto a bóveda permite repararla. C gasta 15 materiales y añade 18 balas.
3. B muestra plano; moverlo a terreno cercano fuera del corredor y a más de 4 unidades del núcleo; G gira; clic verde coloca y descuenta 20. Probar rojo sobre corredor: no se cobra. F repara muro dañado; X recicla.
4. A los 45 s llega primera oleada. Disparar hasta eliminar infectado; recoger botín. Construir delante de otro y observar que ataca el muro. Dejar un acceso permite que ataque el núcleo.
5. Abrir ventana privada y entrar con nombre distinto. Moverse y construir: ambos deben ver la misma acción. Cerrar un cliente; su plaza permanece. Reabrir el mismo perfil: mantiene identidad e inventario.
6. Detener servidor con Ctrl+C, reiniciar y recargar las páginas. Entrar de nuevo; muro, inventarios y fecha deben conservarse.
7. Tras cuatro oleadas llega la primera de nivel 3. Observar jefe y círculo rojo previo a golpe; salir antes de que termine. Balance humano pendiente.
8. Dejar que destruyan la bóveda y mueran los agentes conectados. No reaparecen. Si queda un miembro vivo desconectado, la comunidad aún no se elimina: debe volver y morir para ese desenlace.

## Límites de evidencia

No se ha completado todo este recorrido manual, ni una defensa coordinada entre dos personas. No se midieron percentiles de rendimiento, 40 conexiones, pérdida de paquetes, móviles, dos PCs de una LAN ni un proceso muerto entre escritura y rename. No se probó audio con escucha humana. No confundir FPS instantáneos del HUD con benchmark.

## Entrega 0.12 — verificación ejecutada

- `npm test`: 74 pruebas aprobadas, 0 fallos.
- `npm run check`: sin errores de sintaxis.
- `node tools/verify-godot.mjs .tools/godot-4.5.1/Godot_v4.5.1-stable_win64_console.exe --capture`: NATIVE_SMOKE failures=0, guardado leído correctamente, captura real revisada. Prueba final con servidor v6 y perfiles cosméticos.
- Segundo proyecto: la misma integración con `--project=el-cerco-3d-(4.5)` también pasó. Comparación byte a byte: los diez scripts actualizados coinciden; configuraciones del proyecto preservadas.
- Render normal: 143,99 FPS de media, p95 7,031 ms; 387 llamadas de dibujo en la muestra final. Escena sintética ampliada: 73,10 FPS, p95 16,755 ms; no incluye IA de las entidades añadidas. Ver performance-012.json y performance-012-stress.json.
- Carga HTTP/SSE 2/10/20/40: sin errores; ~30 ticks/s. Condiciones y límites en CARGA_012.md.
- El servidor que el usuario mantiene en 3002 todavía anuncia saveVersion 5 y no anuncia build: necesita reinicio. Las pruebas usaron carpetas temporales y no migraron ni reemplazaron su partida activa.

Los nuevos flujos verificados incluyen cobros y filas atómicos, inventarios tipados, producción con trabajadores, recargas/cambio de arma, pausa, recogida de muestra junto al sello, victoria condicionada, nueva oportunidad al eliminar la comunidad que mató al jefe, expiración real durante pausa, copia exacta de guardado v5 y conservación de cosméticos entre mundos sin duplicar premios o plazas. Las limitaciones de producto y el siguiente paso están en SUPERVIVENCIA_012.md.

## Retoma de entrega 0.12 — 4 de octubre de 2026

- npm test: 74 aprobadas, 0 fallos. El primer intento no pudo crear subprocesos (spawn EPERM); la repetición autorizada completó la suite.
- npm run check: aprobado, ampliado a adventure, inventory, rewards, harvesting y loot.
- Integración Godot 4.5.1 sin ventana: NATIVE_SMOKE failures=0 en godot/ y el-cerco-3d-(4.5)/. Ambos verificaron guardado y lectura con dos identidades, cinco estructuras y una mejora.
- Corregidas las instrucciones que todavía presentaban la etapa 6 como pendiente, el guardado como v4 y las oleadas como intervalos de 95 segundos. Registro de entrega actualizado a 0.12.
- Se utilizaron guardados temporales. Esta revisión no repite mediciones gráficas ni sustituye la campaña manual completa pendiente.


## Continuación 0.13

83/83 pruebas Node aprobadas. Nuevos flujos en test/horde-population.test.mjs: habilidades con preparación, interrupción por disparos, resurrección única sin duplicar botín, límites de enemigos y colisión, frenesí y caducidad, prioridades de trabajo, raciones atómicas, desconexión, agotamiento compartido, descarga única y selección por ruido.

La integración Godot pasa en los dos proyectos. Comprueba rótulos de jefe, marcador de frenesí, pantalla de comunidad, bloqueo de movimiento con menú y eliminación de filas obsoletas. La captura real de 0.13 se revisó. Reporte de escena pequeña: performance-013.json. Carga ampliada 2/10/20/40 clientes: CARGA_013.md; cero errores, ~30 ticks/s con 40 clientes y 96 infectados. Las condiciones y límites se detallan allí y en HORDAS_COMUNIDAD_013.md.


## 0.14 — Mundo vivo

91 pruebas Node y comprobación sintáctica aprobadas. Integración nativa en ambos proyectos. Trabajadores: ruta, carga guardada, entrega y recogida tras destruir puesto; paredes bloquean extracción. Radio: distancia, visión, caducidad y premio único. Colectores: salida libre y costes atómicos. Cosméticos: propiedad, saldo, repetición y equipamiento por sesión autenticada.

Estrés gráfico a 1280×720 con 96 infectados, 80 muros y 32 residentes: 119,20 FPS medios frente a 50,14 antes de fusionar mallas rígidas; p95 10,39 ms. Es render sintético, sin IA de las entidades añadidas. Simulación separada de 32 residentes: tick medio 2,11 ms, p95 6,36 ms. Ver MUNDO_VIVO_014.md y sus reportes.


## 0.15 — Galerías

96 pruebas Node aprobadas y comprobación sintáctica correcta. Godot comprueba las dos galerías, ocho accesos, gas y ventilación. La carga combinada local mantuvo 30 ticks/s durante 137,09 s con 40 clientes, 96 infectados iniciales, 32 residentes y 36 edificios; sin errores HTTP/red. Tick p95 muestreado 23,57 ms. Detalles y límites: COLECTORES_015.md y CARGA_MIXTA_015.md.
