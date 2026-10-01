# -----------------------------------------------------------------------------
# 02 — Extraer y limpiar
#
# Lee las copias locales de datos/crudo/, extrae los campos y guarda el CSV.
# No sale a internet: podés correrlo mil veces mientras ajustás selectores.
# -----------------------------------------------------------------------------

source("R/00-configuracion.R")


extraer <- function(archivo) {

  pagina  <- rvest::read_html(archivo)
  bloques <- pagina |> rvest::html_elements(CONFIG$selector)

  # Regla de la clase 2: primero la unidad, después los campos.
  # html_element() en SINGULAR sobre la lista de bloques devuelve un
  # resultado por bloque, y NA donde el campo no existe.
  tibble::tibble(
    campo_1 = bloques |> rvest::html_element("[selector-1]") |> rvest::html_text2(),
    campo_2 = bloques |> rvest::html_element("[selector-2]") |> rvest::html_text2(),
    enlace  = bloques |> rvest::html_element("a")            |> rvest::html_attr("href"),

    origen      = basename(archivo),
    recolectado = as.character(Sys.time())
  )
}


archivos <- list.files(CONFIG$crudo, pattern = "[.]html$", full.names = TRUE)

datos <- purrr::map(archivos, extraer) |> purrr::list_rbind()


# --- Limpieza ---
datos <- datos |>
  dplyr::mutate(
    campo_1 = stringr::str_squish(campo_1),
    campo_2 = stringr::str_squish(campo_2)
  ) |>
  dplyr::filter(!is.na(campo_1)) |>
  dplyr::distinct(enlace, .keep_all = TRUE)


readr::write_csv(datos, file.path(CONFIG$salida, "datos.csv"))

cat("\n", nrow(datos), "registros guardados en", CONFIG$salida, "\n")

# Si esto imprime 0, no es que "no había datos": es que el selector no
# coincide. Volvé al navegador y revisalo.
