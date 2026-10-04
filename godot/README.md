# El Cerco — cliente Godot

## Actualización 0.8

**Mayús + arrastrar** en construcción: fila de muros, portones o pinchos con coste total y vista previa. Soltar confirma; clic derecho cancela. **Clic derecho** sobre un edificio abre gestión con estado, uso, reparación, mejora y desmontaje. **V** junto a una ruina obtiene materiales y balas cada dos minutos. [Detalle de reglas y pruebas](../docs/MECANICAS_08.md).

Los scripts también están actualizados en `el-cerco-3d-(4.5)/`, conservando su nombre de proyecto y perfil. Reinicia el cliente. La integración 0.8 verifica cinco estructuras, filas, mejoras y persistencia.

## Actualización de mecánicas 0.7

**B** abre construcción RTS; **1–8** elige estructura, **WASD** mueve la cámara, **G** gira, clic coloca con encaje automático, **Escape/B** vuelve a supervivencia. El mundo no se pausa. **E**, apuntando a una estructura cercana, la utiliza. **T** deposita materiales; **F/X** reparan/desmontan. Recarga corregida y alimento/agua visibles. Consulta [funciones y costes de las ocho estructuras](../docs/MECANICAS_07.md).

Reinicia el cliente para cargar esta versión. El servidor de entrenamiento usa guardado v5 y conserva una copia exacta `.v4.bak` al migrar tus partidas. La prueba nativa actual verifica cuatro recargas y tres estructuras con reconexión; los detalles anteriores del documento describen el primer corte de migración.

Verificado con **Godot 4.5.1 estable, edición estándar**, renderizador Compatibility/OpenGL. No usa C# ni requiere Blender. El servidor sigue siendo Node.js >=22; los archivos .mjs no se cargan como scripts Godot.

## Windows 10: abrir y jugar

1. Desde la carpeta raíz CityZ abre PowerShell y ejecuta:

   ```powershell
   node tools/start-godot.mjs
   ```

   Escucha en 127.0.0.1:3002 y usa exclusivamente `data-godot/`. La primera inscripción en su primer mundo añade tres infectados y cuatro muros con paso central. Las siguientes oleadas usan las reglas existentes. No borra ni modifica `data/` o `data-demostracion/`.

2. Abre Godot 4.5.1 → **Importar** → selecciona `godot/project.godot` → **Importar y editar**. Presiona **F6** con `world/main.tscn` abierto, o **F5** para iniciar el proyecto.
3. Pulsa **Entrar**. WASD mueve; apunta al terreno con el ratón y mantén clic para disparar. R recarga. B activa el muro, G lo gira y clic solicita colocarlo. Verde indica colocación prevista válida; el servidor confirma el gasto. E interactúa/recoge; F repara; X desmonta; C fabrica; U amplía territorio; T deposita; J abre el diario; 2–7 lanzan poderes aprendidos. Escape cierra diario/cancela construcción.
4. **Partidas** desconecta sin liberar la plaza. **Reconectar** usa el mismo agente. Si el servidor se detiene, reinícialo y pulsa Reconectar. El cliente no crea una identidad nueva al fallar una conexión.

La copia portátil descargada para esta verificación está en `.tools/godot-4.5.1/` (ignorada por Git). También puedes usar la [distribución oficial](https://github.com/godotengine/godot-builds/releases/tag/4.5.1-stable). No se instaló un motor global.

## Dos ventanas independientes

Con el servidor iniciado, desde CityZ:

```powershell
$godotExe = '.\.tools\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe'
& $godotExe --path godot -- --profile=agente1 --port=3002
```

En otra PowerShell:

```powershell
$godotExe = '.\.tools\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe'
& $godotExe --path godot -- --profile=agente2 --port=3002
```

Selecciona el mismo mundo y comunidad en ambas. Cada perfil guarda claves por mundo en `user://identity_PUERTO_PERFIL.json` (carpeta de datos de usuario de Godot). Dos procesos con el mismo perfil comparten identidad y reemplazan la conexión anterior. Para conectar a tu servidor habitual usa `--port=3000` después de reiniciarlo con el código actual; el endpoint de protocolo es nuevo.

## Comprobaciones reproducibles

```powershell
npm run check
npm test
& $godotExe --headless --path godot --editor --import --quit
node tools/verify-godot.mjs $godotExe
node tools/verify-godot.mjs $godotExe --capture
```

La integración crea un servidor temporal aislado y dos instancias del cliente nativo dentro de un proceso Godot. Prueba la escena real, posiciones, tres zombis, disparo/daño, recarga, muro/coste, rechazo de secuencia repetida, desconexión, identidad y lectura posterior del guardado. Con `--capture` usa renderizado real y guarda `docs/godot-preview.png`. El servidor temporal se cierra y limpia al terminar. No sustituye una sesión manual de dos ventanas, ni prueba 40 jugadores 3D.

## Escenas y sustitución de modelos

- `world/main.tscn`: escena principal con cámara, iluminación, mundo, red y HUD.
- `player/player.tscn`, `zombies/zombie.tscn`: modelos montados con mallas nativas. `player/actor.gd` genera AnimationPlayer para quieto, correr, apuntar, disparar, recibir daño y atacar.
- `world/shapes.gd`: materiales, mallas y colisiones estáticas; no son assets de Blender.
- `combat/presentation.tres`: intervalo visual de disparo/entrada y dimensiones de muro. El balance y la validación siguen en Node.
- `building/placement.gd`: predicción visual de validez; no cobra recursos.
- `network/client.gd`: HTTP, SSE, claves, secuencias y reconexión explícita.

El personaje no integra física local: interpola la posición que el servidor ya resolvió contra geometría. Así no atraviesa muros para otros jugadores ni decide su propio daño. La interpolación suaviza la imagen; aún no hay predicción de movimiento para conexiones lentas. Radio, magos y árboles son decorativos sin colisión, igual que en la base web.

Incluye minimapa (bases, aliados, rivales e infectados visibles y señales desbloqueadas), reloj de asedio, maná y recargas, pulsos de magia, escudo visible, control de infectados y disparo sintetizado. Los puntos del minimapa respetan la información filtrada por el servidor. El sonido provisional usa PCM generado en Godot, sin assets externos.

Consulta `../docs/MIGRACION_GODOT.md` para inventario, resultados y límites de paridad. **No es una migración terminada**: faltan aceptación manual completa, recorrido nativo de los seis poderes, audio y animaciones finales, y mapa/arte elaborados.
