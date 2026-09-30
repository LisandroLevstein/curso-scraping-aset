# -----------------------------------------------------------------------------
# Clase 3 · Script 1 — De una página a muchas: iteración con purrr
#
# Qué hace:  recorre varias páginas de un listado paginado y las une en una
#            sola tabla, con pausas entre pedidos y manejo de errores.
# Necesita:  rvest, dplyr, purrr, readr. Internet.
# Produce:   clase-03-iteracion-apis-dinamico/datos/salida/citas.csv
# Duración:  unos 10 segundos (hay pausas a propósito).
#
# Sitio:     quotes.toscrape.com — hecho para practicar, con paginación simple.
# -----------------------------------------------------------------------------

library(rvest)
library(dplyr)
library(purrr)
library(readr)


# --- 1. Entender el patrón de la URL -----------------------------------------
# Antes de iterar, mirá cómo cambia la dirección al pasar de página:
#
#   https://quotes.toscrape.com/page/1/
#   https://quotes.toscrape.com/page/2/
#
# Cambia un solo número. Ese es el caso fácil y el más común.
# Otros sitios usan ?page=2 o ?offset=20. La idea es la misma:
# encontrá qué parte cambia, y armá la URL con paste0().

armar_url <- function(n) {
  paste0("https://quotes.toscrape.com/page/", n, "/")
}

armar_url(1)
armar_url(2)


# --- 2. Resolver UNA página primero ------------------------------------------
# Nunca escribas el bucle antes de que funcione una sola página.
# Es la regla de oro: si falla con 1, va a fallar 50 veces con 50.

extraer_citas <- function(pagina) {
  bloques <- pagina |> html_elements("div.quote")

  tibble(
    cita  = bloques |> html_element("span.text")    |> html_text2(),
    autor = bloques |> html_element("small.author") |> html_text2(),

    # Las etiquetas son VARIAS por cita, así que no entran en una columna
    # de texto simple. Recorremos bloque por bloque con map_chr() y las
    # pegamos separadas por punto y coma.
    etiquetas = bloques |> map_chr(function(b) {
      b |> html_elements("a.tag") |> html_text2() |> paste(collapse = "; ")
    })
  )
}

read_html(armar_url(1)) |> extraer_citas()


# --- 3. Una función que baja una página --------------------------------------
# Le agregamos dos cosas que la versión de arriba no tenía:
#   - un mensaje, para saber por dónde va
#   - una pausa, para no golpear el servidor

bajar_pagina <- function(n) {
  message("Bajando página ", n)
  Sys.sleep(1)                     # un segundo entre pedido y pedido
  read_html(armar_url(n)) |> extraer_citas()
}


# --- 4. Iterar ---------------------------------------------------------------
# map() aplica la función a cada elemento y devuelve una lista.
# list_rbind() apila esa lista en un solo data frame.

citas <- map(1:5, bajar_pagina) |> list_rbind()

nrow(citas)          # 10 citas por página x 5 páginas
citas |> count(autor, sort = TRUE) |> head(5)


# --- 5. La trampa: un error que no parece un error ---------------------------
# El sitio tiene 10 páginas. Pedimos la 11:

pagina_11 <- read_html(armar_url(11))

pagina_11 |> html_elements("div.quote") |> length()      # 0 citas
pagina_11 |> html_element("body") |> html_text2() |> substr(1, 60)

# El servidor respondió 200 OK. No hubo ningún error.
# Simplemente devolvió una página que dice "No quotes found!".
#
# Si hubieras pedido 1:50 sin mirar, te habrías traído 40 páginas vacías
# y ningún aviso. En scraping, la ausencia de error NO es garantía de dato.
#
# La solución: definir vos la condición de corte. Acá es "0 citas".

bajar_hasta_vacio <- function(maximo = 20) {
  acumulado <- list()

  for (n in 1:maximo) {
    pagina <- bajar_pagina(n)

    if (nrow(pagina) == 0) {
      message("Página ", n, " vacía. Cortamos acá.")
      break
    }

    acumulado[[n]] <- pagina
  }

  list_rbind(acumulado)
}

todas <- bajar_hasta_vacio()
nrow(todas)


# --- 6. Que un error no tire abajo toda la corrida ---------------------------
# Si la página 7 de 50 falla (se cayó la red, el servidor tardó demasiado),
# map() se detiene y perdés las 6 que ya habías bajado.
#
# possibly() envuelve una función y le dice qué devolver si falla,
# en lugar de cortar todo.

bajar_seguro <- possibly(bajar_pagina, otherwise = tibble())

resultado <- map(c(1, 2, 999), bajar_seguro) |> list_rbind()

nrow(resultado)   # la página 999 no existe, pero 1 y 2 se salvaron

# En una recolección larga esto no es un lujo: es la diferencia entre
# perder dos horas de descarga o perder una página.


# --- 7. Guardar --------------------------------------------------------------

write_csv(todas, "clase-03-iteracion-apis-dinamico/datos/salida/citas.csv")

cat("\n", nrow(todas), "citas guardadas.\n")


# -----------------------------------------------------------------------------
# EJERCICIO
#
# 1. Cambiá la pausa de 1 segundo a 0.2 y volvé a correr. ¿Notás la diferencia?
#    ¿Por qué igual conviene dejarla en 1 con un sitio real?
# 2. Agregá una columna con el número de página de la que salió cada cita.
#    Pista: modificá bajar_pagina() para que la agregue con mutate().
# 3. Aplicá el patrón a books.toscrape.com, que tiene 50 páginas.
#    ¿Cómo se arma la URL de la página 2 en ese sitio?
# -----------------------------------------------------------------------------
