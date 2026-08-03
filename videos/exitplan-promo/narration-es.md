# Narración ES — guion para ElevenLabs v3

Guion de locución para `renders/video-es.mp4` (29.5s, 1080x1920).
No es un `SCRIPT.md` a propósito: ese nombre activa el pipeline de TTS de HyperFrames
y aquí el audio se genera fuera y se monta a mano.

## Cortes de escena (timeline final)

| # | Escena        | Entra  | Sale   | Dura | Habla ~ |
| - | ------------- | ------ | ------ | ---- | ------- |
| 1 | hook          | 0.0s   | 4.0s   | 4.0s | 3.1s    |
| 2 | 47 sonidos    | 4.0s   | 8.5s   | 4.5s | 3.8s    |
| 3 | mecha         | 8.5s   | 13.0s  | 4.5s | 3.4s    |
| 4 | llamada       | 13.0s  | 18.5s  | 5.5s | 4.0s    |
| 5 | privacidad    | 18.5s  | 24.0s  | 5.5s | 4.2s    |
| 6 | cierre / CTA  | 24.0s  | 29.5s  | 5.5s | 3.4s    |

Total hablado ≈ 22s sobre 29.5s. El hueco restante es deliberado: las escenas 3, 4 y 6
tienen beats sostenidos (pantalla en negro, la llamada entrando, el lockup) que se leen
mejor sin voz encima.

## Guion

Los subtítulos ya están quemados en el vídeo, así que la voz **no los repite** —
los complementa. Donde el rótulo dice el titular, la voz explica el mecanismo.

### Bloque único (recomendado)

```
Cuando necesitas irte... y no tienes excusa.

Esto es ExitPlan. Cuarenta y siete sonidos reales.

Eliges uno, pones el tiempo... [whispers] y guardas el móvil.

Diez segundos después... te llaman. Con nombre, foto y todo.

Nada sale de tu teléfono. Sin cuenta, sin registros, sin nada.

ExitPlan. Tu excusa, siempre a mano. En Google Play.
```

### Por escena (si prefieres generar seis clips)

| # | Texto |
| - | ----- |
| 1 | `Cuando necesitas irte... y no tienes excusa.` |
| 2 | `Esto es ExitPlan. Cuarenta y siete sonidos reales.` |
| 3 | `Eliges uno, pones el tiempo... [whispers] y guardas el móvil.` |
| 4 | `Diez segundos después... te llaman. Con nombre, foto y todo.` |
| 5 | `Nada sale de tu teléfono. Sin cuenta, sin registros, sin nada.` |
| 6 | `ExitPlan. Tu excusa, siempre a mano. En Google Play.` |

## Ajustes en ElevenLabs

- **Modelo:** Eleven v3
- **Stability:** Natural. (Creative sobreactúa el tono seco; Robust ignora las etiquetas.)
- **Voz:** femenina joven, español neutro o de España, registro conversacional —
  el público objetivo son adultos de 25 a 34 con ligero sesgo femenino.
- **Etiquetas:** solo hay una, `[whispers]` en la escena 3, donde el gesto es
  cómplice — es el momento "te enseño un truco". Si la voz sobreactúa, quítala.

## Notas de producción

- **Los números van escritos en letra** (`cuarenta y siete`, `diez`) para que no los
  lea como cifra suelta ni cambie de idioma.
- **`ExitPlan`** puede salir con acento inglés. Si no te convence, escríbelo
  `Éxitplan` en el prompt: fuerza la lectura castellana.
- **Genera el bloque único de una vez** aunque luego lo cortes. v3 mantiene mucho mejor
  el tono y el timbre en una sola pasada que en seis generaciones sueltas; con menos
  de ~250 caracteres tiende a volverse inestable.
- **Al cortar,** deja el inicio de cada frase alineado con la entrada de su escena
  (columna "Entra"), no comprimido contra el corte anterior.

## Para montarlo

Deja el archivo en `assets/audio/` y añade en `index.html`, como hijo directo del div
raíz, un elemento `audio` con `id="el-narration"`, el `src` al archivo,
`data-start="0"`, `data-duration` con la duración real, `data-track-index="10"` y
`data-volume="1"`. Después `npm run render`.
