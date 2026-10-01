# -----------------------------------------------------------------------------
# 01 — Recolectar
#
# Baja las páginas y guarda una copia local en datos/crudo/.
# No extrae ni limpia nada: eso es el paso 02.
#
# Separar la descarga de la extracción tiene una ventaja concreta: si más
# adelante te equivocaste en un selector, corregís y volvés a extraer SIN
# volver a molestar al servidor.
# -----------------------------------------------------------------------------

source("R/00-configuracion.R")


armar_url <- function(n) {
  # [Ajustá esto al patrón de tu sitio]
  paste0(CONFIG$fuente, "?page=", n)
}


bajar <- function(n) {
  url     <- armar_url(n)
  destino <- file.path(CONFIG$crudo, paste0("pagina-", n, ".html"))

  if (file.exists(destino)) {
    message("[cache] página ", n)
    return(invisible(destino))
  }

  message("[red]   página ", n)
  Sys.sleep(CONFIG$pausa)

  respuesta <- httr2::request(url) |>
    httr2::req_user_agent(CONFIG$identidad) |>
    httr2::req_timeout(30) |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()

  if (httr2::resp_status(respuesta) != 200) {
    warning("Página ", n, ": el servidor respondió ",
            httr2::resp_status(respuesta), call. = FALSE)
    return(invisible(NULL))
  }

  writeLines(httr2::resp_body_string(respuesta), destino, useBytes = TRUE)
  invisible(destino)
}


# Empezá siempre con UNA página. Recién cuando el paso 02 funcione,
# subí max_paginas.
archivos <- purrr::map(1:CONFIG$max_paginas, bajar)

message("\nListo. Archivos en ", CONFIG$crudo)
