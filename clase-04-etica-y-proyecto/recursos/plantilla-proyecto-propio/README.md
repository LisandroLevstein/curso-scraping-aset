# [Nombre de tu proyecto]

Plantilla para tu propio caso de scraping. Copiá esta carpeta afuera del curso,
renombrala y completá lo que está entre corchetes.

## Qué recolecto y para qué

- **Pregunta de investigación:** [una oración, sin tecnicismos]
- **Fuente:** [URL exacta]
- **Qué es esa fuente:** [organismo, medio, plataforma]
- **Unidad de análisis:** [una nota, un aviso, un convenio, una publicación]
- **Período de recolección:** [desde / hasta]
- **Volumen estimado:** [cuántos registros]

## Encuadre ético y legal

Completado con `checklist-etico-legal.md` el [fecha].

- **robots.txt:** [qué dice sobre las rutas que necesito]
- **Términos de uso:** [permiten / prohíben / no dicen nada]
- **¿Hay datos personales?** [sí / no — cuáles]
- **¿Hay datos sensibles (art. 7, Ley 25.326)?** [sí / no]
- **Vía oficial descartada porque:** [no existe API / la API no tiene este campo / ...]
- **Carga estimada sobre el servidor:** [N pedidos x M segundos de pausa = tiempo total]

## Cómo correrlo

```r
# 1. Abrir el .Rproj
# 2. Instalar dependencias (una vez)
source("R/00-configuracion.R")

# 3. Recolectar
source("R/01-recolectar.R")

# 4. Limpiar y guardar
source("R/02-limpiar.R")
```

## Estructura

```
R/               scripts numerados, en orden de ejecución
datos/crudo/     páginas descargadas tal cual (no se editan nunca)
datos/salida/    lo que producen los scripts (se puede borrar y regenerar)
docs/            bitácora y notas metodológicas
```

## Bitácora

Ver `docs/bitacora.md`. Anotá ahí cada vez que el sitio cambie y tengas que
tocar un selector. Tu yo de dentro de seis meses te lo va a agradecer.
