# Hacha-pico y recolección

Todos los agentes pueden alternar entre pistola y hacha-pico con **Q** o con el botón inferior. La herramienta aparece en la mano y se anima al golpear. Al equiparla se muestran los árboles y rocas cercanos con sus golpes restantes. Acércate a menos de 3,2 m, apunta a la base del recurso y mantén clic izquierdo. Q vuelve a la pistola.

- Árbol: cinco golpes, seis materiales por golpe; total 30. Se regenera a los tres minutos.
- Roca: cinco golpes, ocho materiales por golpe; total 40. Se regenera a los cuatro minutos.
- Cada golpe tarda al menos 0,8 segundos. No consume balas. La herramienta sirve para recolectar; el combate sigue usando la pistola.
- La madera y piedra obtenidas se incorporan al contador existente de materiales de construcción; sirven para construir, reparar, mejorar y fabricar.
- Todos comparten los mismos recursos: el último golpe agota el árbol o roca para todos. No se permite recolectar a distancia ni atravesando muros o edificios. El agotamiento se representa reduciendo el recurso a un tocón o resto bajo.
- Los recursos sólidos bloquean el movimiento mientras están disponibles. No se puede construir encima sin extraerlos. Su regeneración espera si hay jugadores, zombis o estructuras en el punto.

El servidor añade los recursos de forma determinista alrededor de las comunidades cuando una partida aún no tiene `resources`. La lista, golpes restantes, fecha de recuperación, equipo y contador de golpes se conservan en el guardado v5 como campos opcionales. Se aplica también a partidas existentes. Las rocas grandes del escenario que funcionan como obstáculos y edificios en ruinas conservan su función anterior; los recursos recolectables llevan indicación al equipar la herramienta.

Verificación: 52 pruebas Node aprobadas, incluidas extracción de ambos tipos, costes, cadencia, agotamiento compartido, distancia, obstáculos y persistencia. Integración Godot con equipamiento compartido, representación de herramienta y cosecha sincronizada. Reinicia servidor y juego para cargar los cambios.
