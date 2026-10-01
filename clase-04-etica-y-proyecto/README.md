# Clase 4 — Integración, ética y aplicación a casos propios

**Duración:** 2 horas
**Objetivo:** que te vayas con tres cosas: criterio para decidir qué se puede recolectar,
un lugar donde guardar el corpus, y el esqueleto de tu propio proyecto andando.

> Requisito: haber corrido los scripts de las clases 2 y 3. El script 2 de hoy lee los CSV
> que aquellos dejaron.

---

## De qué se trata esta clase

Las tres primeras clases fueron sobre **cómo**. Esta es sobre **cuándo, hasta dónde y para qué**.

Y no porque lo técnico se termine: porque el límite del scraping casi nunca es técnico.
Cuando un sitio te dice que no, el problema deja de resolverse con código.

---

## Guion del encuentro

| Bloque | Min | Qué hacemos |
|---|---|---|
| **A** | 30 | Ética y legalidad. Las dudas que trajeron de tarea. Los tres planos: técnico, contractual, legal. |
| **B** | 20 | Cortesía técnica y diagnóstico. Leer un 403, un 429, un CAPTCHA. → `01-cortesia-y-diagnostico.R` |
| **C** | 20 | De CSV a SQLite: cuando el corpus crece. → `02-guardar-en-sqlite.R` |
| **D** | 20 | Pipelines reproducibles y mantenimiento. → `03-pipeline-reproducible.R` |
| **E** | 30 | **Presentación de casos propios** y cierre. |

### Bloque A — Público no quiere decir libre

Tres planos que se confunden todo el tiempo, y que pueden decir cosas distintas:

| Plano | Qué regula | Quién decide |
|---|---|---|
| **Técnico** | Si podés acceder | El servidor (200, 403, 429) |
| **Contractual** | Si te dejan | Los términos de uso |
| **Legal** | Si corresponde | La ley (Ley 25.326, propiedad intelectual) |

Un sitio puede dejarte pasar, prohibirlo en sus términos y contener datos que la ley protege.
Los tres importan, y el primero es el que menos dice.

Trabajamos sobre [`recursos/checklist-etico-legal.md`](recursos/checklist-etico-legal.md),
con los casos concretos del curso: `computrabajo` (403 duro), `zonajobs` (sitemaps abiertos),
`archivopolitico` (permite las páginas, protege su base) y las redes sociales.

---

## Scripts

| Archivo | Qué enseña | Internet |
|---|---|---|
| `01-cortesia-y-diagnostico.R` | Identidad, pausas, reintentos, caché. Traducir códigos de estado. | sí |
| `02-guardar-en-sqlite.R` | Del CSV a una base. Consultar sin cargar todo. Deduplicar. | no |
| `03-pipeline-reproducible.R` | El script que corrés todos los días y deja rastro. | sí |

Los tres usan [`../comun/R/funciones-cortesia.R`](../comun/R/funciones-cortesia.R),
donde vive la función `descargar()`. Abrila y leela: son cuarenta líneas y resumen
buena parte del curso.

---

## Las cuatro ideas de la clase

### 1. Un bloqueo es un mensaje, no un obstáculo

`computrabajo.com` devuelve **403 hasta para su propio `robots.txt`**. No falta un
`User-Agent` ni sobra velocidad: no atiende programas automáticos, y está en su derecho.

`zonajobs.com.ar` responde 200 y encima **publica cinco sitemaps XML**: listados de URLs
que el sitio ofrece para que los recorran.

Mismo rubro, mismo dato, decisión opuesta. **Elegir bien la fuente es parte del método.**

Este curso no enseña a forzar la primera puerta. Enseña a encontrar la segunda —
y cuando no hay segunda, a pedirla o a reformular la pregunta.

### 2. Cada pedido que no hacés es carga que no generás

