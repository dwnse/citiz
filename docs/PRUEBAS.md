# Verificación — 3 de octubre de 2026

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
