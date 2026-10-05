# Funciones de las construcciones

Selecciona una estructura con clic derecho para ver su función, estado y acciones. Acércate a 4,5 m para usarla. E ejecuta su función principal; los muros y pinchos son pasivos. El servidor valida distancia, propiedad, existencias y costes. Los rechazos y éxitos muestran mensajes concretos.

| Edificio | Función jugable |
|---|---|
| Muro | Bloquea movimiento y disparos. Los infectados lo rodean o atacan. Reparación y mejoras aumentan la resistencia de la defensa. |
| Portón | Abre/cierra el paso. Cierre automático opcional a los cinco segundos; espera si hay alguien en el hueco. |
| Pinchos | Dañan infectados cada segundo y se desgastan: 18/24/30 de daño según nivel, 5 PV de desgaste por ataque. Respetan a infectados controlados. |
| Taller | Fabrica 30/36/42 balas por 15 materiales. También recupera 30/40/50 de blindaje por 25 materiales, máximo 100. |
| Enfermería | Cura 35/45/55 PV por 10 materiales, máximo 100. No cobra si la salud está completa. |
| Pozo | Produce agua y recupera 40 de hidratación por uso. Un pozo vivo acelera un 25 % los huertos aliados a 6 m. Varios pozos no acumulan el beneficio. |
| Huerto | Produce comida y recupera 35 de alimento por uso. La ficha muestra existencias y segundos hasta la siguiente producción. |
| Almacén | Comparte materiales y munición de reserva entre aliados: capacidad inicial 200 materiales y 120 balas, +100/+60 por mejora. Transferencias de hasta 20 materiales o 30 balas. |

Pozo y huerto conservan un máximo de cinco usos. La producción depende del nivel; con un pozo cercano, un huerto inicial produce cada 48 segundos. Los edificios destruidos no producen ni activan trampas. Al desmontar un almacén, materiales y munición caen como un único botín recuperable. La destrucción en combate pierde el contenido.

Persistencia v5: `ammoStock`, `autoClose` y `closeAt` son campos opcionales; partidas existentes funcionan con depósito de munición vacío y cierre manual. Las descripciones y temporizadores de `operation` se calculan en cada instantánea y no modifican el guardado.

Verificación: 49 pruebas Node aprobadas y prueba de integración Godot sin fallos. Se verificaron límites de blindaje y costes, cierre sin aplastar ocupantes, capacidad y conservación de depósitos, botín único, riego aliado y protección de infectados controlados. Reinicia el servidor y el cliente para activar los cambios.
