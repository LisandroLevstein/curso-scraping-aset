# -----------------------------------------------------------------------------
# Clase 4 · Demo — Archivo La Nación: enero de 1999 desde el sitemap
#
# Qué hace:  trae las URLs de notas de enero de 1999 desde el sitemap oficial
#            (la puerta legítima: el feed RSS actual solo trae lo reciente)
#            y las guarda en un CSV, sin duplicados.
# Necesita:  httr2, xml2, dplyr, purrr, readr. Internet.
# Produce:   lanacion-1999-01-urls.csv (en este mismo directorio)
#            + copia de cada XML en lanacion-sitemap/ (para no pedir dos veces).
# Duración:  ~1 minuto (hay pausas a propósito).
#
# Por qué DOS pasadas: medido el 2026-10-07, ninguna ventana sola es completa.
# La diaria suma ~3760 URLs y la mensual ~3560, pero cada una trae cientos que
# la otra no trae. El script pasa la red diaria (base) y la mensual (rescate),
# y une por URL.
# -----------------------------------------------------------------------------

library(httr2)
library(xml2)
library(dplyr)
library(purrr)
library(readr)

IDENTIDAD <- "Docente"
CRUDO  <- "lanacion-sitemap"
SALIDA <- "lanacion-1999-01-urls.csv"
dir.create(CRUDO, recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(SALIDA), recursive = TRUE, showWarnings = FALSE)


# --- 1. Armar la URL del sitemap para una ventana de fechas -------------------
# El patrón vive declarado en robots.txt: .../sitemap-articles-fromDESDE-toHASTA.xml
# https://www.lanacion.com.ar/sitemap-articles-from1999-12-01T00:00:00Z-to1999-12-03T00:00:00Z.xml

armar_url <- function(desde, hasta) {
  paste0(
    "https://www.lanacion.com.ar/sitemap-articles-from",
    desde, "T00:00:00Z-to", hasta, "T00:00:00Z.xml"
  )
}


# --- 2. Bajar UNA ventana ------------------------------------------------------
# Si el XML ya está en disco, se lee de ahí: cada pedido ahorrado es carga
# que no le ponemos a un servidor que no es nuestro.

bajar_ventana <- function(desde, hasta, fuente, pausa = 1) {
  destino <- file.path(CRUDO, paste0("sitemap-", desde, "-a-", hasta, ".xml"))

  if (file.exists(destino)) {
    message("[cache] ", desde, " -> ", hasta)
  } else {
    message("[red]   ", desde, " -> ", hasta)
    Sys.sleep(pausa)
    respuesta <- request(armar_url(desde, hasta)) |>
      req_user_agent(IDENTIDAD) |>
      req_timeout(30) |>
      req_retry(max_tries = 3) |>
      req_perform()
    writeLines(resp_body_string(respuesta), destino, useBytes = TRUE)
  }

  nodos <- destino |> read_xml() |> xml_find_all("//*[local-name()='url']")

  tibble(
    loc     = nodos |> xml_find_first("./*[local-name()='loc']") |> xml_text(),
    lastmod = nodos |> xml_find_first("./*[local-name()='lastmod']") |> xml_text(),
    fuente  = fuente
  )
}

# Que una ventana fallida no tire abajo las otras 31:
bajar_segura <- possibly(
  bajar_ventana,
  otherwise = tibble(loc = character(), lastmod = character(), fuente = character())
)


# --- 3. Red base: 31 ventanas de 24 h ------------------------------------------

dias <- seq(as.Date("1999-01-01"), as.Date("1999-01-31"), by = "day") |> as.character()

diaria <- map(
  dias,
  function(d) bajar_segura(d, as.character(as.Date(d) + 1), "diaria")
) |> list_rbind()


# --- 4. Red de rescate: 1 ventana mensual ---------------------------------------

mensual <- bajar_segura("1999-01-01", "1999-02-01", "mensual")


# --- 5. Unir sin duplicar y guardar ----------------------------------------------
# distinct() conserva la primera aparición: lo que trajo la diaria manda,
# y la mensual solo agrega lo que la diaria no había visto.

todo <- bind_rows(diaria, mensual) |>
  distinct(loc, .keep_all = TRUE) |>
  arrange(loc)

write_csv(todo, SALIDA)

cat(
  "\nDiaria:", nrow(diaria),
  "| Mensual:", nrow(mensual),
  "| Unión sin duplicar:", nrow(todo),
  "| Rescate mensual:", sum(!mensual$loc %in% diaria$loc), "\n"
)

# -----------------------------------------------------------------------------
# EJERCICIO
# 1. Cambiá el mes (los tres "1999-01" y el "1999-02-01") y traé febrero de 1999.
# 2. Con el CSV en mano: ¿cuántas URLs son de cada lastmod? (hint: count(lastmod))
# -----------------------------------------------------------------------------
