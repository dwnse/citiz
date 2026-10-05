# Plan de implementación

Cada etapa debe conservar un arranque reproducible. No se declara cumplida una aceptación sin evidencia en PRUEBAS.md.

| Etapa | Dependencia | Aceptación observable | Estado |
|---|---|---|---|
| 1. Prototipo | Node y navegador | Entrar, mover, apuntar, disparar a infectado; levantar muro y defender bóveda; controles visibles | Implementada; revisión visual parcial y pruebas de reglas aprobadas |
| 2. Cooperativo | 1 | Dos clientes ven mismo mundo; servidor mueve, valida combate y cobra construcción; desconexión detiene intención; reconexión recupera identidad | Integración aprobada y dos clientes gráficos verificados: muro compartido, plaza conservada y reconexión |
| 3. Supervivencia | 2 | Recoger, fabricar, reparar, oleadas 1–3 con jefe; cerrar/reiniciar conserva estado; muerte con y sin núcleo | Implementada; pruebas automáticas aprobadas; balance y partida manual completa pendientes |
| 4. Mundo | 3 verificada manualmente | Cuatro regiones y comunidades, inscripción 40 persistente, radio hasta ×2, directorio local, asedio configurable, eliminación y carga gradual 2/10/20/40 | Base funcional implementada y probada; territorios provisionales, túneles/POI y partida humana de asedio pendientes |
| 5. Historia | 4 | Introducción jugable desarrollada, seis magos alcanzables con pistas y movilidad segura, seis poderes validados por servidor, misión de apertura | Base funcional 0.6 implementada, 30 pruebas aprobadas; desarrollo audiovisual y recorrido manual completo pendientes |
| 6. Desenlace | 5 | Fases persistentes, Paciente 0, única comunidad + verdad + cura, cierre por fecha y premios idempotentes por cuenta | Base funcional 0.12: jefe, cura, victoria condicionada, expiración y recompensa única; pruebas automáticas aprobadas. Balance del mes, tienda y campaña humana pendientes |

## Estado actual: 0.14

Implementados trabajadores físicos con transporte, señales temporales, patios abiertos, colectores y tienda de insignias. 91 pruebas aprobadas. La siguiente aceptación es una partida humana completa y una prueba prolongada combinando población, hordas y red. Ver MUNDO_VIVO_014.md para los límites de los interiores, arte, IA de peatones y campaña.

## Historial de incrementos

Incremento 0.13 añade jefes variables, gestión de población, raciones y prioridad de puestos, con pruebas aprobadas; ver HORDAS_COMUNIDAD_013.md.

Incremento 0.12 implementado: supervivencia, expediciones, población, investigación y desenlace funcional. Detalles y límites en SUPERVIVENCIA_012.md. Siguiente aceptación: partida humana completa hasta la cura, incluyendo asedio, muerte del portador de muestra y reconexión. Arte final, trabajadores visibles, más contenido de campaña y tienda cosmética siguen pendientes.

1. Dos clientes gráficos y construcción compartida verificados; completar defensa coordinada y registrar percepción del control.
2. Obstáculos y búsqueda por cuadrícula implementados y probados; ampliar pruebas con laberintos de jugadores y congestión.
3. Directorio, cuatro comunidades y cupo 40 implementados; carga gradual ejecutada en loopback. Optimizar tráfico y probar sesiones prolongadas y red externa.
4. Asedio, permisos, robo y eliminación implementados con reglas reversibles. Completar prueba humana de guerra y resolver balance de defensa offline. Diseñar POI, túneles y rutas alternativas de las cuatro regiones.
5. Llevar inventarios y eventos a almacenamiento transaccional con migración de v1 y prueba de caída entre escritura y confirmación.

## Pruebas futuras obligatorias

Desconectar sin liberar plazas, ingreso simultáneo en última plaza, no morir dentro de geometría, acceso continuo al núcleo, robo bajo asedio válido, comunidad sin núcleo y miembros offline, jefe muerto antes/después del cierre, caída entre pago y confirmación, recompensa duplicada, migración y recuperación del estado. No dar por superadas estas pruebas por existir en este documento.
