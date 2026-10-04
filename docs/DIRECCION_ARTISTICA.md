# Referencia visual aprobada — El Cerco

La imagen aportada por el usuario es el objetivo aproximado de calidad: 3D estilizado occidental, proporciones humanas, cámara elevada oblicua, fortificaciones de madera/piedra, terreno orgánico con vegetación abundante, estructuras reconocibles, iluminación cálida y núcleo mágico azul. El prototipo anterior de cubos no representa el acabado esperado.

## Primera pasada implementada

- Shader de suelo en coordenadas del mundo: manchas de hierba/tierra, ruido a distintas escalas, senderos irregulares y tonos por región.
- Hierba agrupada en MultiMesh para reducir llamadas de dibujo; arbustos y copas con volúmenes facetados.
- Muros de tablones, travesaños, refuerzos de piedra y diagonal; pilares con luminarias. Se conserva el acceso central abierto: no se dibuja una puerta cerrada donde la autoridad permite pasar.
- Bóveda de piedra con cristal cian y soportes metálicos; cajas reforzadas, vehículo averiado y mampostería en obstáculos.
- Agente con proporciones menos cúbicas, casco, chaleco, mochila, bolsas y botas; infectados con ropa y silueta diferenciada. Se mantienen las animaciones nativas.
- Cámara oblicua y movimiento WASD transformado según su orientación. Luz solar cálida y sombras.

Modelos y materiales generados dentro de Godot, no modelos de Blender ni assets comerciales. La referencia no se pegó como fondo ni se usó como captura del juego. docs/godot-preview.png proviene del motor renderizando la prueba real.

## Diferencia respecto al objetivo

Esta pasada establece la dirección y mejora el prototipo, pero **todavía no alcanza el detalle de la referencia**. Faltan modelos esculpidos con texturas trabajadas, manos/rostros y animaciones esqueléticas naturales, follaje con mejor distribución y variedad, torres/refugios/ruinas elaborados, piedras y bordes de caminos diseñados a mano, materiales con desgaste y una composición de base completa. Se necesita también medir rendimiento con esta densidad visual; la prueba breve no certifica FPS ni 40 clientes 3D.

Próximo paso artístico: terminar una zona de bosque y fachada de base como muestra de calidad, después aplicar ese estándar al resto del mapa. Añadir estructuras sólidas requiere introducir sus colisiones en la autoridad, evitando decoración que prometa una barrera inexistente.

## Validación

Godot 4.5.1 Compatibility: integración nativa con renderizado, dos clientes, apuntado, combate, construcción, persecución, daño, guardado y reconexión. La primera pasada pasó sin errores de scripts/shader y se revisó la captura. Los cambios se limitan al cliente y documentación; no se alteraron inventarios, reglas ni guardados de Node.

Archivos: nuevos godot/world/art.gd y ground.gdshader; modificados world/main.gd, world/main.tscn, camera/follow.gd, player/actor.gd y docs/godot-preview.png. Este documento conserva el objetivo visual para las siguientes entregas.
