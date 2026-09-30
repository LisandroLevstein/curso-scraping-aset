# -----------------------------------------------------------------------------
# Clase 3 · Script 2 — Cuando hay API, se usa la API
#
# Qué hace:  consulta el catálogo de datos abiertos del Estado argentino
#            a través de su API, y arma una tabla con los conjuntos de datos.
# Necesita:  httr2, dplyr, purrr, readr. Internet.
# Produce:   clase-03-iteracion-apis-dinamico/datos/salida/datasets-empleo.csv
# Duración:  segundos.
#
# datos.gob.ar corre sobre CKAN, el software de portales de datos abiertos
# más usado del mundo. Lo mismo que aprendas acá sirve para cientos de
# portales de organismos públicos de toda la región.
# -----------------------------------------------------------------------------

library(httr2)
library(dplyr)
library(purrr)
library(readr)


# --- 1. Qué es una API -------------------------------------------------------
# Una API es una puerta que el sitio abrió A PROPÓSITO para que un programa
# le pida datos. No hay que adivinar selectores ni pelear con el diseño:
# devuelve JSON, un formato pensado para máquinas.
#
# Ventajas sobre el scraping:
#   - No se rompe cuando rediseñan el sitio.
#   - Es más rápida: no baja imágenes, estilos ni publicidad.
#   - Está permitida por definición. No hay nada que discutir.
#
# Regla: antes de escribir un scraper, buscá si hay API. Diez minutos de
# búsqueda te pueden ahorrar dos días de trabajo y todo el dolor de cabeza.


# --- 2. Armar el pedido ------------------------------------------------------
# httr2 construye el pedido por partes, con el pipe. Cada paso agrega algo.

pedido <- request("https://datos.gob.ar/api/3/action/package_search") |>
  req_url_query(q = "empleo", rows = 20) |>
  req_user_agent("Curso ASET - web scraping con R (docencia)")

# Antes de mandar nada, mirá qué vas a mandar:
pedido |> req_dry_run()

# req_dry_run() muestra el pedido sin ejecutarlo. Es el equivalente a leer
# el sobre antes de despacharlo. Usalo siempre que algo no funcione.


# --- 3. Ejecutarlo -----------------------------------------------------------

respuesta <- pedido |> req_perform()

resp_status(respuesta)         # 200 = todo bien
resp_content_type(respuesta)   # application/json


# --- 4. Leer el JSON ---------------------------------------------------------
# resp_body_json() convierte el JSON en una LISTA de R.
# Ojo: una lista, no un data frame. El JSON puede tener estructura anidada
# que una tabla no sabe representar.

datos <- respuesta |> resp_body_json()

names(datos)                   # help, success, result
datos$result$count             # cuántos conjuntos coinciden en total
length(datos$result$results)   # cuántos nos trajimos en este pedido

# Miramos UNO para entender la forma antes de procesar todos:
primero <- datos$result$results[[1]]

primero$title
primero$organization$title
length(primero$resources)      # archivos descargables del conjunto


# --- 5. De lista a tabla -----------------------------------------------------
# map_chr() recorre la lista y devuelve un vector de textos.
# Un elemento de la lista por fila de la tabla.

datasets <- tibble(
  titulo       = map_chr(datos$result$results, "title"),
  organismo    = map_chr(datos$result$results, \(x) x$organization$title),
  actualizado  = map_chr(datos$result$results, "metadata_modified"),
  n_recursos   = map_int(datos$result$results, \(x) length(x$resources)),
  url          = map_chr(datos$result$results, \(x) paste0("https://datos.gob.ar/dataset/", x$name))
)

datasets |> select(titulo, organismo) |> head(10)

# map_chr(lista, "title") es un atajo: cuando le pasás un texto en vez de
# una función, purrr entiende "traeme ese campo de cada elemento".


# --- 6. Paginar en una API ---------------------------------------------------
# Las APIs también paginan, pero te lo dicen de forma explícita.
# CKAN usa dos parámetros: rows (cuántos) y start (desde cuál).

pedir_pagina <- function(desde, por_pagina = 20) {
  message("Pidiendo desde el registro ", desde)
  Sys.sleep(0.5)

  request("https://datos.gob.ar/api/3/action/package_search") |>
    req_url_query(q = "empleo", rows = por_pagina, start = desde) |>
    req_user_agent("Curso ASET - web scraping con R (docencia)") |>
    req_perform() |>
    resp_body_json() |>
    _$result$results
}

# Tres páginas de 20 = 60 registros.
paginas <- map(c(0, 20, 40), pedir_pagina)

todos <- list_flatten(paginas)
length(todos)

# Fijate la diferencia con el scraping: acá no hubo que adivinar dónde
# terminaba el listado. La API te dice cuántos hay (datos$result$count)
# y vos calculás las páginas.


# --- 7. Guardar --------------------------------------------------------------

write_csv(datasets, "clase-03-iteracion-apis-dinamico/datos/salida/datasets-empleo.csv")

cat("\n", nrow(datasets), "conjuntos de datos guardados.\n")
cat("Total disponible en el portal para 'empleo':", datos$result$count, "\n")


# -----------------------------------------------------------------------------
# EJERCICIO
#
# 1. Cambiá q = "empleo" por un tema de tu investigación.
# 2. Agregá una columna con el formato del primer recurso de cada conjunto
#    (CSV, XLSX, JSON...). Pista: x$resources[[1]]$format
# 3. Calculá cuántas páginas harían falta para traer TODOS los resultados,
#    usando datos$result$count.
#
# DESAFÍO
#
# Muchos portales provinciales y municipales también usan CKAN.
# Probá cambiar el dominio por otro portal de datos abiertos y fijate
# si la misma consulta funciona sin tocar nada más. Ese es el punto de
# usar un estándar.
# -----------------------------------------------------------------------------
