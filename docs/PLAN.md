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

## Estado actual: arte 021 — Fase 1, personajes

Agente y zombi común con modelos GLB y esqueleto, capas de animación, recarga,
daño y muerte conectadas al servidor. Pruebas aprobadas en ambos proyectos;
ver [ARTE_FASE_1.md](ARTE_FASE_1.md). Se espera aprobación humana para la fase 2
de arte: resistente, bóveda y tres piezas de base. La fase 3 de arte abordará
zona de muestra, materiales, iluminación e interfaz.

## Base funcional: 0.20 — Fase 4, equilibrio

Ajustes de oleadas y botín, mejoras productivas y previsión de raciones. Ver EQUILIBRIO_020.md y BALANCE_020.json. 118 pruebas aprobadas en esa entrega; auditoría teórica, sin certificación de campaña humana. El trabajo visual continúa ahora por las fases descritas arriba.

## Incremento 0.19 — Fase 3, mundo y campaña

Interiores de hospitales/laboratorios y encuentros con combate, presencia y recogida de informe. Amenaza ligada a las fases del mes y migración conservadora. Ver MUNDO_CAMPANA_019.md. Fase 4 autorizada posteriormente. Arte definitivo, relieve, narrativa ramificada y pruebas humanas prolongadas siguen pendientes.

## Incremento 0.18 — Fase 2, gestión RTS

Órdenes individuales desde Comunidad, separación al caminar y renovación de rutas bloqueadas. Ver RTS_018.md. Fase 3 autorizada posteriormente por el usuario. Las pruebas largas y congestión en bases grandes siguen pendientes.

## Incremento 0.17 — Fase 1, estabilidad y controles

Reconexión automática limitada, cancelación al salir, sustitución de sesión sin bucles, intención de parada conservada y control del foco. Ver ESTABILIDAD_017.md. El usuario autorizó posteriormente la fase 2. Las sesiones largas, red externa y aceptación humana siguen pendientes.

## Incremento 0.16

Replicación incremental con reconstrucción verificada, bases completas periódicas y envíos repartidos. Ver RED_INCREMENTAL_016.md. Continúan pendientes sesiones de horas, red externa, aceptación humana y contenido/artes definitivos.

## Incremento 0.15

Galerías recorribles en vista sin techo, ventilación y suministros compartidos implementados. 96 pruebas aprobadas. Sigue pendiente la aceptación humana del ciclo completo y la validación durante horas en red externa. Ver COLECTORES_015.md.

## Incremento 0.14

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
