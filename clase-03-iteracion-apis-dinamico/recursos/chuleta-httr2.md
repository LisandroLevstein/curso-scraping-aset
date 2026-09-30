# Chuleta de httr2

`rvest` sirve para leer HTML. `httr2` sirve para **controlar el pedido**: cabeceras,
formularios, parámetros, reintentos, pausas. Cuando `read_html()` no alcanza, es esto.

## La forma del pedido

Se arma por partes con el pipe, y no se manda hasta que llamás a `req_perform()`.

```r
library(httr2)

respuesta <- request("https://ejemplo.com/api") |>
  req_url_query(q = "empleo", rows = 20) |>
  req_user_agent("Mi investigación (mi.mail@universidad.edu.ar)") |>
  req_perform()
```

Esa separación importa: podés construir el pedido, mirarlo, guardarlo, reusarlo,
y recién ejecutarlo cuando estés seguro.

## Construir

| Función | Para qué |
|---|---|
| `request(url)` | empieza el pedido |
| `req_url_query(clave = valor)` | agrega parámetros a la URL (`?clave=valor`) |
| `req_url_path_append("ruta")` | agrega segmentos a la ruta |
| `req_user_agent("texto")` | dice quién sos |
| `req_headers(Accept = "application/json")` | agrega cabeceras |
| `req_body_form(campo = valor)` | manda un formulario por POST |
| `req_body_json(lista)` | manda JSON por POST |
| `req_timeout(30)` | corta si tarda más de 30 segundos |
| `req_retry(max_tries = 3)` | reintenta si falla |
| `req_throttle(rate = 30 / 60)` | como máximo 30 pedidos por minuto |

## Mirar antes de mandar

```r
pedido |> req_dry_run()
```

Muestra el pedido completo sin ejecutarlo: método, URL, cabeceras, cuerpo.
Es la primera herramienta a usar cuando algo no funciona y no sabés por qué.

## Ejecutar y leer

| Función | Devuelve |
|---|---|
| `req_perform()` | ejecuta y devuelve la respuesta |
| `resp_status()` | el código: 200, 403, 404, 429... |
| `resp_content_type()` | `text/html`, `application/json`... |
| `resp_body_json()` | el cuerpo como lista de R |
| `resp_body_html()` | el cuerpo como HTML, listo para rvest |
| `resp_body_string()` | el cuerpo como texto crudo |
| `resp_headers()` | las cabeceras de la respuesta |

## GET y POST

**GET** pide una página. Todo va en la URL, y por eso la podés copiar y compartir.

```r
request("https://datos.gob.ar/api/3/action/package_search") |>
  req_url_query(q = "empleo") |>
  req_perform()
```

**POST** manda datos en el cuerpo del pedido. La URL no cambia. Es lo que usan
los formularios de búsqueda.

```r
request("https://sitio.gob.ar/buscar.asp") |>
  req_body_form(anio = "2024", tipo = "convenio") |>
  req_perform()
```

Para saber qué campos manda un formulario: **F12 → Network → hacé la búsqueda a
mano → clic en el pedido → Form Data / Payload**.

## Errores que no cortan la corrida

Por defecto, `req_perform()` lanza un error si el código no es 200. A veces querés
mirar la respuesta igual — por ejemplo, para mostrar en clase un 403:

```r
request("https://ar.computrabajo.com/robots.txt") |>
  req_error(is_error = function(resp) FALSE) |>
  req_perform() |>
  resp_status()
#> 403
```

## Codificaciones viejas

Muchos sistemas públicos argentinos son anteriores a UTF-8. Si los acentos llegan
rotos (`Ã³`, `Ã±`), pedile a rvest que use la codificación correcta:

```r
resp |> resp_body_html(encoding = "ISO-8859-1")
```

## Cortesía

Tres cosas que no cuestan nada y evitan casi todos los bloqueos:

```r
request(url) |>
  req_user_agent("Investigación UNLP - nombre@institucion.edu.ar") |>
  req_throttle(rate = 20 / 60) |>     # 20 pedidos por minuto como techo
  req_retry(max_tries = 3)            # reintenta con espera creciente
```

Un `User-Agent` que dice quién sos y cómo contactarte convierte tu scraper en
alguien identificable. Es la diferencia entre un visitante y un intruso anónimo.

## Códigos de estado que vas a ver

| Código | Qué significa | Qué hacer |
|---|---|---|
| 200 | Todo bien | seguir |
| 301 / 302 | Se mudó | httr2 lo sigue solo |
| 403 | Prohibido | el sitio no atiende programas. Buscá API o sitemap |
| 404 | No existe | revisá la URL |
| 429 | Demasiados pedidos | bajá el ritmo, agregá `req_throttle()` |
| 500 / 503 | Se rompió del lado del servidor | reintentá más tarde |

Un 403 o un 429 no son bugs a esquivar: son mensajes. Leelos.

## Para seguir

- Documentación oficial: https://httr2.r-lib.org
- Guía de APIs REST con httr2: https://httr2.r-lib.org/articles/wrapping-apis.html
