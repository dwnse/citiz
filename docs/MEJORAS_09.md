# Interfaz, mapa y rendimiento — 0.9

Corrección de entrada: las dos partidas existentes habían terminado y el cliente permitía reconectar con un agente muerto sin posibilidad de reaparición, dejando el escenario sin personaje. Ahora la sala deshabilita partidas terminadas, indica cuándo crear una nueva y una reconexión que recibe derrota vuelve a la sala con explicación. La cámara se centra también al reconectar al mismo mundo. La muerte temporal muestra la cuenta atrás. Integración nativa verificada: personaje vivo visible, cámara centrada, entrada bloqueada a partidas terminadas y recuperación de la sala. Se creó `Supervivencia 0.9` en el servidor local para continuar; las partidas anteriores se conservan.

La construcción centra la cámara en la bóveda para mostrar el territorio disponible. B o el botón inferior abre/cierra el modo; WASD desplaza la cámara, rueda cambia el zoom, 1–8 elige edificio, G gira y clic coloca. Mayús y arrastrar coloca filas. El jugador debe estar cerca de su base, tener materiales y seguir vivo. Las carreteras, obstáculos, zonas de historia y edificios existentes siguen reservados.

La vista previa explica el motivo local de rechazo. El servidor devuelve el motivo concreto de construcción y el cliente muestra avisos de error o confirmación. Los botones de edificios indican el coste y resaltan si faltan materiales. La ficha se abre con clic derecho. La interfaz incorpora tarjetas de fondo oscuro, barras de vida/comida/agua, botón de construcción, avisos temporales y contador de FPS.

El mapa incorpora asfalto deteriorado, marcas viales, escombros bajos, señales con nombres de comunidades y ruinas con ventanas tapiadas, azoteas y rótulos de suministros. Los elementos añadidos respetan los espacios de juego existentes. Se mantiene el mapa y guardado del usuario.

Oleadas: intervalo de 95 a 35 segundos, con los límites existentes de población y comunidades conectadas. Los mundos nuevos mantienen 45 segundos de preparación inicial; el sembrado de entrenamiento espera 35 segundos. Un temporizador ya guardado se respeta hasta su próximo vencimiento.

Optimización: árboles, arbustos, rocas y cajas del terreno se agrupan por geometría en MultiMesh por sectores de 24 unidades. El cliente conserva botín, radio y magos entre instantáneas. Las piezas fantasma se regeneran solo al cambiar la fila o su validez. Se mantiene un límite de 144 FPS y se desactiva VSync; esto puede producir tearing en monitores sin refresco variable.

Medición local: Godot 4.5.1 Compatibility, RX 580 2048SP, 1280×720, dos clientes en un proceso, tres infectados y cinco estructuras. Muestra de cinco segundos: **144,07 FPS medios**, **6,995 ms de fotograma p95**, 542 llamadas de dibujo al tomar la muestra. Resultado bruto en `performance-09.json`. Es una muestra breve de esa escena; no demuestra 60 FPS sostenidos en batallas de 40 jugadores ni en otros equipos. No se obtuvo una medición equivalente anterior para calcular una mejora porcentual.

Verificación: 45 pruebas Node aprobadas e integración nativa con cero fallos. Incluye construcción compartida, filas, mejoras, recarga, daño, reconexión y guardado. Captura del renderizado revisada en `godot-preview.png`. Ambas carpetas de cliente reciben los mismos scripts; su configuración e identidades se conservan.
