# Mecánicas 0.8 — construcción y abastecimiento

## Construcción de filas

En modo B, elige muro, portón o pinchos. Mantén Mayús y arrastra con clic izquierdo. La fila sigue el eje horizontal o vertical dominante y gira las piezas automáticamente. Separación de centros: 3,2 unidades, bordes unidos. Hasta 20 piezas por envío, dentro del límite de 80 estructuras de la comunidad.

La vista previa indica cantidad, coste total y obstáculos. Soltar fuera de la interfaz solicita construcción; clic derecho, Escape, cambiar plano o salir del modo cancela. El servidor calcula todas las piezas y valida fondos, territorio, ocupación y solapamiento antes de cobrar. Si falla alguna, rechaza la fila entera. La vista previa es orientativa: un agente puede ocupar el lugar antes de confirmar.

## Gestión de edificios

Clic derecho sobre un edificio aliado abre su ficha: nivel, vida, existencias y botones de uso, reparación, mejora y desmontaje. Acércate a 5 unidades para reparar/mejorar, menos de 5 para desmontar y hasta 4,5 para usar. Los botones inhabilitados indican falta de alcance, materiales o nivel máximo.

Todos comienzan en nivel 1; dos mejoras alcanzan nivel 3. La primera cuesta el coste original y la segunda el doble. Cada mejora añade 50 % de la vida base a la vida actual y máxima. No repara gratis el daño previo. Reparación: 10 materiales por hasta 65 PV. Desmontaje devuelve la mitad del coste base, sin reembolsar mejoras.

Beneficios adicionales por mejora:

- Taller: +6 balas por fabricación; nivel 3 entrega 42 por 15 materiales, tanto con E como con C.
- Enfermería: +10 PV por uso; nivel 3 cura hasta 55 por 10 materiales, sin superar 100 PV.
- Pozo y huerto: velocidad de producción +25 % por mejora; nivel 3 produce cada 20/40 segundos. Mantienen el tope de cinco usos.
- Muros, portones, pinchos y almacenes: resistencia adicional.

## Abastecimiento renovable

Acércate al borde de una ruina a menos de tres unidades y pulsa V: +25 materiales y +6 balas. La disponibilidad se comparte entre todos los jugadores, con espera de 120 segundos. El HUD indica cuándo vuelve a estar disponible. Las rocas no producen recursos. Esto permite abastecerse fuera de la base sin depender exclusivamente del botín de infectados.

## Compatibilidad

Formato v5 conservado: `level` en estructuras y `scavengeAfter` en ruinas son campos opcionales persistidos; ausencia significa nivel inicial y ruina disponible. No se reinician mundos, identidades ni inventarios. El cliente antiguo `el-cerco-3d-(4.5)/` solo aceptaba v4: se actualiza para recibir v5 y las nuevas mecánicas. Se conserva su `project.godot`; los archivos sustituidos tienen respaldo en `.tools/backups/`.

## Verificación

- 45 pruebas Node aprobadas: incluyen recarga, filas conectadas horizontales y verticales, rechazo atómico, secuencias repetidas, mejoras, alcance, propiedad, producción, espera compartida y persistencia.
- Integración Godot 4.5.1 con dos clientes dentro de un proceso: filas y mejoras compartidas, ficha actualizada, vista previa, cancelación, cuatro recargas, daño, reconexión y lectura posterior de cinco estructuras con mejora conservada. Cero fallos. Captura real revisada en `godot-preview.png`.
- Estas pruebas no sustituyen una sesión humana prolongada de balance.

## Pendientes del proyecto completo

Quedan el desenlace con Paciente 0 y cura, recompensas por cuenta, rutas y puntos de interés adicionales, almacenamiento transaccional y aceptación de sesiones prolongadas. Electricidad, combustible, tala, minería y trabajadores automáticos aún no están implementados. La prioridad sigue siendo completar y equilibrar la supervivencia antes de otra mejora gráfica.
