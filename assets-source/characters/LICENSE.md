# Personajes de El Cerco — procedencia

Autor: **Quaternius**. Paquete: **Zombie Apocalypse Kit**, marzo de 2024.
Licencia: **CC0 1.0 Universal**, uso personal y comercial permitido.

- Página del autor y declaración de licencia: https://quaternius.com/packs/zombieapocalypsekit.html
- Publicación del autor: https://www.patreon.com/quaternius/posts/zombie-kit-60-100385247
- Licencia: https://creativecommons.org/publicdomain/zero/1.0/
- Carpeta oficial: https://drive.google.com/drive/folders/1mWP6sCHun7OUMHQeDNZLrXTteXlzWg_t

Comprobado el 5 de octubre de 2026. Drive devolvió «Quota exceeded» al descargar.
Se usó la copia pública del mismo paquete en `agentkaerf/FreeModels`, fijada al
commit `db3df04d1e4714298a09510b26fb6de6645138a2`. La licencia se comprobó en la
página del autor, no se dedujo del repositorio espejo. El License.txt del espejo
dice CC0 pero su encabezado menciona otro paquete; por eso se registra aquí la
declaración específica del autor para Zombie Apocalypse Kit.

| Archivo local | Archivo de origen |
|---|---|
| Sam.gltf | Characters/glTF/Characters_Sam_SingleWeapon.gltf |
| Zombie.gltf | Characters/glTF/Zombie_Basic.gltf |

Origen de los archivos: https://github.com/agentkaerf/FreeModels/tree/db3df04d1e4714298a09510b26fb6de6645138a2/Zombie%20Apocalypse%20Kit%20-%20March%202024

Los glTF conservan la geometría, texturas, esqueleto y animaciones del autor.
`tools/pack-characters.mjs` empaqueta sus buffers incrustados en GLB; no modela
personajes ni modifica su topología. Los GLB se encuentran en
`godot/assets/characters` y en `el-cerco-3d-(4.5)/assets/characters`.

Adaptaciones de El Cerco: escala ×1,5; orientación +Z a −Z; paleta mediante shader;
ajuste de agarre/tamaño de pistola; capas de torso/piernas; gesto esquelético de
recarga y retroceso; dirección de zancada; conexión con estados del servidor.
No se utilizó Blender y no se entrega un .blend de autoría propia.
