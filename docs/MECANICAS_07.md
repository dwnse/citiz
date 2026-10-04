# 0.7 — supervivencia y construcción RTS

Prioridad indicada por el usuario: mecánicas y funcionalidad antes de continuar el acabado gráfico.

## Recarga corregida

El contador de 1,4 segundos se restaba por fotogramas hasta quedar negativo. La condición `!p.reload` lo interpretaba como una recarga aún presente y rechazaba las siguientes aunque hubiese munición. Ahora se limita a cero al terminar y se permite iniciar cuando es <=0. La migración corrige contadores negativos guardados. El cargador es de 12; la reserva es independiente y se consumen solo las balas transferidas. Godot muestra RECARGANDO y no envía disparos mientras recarga o está vacío.

## Construcción en Godot

- **B** entra/sale del modo RTS. Se muestra cuadrícula y catálogo; WASD mueve la cámara, el agente permanece quieto y puede recibir ataques. **Escape** vuelve al control de supervivencia.
- **1–8** o los botones eligen estructura; **G** gira; clic coloca. El plano queda activo para seguir construyendo. La rejilla base es de 0,8 unidades y el encaje busca los bordes de piezas cercanas, con precisión de 0,2.
- Las piezas contiguas pueden tocar sus bordes; se rechazan solapamientos por dimensiones reales, enemigos o agentes dentro del plano, fondos insuficientes y terreno ocupado. El servidor decide y cobra una vez.
- Se puede construir en el territorio propio de radio 18, ampliable a 36; el agente debe estar en su base o a menos de seis unidades de su límite. Ya no es necesario caminar junto a cada pieza al usar el catálogo. Máximo 80 estructuras por comunidad.
- Los corredores públicos y las zonas de historia siguen reservados. Los portones se construyen fuera de esos corredores, como parte de las defensas propias.
- **E** apuntando a una estación la usa; sin apuntar a una se intenta la más cercana. Alcance 4,5. **F** repara la estructura cercana; **X** desmonta y devuelve la mitad del coste. **T** guarda materiales en el almacén cercano o, si no hay, en la bóveda. No hay control de unidades obreras ni colas de construcción todavía.

| Tecla | Estructura | Coste | PV | Función |
|---|---|---:|---:|---|
| 1 | Muro | 20 | 180 | Barrera modular |
| 2 | Portón | 30 | 240 | E abre/cierra; abierto pasan personas, zombis y disparos. No puede cerrarse sobre ellos |
| 3 | Pinchos | 15 | 90 | Transitables, infligen 18 de daño/s a infectados; pierden 5 PV por activación y dejan botín al matar |
| 4 | Taller | 60 | 300 | E fabrica 30 balas por 15 materiales; C cerca tiene la misma mejora, fuera fabrica 18 |
| 5 | Enfermería | 50 | 260 | E recupera hasta 35 PV por 10 materiales; no cobra si estás a plena salud |
| 6 | Pozo | 40 | 300 | Agua cada 30 s, hasta cinco usos; E recupera 40 de hidratación |
| 7 | Huerto | 45 | 160 | Comida cada 60 s, hasta cinco usos; E recupera 35 de alimento |
| 8 | Almacén | 35 | 280 | T deposita 20 materiales; E retira hasta 20; compartido entre aliados |

Todos los edificios pertenecen a su comunidad. Las estructuras sólidas participan en la navegación y los disparos; pueden ser atacadas y destruidas. Al desmontar un almacén, sus materiales se dejan en el suelo, una sola vez. Si es destruido en combate se pierde su contenido. Los portones no son invulnerables. Reparar cuesta 10 y recupera hasta 65 PV según el máximo de cada tipo.

## Supervivencia

Alimento e hidratación empiezan en 100. Bajan solo estando vivo y conectado, a 0,04 y 0,07 puntos por segundo (aproximadamente 42 y 24 minutos desde lleno). Si alguno llega a cero, se pierden 2 PV/s; puede causar muerte. Al reaparecer se recuperan a 70. El pozo/huerto producen desde su construcción; no entregan usos gratis al construir, y el tiempo offline produce hasta su límite de cinco. El taller, la enfermería y el almacén gastan o transfieren recursos reales.

Materiales y balas siguen obteniéndose de suministros y zombis; no hay todavía minería, tala, electricidad, combustible, cadena de herramientas ni automatización de trabajadores. Es una base funcional ampliable, no todos los sistemas posibles de un apocalipsis zombi.

## Persistencia y compatibilidad

Guardado v5. Abrir v4 crea `world.json.v4.bak` exacto antes de migrar. Conserva identidades, mundos, estructuras, materiales y fechas. Muros existentes se identifican como `wall`; necesidades inicializadas en 100; recargas negativas normalizadas. Las nuevas estructuras mantienen tipo, resistencia, rotación, estado abierto, existencias y fecha de producción. El catálogo del servidor es la fuente de costes y tamaños y llega en las instantáneas.

El cliente web conserva su colocación de muro y recibe la corrección de recarga; ahora representa los tipos nuevos y portones abiertos, y muestra comida/agua. El catálogo RTS completo está en Godot. La aplicación cliente debe reiniciarse después de actualizar scripts; un servidor antiguo no dispone del catálogo nuevo.

## Verificación

- `npm run check`: correcto.
- `npm test`: 40/40 aprobadas. Nueve nuevas pruebas: diez recargas seguidas más reserva parcial, ocho costes y mensajes inválidos, encaje y territorio, portones/ocupación/propiedad, taller/enfermería/almacén, comida/agua, desgaste y botín único de trampas, hambre/sed y migración v4→v5 con lectura posterior.
- `node tools/verify-godot.mjs RUTA_GODOT --capture`: Godot 4.5.1, cero fallos. Dos clientes nativos, cuatro recargas consecutivas, catálogo de ocho, muro+portón contiguos, pozo, daño, reconexión y lectura de tres estructuras guardadas. Captura de la cuadrícula y catálogo revisada. No equivale a una partida humana prolongada ni certifica balance.
- Correcciones durante la integración: tipo explícito de booleano en GDScript y conversión de versión JSON a entero antes de comprobar compatibilidad 4/5.

## Archivos

Nuevos: src/structures.mjs, test/structures.test.mjs, godot/building/view.gd, este documento. Modificados: src/world.mjs, src/navigation.mjs, src/storage.mjs, server.mjs, package.json, test/expansion.test.mjs, test/protocol.test.mjs, godot/building/placement.gd, godot/world/main.gd, godot/ui/hud.gd, godot/network/client.gd, godot/tests/native_smoke.gd, tools/verify-godot.mjs, public/game.js, public/index.html y docs/godot-preview.png. README.md y godot/README.md enlazan estas instrucciones.

Siguiente paso de mecánicas: balancear una sesión de defensa real y ampliar selección/gestión de edificios, abastecimiento renovable y construcción de filas. Se mantiene la prioridad de jugabilidad sobre mejoras gráficas.
