# Clase 3 — Scraping iterativo, APIs y contenido dinámico

**Duración:** 2 horas
**Objetivo:** escalar de una página a muchas, y aprender a reconocer cuándo el scraping
**no** es el mejor camino.

> Requisito: haber corrido los scripts de las clases 1 y 2.

---

## La clase más importante del curso

Hasta acá extrajimos de una página por vez. Eso alcanza para un ejercicio, no para una
investigación. Hoy pasamos a escala — y con la escala aparecen tres problemas nuevos:

1. **Cómo recorrer muchas páginas** sin escribir el mismo código cincuenta veces.
2. **Qué hacer cuando algo falla** en la página 37 de 50.
3. **Cómo saber cuándo parar** — porque un sitio que te bloquea te está diciendo algo.

Y la pregunta que atraviesa todo: **¿hace falta scrapear, o hay una puerta abierta?**

---

## Guion del encuentro

| Bloque | Min | Qué hacemos |
|---|---|---|
| **A** | 25 | Paginación. `purrr::map()`, `list_rbind()`, `possibly()`. El error que no parece error. → `01-paginacion-con-purrr.R` |
| **B** | 20 | `robots.txt`, cortesía, pausas y `User-Agent`. Lectura en vivo de dos portales de empleo. |
| **C** | 25 | APIs REST con httr2. El catálogo de datos abiertos del Estado. → `02-api-datos-abiertos.R` |
| **D** | 30 | Formularios POST: convenios colectivos del Ministerio de Trabajo. → `03-formulario-post-convenios.R` |
| **E** | 20 | Páginas armadas por JavaScript. Las tres salidas posibles. → `04-pagina-dinamica-chromote.R` |

### Bloque B — Lo que el sitio te está diciendo

Retomamos los dos portales de empleo de la clase 1, ahora para decidir qué hacer:

```r
library(httr2)

# computrabajo: 403 hasta para leer sus propias reglas.
request("https://ar.computrabajo.com/robots.txt") |>
  req_error(is_error = function(resp) FALSE) |>
  req_perform() |> resp_status()
#> 403

# zonajobs: 200, y además publica cinco sitemaps.
request("https://www.zonajobs.com.ar/robots.txt") |>
  req_perform() |> resp_body_string() |> cat()
```

El primero cerró la puerta. Insistir con más técnica es empujar una puerta cerrada:
frágil, caro y discutible.

El segundo dejó la puerta abierta **y encima puso un cartel**: sus sitemaps son un listado
de URLs que el propio sitio publica para que los programas las recorran.

Misma industria, mismo dato, dos respuestas. Elegir bien la fuente es parte del método,
no un detalle técnico.

**Este curso no enseña a forzar la primera puerta.** Enseña a encontrar la segunda.

---

## Scripts

| Archivo | Qué enseña | Fuente |
|---|---|---|
| `01-paginacion-con-purrr.R` | Iterar, unir, pausar, sobrevivir a un error. | quotes.toscrape.com |
| `02-api-datos-abiertos.R` | Consumir una API REST y convertir JSON en tabla. | datos.gob.ar (CKAN) |
| `03-formulario-post-convenios.R` | POST con campos ocultos, paginación y HTML mal formado. | convenios.trabajo.gob.ar |
| `04-pagina-dinamica-chromote.R` | Demostración: qué hacer cuando el HTML llega vacío. | quotes.toscrape.com/js |

---

## Las cuatro ideas de la clase

### 1. Resolvé una página antes de escribir el bucle

Si falla con una, va a fallar cincuenta veces con cincuenta. Y vas a tardar cincuenta veces
más en darte cuenta.

### 2. La ausencia de error no garantiza el dato

`quotes.toscrape.com/page/11/` responde **200 OK** y devuelve una página que dice
*"No quotes found!"*. No hay excepción, no hay aviso, no hay nada roto.

Si hubieras pedido `1:50` sin mirar, te traías 40 páginas vacías y ni te enterabas.
**La condición de corte la definís vos**, no el servidor.

### 3. Cuando hay API, se usa la API

No se rompe con los rediseños, es más rápida, y está permitida por definición.
Diez minutos buscando si existe te pueden ahorrar dos días de trabajo.

Y si no hay API, todavía queda algo mejor que scrapear: **escribirle al organismo y pedir
los datos**. Más de una vez te los mandan en CSV, más completos que los de la web.

### 4. El HTML real está roto

El buscador de convenios devuelve tablas anidadas donde deberían ser hermanas, porque tiene
etiquetas sin cerrar. rvest hace lo que puede con lo que le dan.

Eso no es un error tuyo. Es cómo es la web fuera de los tutoriales.
Lo importante es **detectarlo antes de confiar en el dato** — por eso el script 3 cuenta
las celdas de la primera fila y de la última, y compara.

---

## Antes de una recolección larga: calculá el costo

```
33 páginas × 2 segundos de pausa ≈ 1 minuto
1000 fichas × 2 segundos          ≈ 33 minutos
```

Hacé esta cuenta **siempre**, antes de apretar Enter. Sirve para dos cosas: saber si podés
esperar, y saber cuánta carga le estás poniendo a un servidor que no es tuyo.

Si el número te asusta, achicá la búsqueda. Casi nunca necesitás todo.

---

## Ejercicios

**Script 1**
1. Bajá la pausa de 1 segundo a 0.2. ¿Por qué conviene dejarla en 1 con un sitio real?
2. Agregá una columna con el número de página de origen.
3. Aplicá el patrón a books.toscrape.com (50 páginas).

**Script 2**
4. Cambiá `q = "empleo"` por un tema de tu investigación.
5. Agregá el formato del primer recurso de cada conjunto.
6. Calculá cuántas páginas harían falta para traer todos los resultados.

**Script 3**
7. Cambiá el año. ¿Cuántos documentos hay para 2020?
8. Filtrá solo convenios colectivos con `TipoDocumentoId = "1"`.
9. Bajá las 33 páginas de 2024 y guardá la base completa.

## Desafíos

**A.** El boletín del Ministerio de Seguridad bonaerense
(`https://boletin.mseg.gba.gov.ar/NrosAnteriores.aspx`) es ASP.NET y usa un campo oculto
`__VIEWSTATE` que cambia en cada pedido. No alcanza con mandar campos fijos: hay que **leer
el `__VIEWSTATE` de la respuesta anterior y devolverlo** en la siguiente. Mismo principio
que el script 3, un escalón más arriba.

**B.** Explorá `https://www.zonajobs.com.ar/sitemap_avisos_zj.xml` y extraé URLs de avisos.
Es XML, no HTML: `rvest::read_xml()` lo lee igual.

---

## Tarea para la clase 4

Traé, sobre tu propio caso:

1. La fuente elegida y **por qué esa y no otra**.
2. Cuántos registros calculás recolectar y cuánto tiempo estimás que tarda.
3. Qué dice su `robots.txt` y sus términos de uso.
4. **Una duda ética o legal concreta.** La clase 4 arranca con esas dudas.

---

## Recursos

- [`recursos/chuleta-httr2.md`](recursos/chuleta-httr2.md) — pedidos, POST, códigos de estado, cortesía
- [`../clase-02-rvest-estaticas/recursos/chuleta-stringr.md`](../clase-02-rvest-estaticas/recursos/chuleta-stringr.md)
- [`../docs/glosario.md`](../docs/glosario.md)