La cortesía más importante no es la pausa: es el **caché**. Si ya bajaste una página, no la
vuelvas a pedir. `descargar()` guarda copia local y avisa `[cache]` cuando la usa.

Corré el script 1 dos veces seguidas y mirá la diferencia.

### 3. Guardá siempre la fecha de recolección y un id estable

Sin fecha, dentro de seis meses no vas a poder decir qué había en esa portada.
Con fecha, tu base deja de ser una foto y pasa a ser una serie temporal.

Sin un id estable, correr el scraper dos veces te duplica todo. Con id, la deduplicación
son dos líneas.

### 4. El sitio va a cambiar

No es una posibilidad: es cuestión de tiempo.

- **Síntoma:** el script corre sin error y devuelve 0 filas. Por eso el pipeline **imprime
  cuántas recolectó** — un cero salta a la vista, un error silencioso no.
- **Arreglo:** volvés al navegador, buscás el selector nuevo, lo cambiás en `CONFIG`.
- **Y lo anotás en la bitácora**, porque tu corpus tiene una costura ahí y hay que poder
  explicarla.

Los selectores viven en un solo lugar justamente para que arreglar sea cambiar una línea.

---

## Tu proyecto

En [`recursos/plantilla-proyecto-propio/`](recursos/plantilla-proyecto-propio/) hay un
esqueleto listo para copiar afuera del curso y usar con tu caso:

```
README.md                    qué recolectás, para qué, y el encuadre ético
R/00-configuracion.R         todo lo que puede cambiar, en un solo lugar
R/01-recolectar.R            baja y guarda copia local. No extrae nada.
R/02-limpiar.R               extrae de las copias locales. No sale a internet.
docs/bitacora.md             una entrada por cada cambio o problema
docs/notas-metodologicas.md  borrador del apartado de tu tesis o paper
```

**Por qué recolectar y limpiar están separados:** si te equivocaste en un selector,
corregís y volvés a extraer sin molestar al servidor de nuevo. Es la decisión de diseño
más útil de todo el curso.

---

## Presentación de casos (bloque E)

Tres minutos por persona. No hace falta que funcione: hace falta que esté pensado.

1. **Qué querés recolectar** y para qué pregunta de investigación.
2. **Qué fuente elegiste** y por qué esa y no otra.
3. **Con qué obstáculo chocaste** — técnico, ético o legal.
4. **Qué te falta** para resolverlo.

El punto 3 es el que más nos sirve a todos. Los obstáculos se repiten más de lo que parece.

---

## Después del curso

**Cosas que quedaron afuera y que quizás necesites**

| Necesidad | Por dónde seguir |
|---|---|
| El dato está en PDF | paquete `pdftools` |
| Documentos escaneados | OCR con `tesseract` |
| Un scraper educado sin escribirlo | paquete `polite` (envuelve rvest y respeta `robots.txt`) |
| Correrlo solo todos los días | `taskscheduleR` (Windows) o `cronR` (Mac/Linux) |
| Analizar el texto recolectado | `tidytext`, `quanteda`, `udpipe` |
| Compartir el corpus | Zenodo, o el repositorio institucional de tu universidad |

**Un consejo final**

El scraper más útil no es el más ingenioso: es el que sigue andando dentro de un año.
Simple, documentado, con la fuente y la fecha guardadas en cada registro.

Menos es más. También acá.

---

## Recursos

- [`recursos/checklist-etico-legal.md`](recursos/checklist-etico-legal.md) — diez preguntas antes de escribir el scraper
- [`recursos/plantilla-proyecto-propio/`](recursos/plantilla-proyecto-propio/) — esqueleto para tu caso
- [`../comun/R/funciones-cortesia.R`](../comun/R/funciones-cortesia.R) — `descargar()` y `diagnosticar()`
- [`../docs/preguntas-frecuentes.md`](../docs/preguntas-frecuentes.md)
- [`../docs/bibliografia.md`](../docs/bibliografia.md)
