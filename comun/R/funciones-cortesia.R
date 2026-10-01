# -----------------------------------------------------------------------------
# Funciones de cortesía — compartidas por todo el curso
#
# Qué hace:  descargar páginas identificándose, con pausas, reintentos y
#            copia local, para no golpear dos veces el mismo servidor.
# Necesita:  httr2, rvest.
# Uso:       source("comun/R/funciones-cortesia.R")
#
# Estas cuatro líneas de cortesía evitan la enorme mayoría de los bloqueos.
# No son un truco para pasar desapercibido: son lo contrario. Sirven para
# que el servidor sepa quién sos y vea que no le estás haciendo daño.
# -----------------------------------------------------------------------------

library(httr2)
library(rvest)


# Cambiá esto por tus datos reales antes de usarlo con un sitio de verdad.
# Un User-Agent que dice quién sos y cómo contactarte convierte tu scraper
# en alguien identificable. Es la diferencia entre un visitante y un intruso.
IDENTIDAD <- "Investigacion academica ASET - nombre@institucion.edu.ar"


# --- Convertir una URL en un nombre de archivo válido ------------------------
# Sirve para guardar la copia local sin que el sistema se queje por las
# barras y los signos de pregunta.

nombre_archivo <- function(url) {
  url |>
    sub("^https?://", "", x = _) |>
    gsub("[^A-Za-z0-9]+", "-", x = _) |>
    substr(1, 120)
}


# --- Descargar una página con cortesía ---------------------------------------
#
#   url      la dirección a bajar
#   cache    carpeta donde guardar la copia local
#   pausa    segundos de espera antes de cada pedido nuevo
#   formato  "html" para páginas web (devuelve el HTML listo para rvest)
#            "texto" para archivos de texto plano, como robots.txt
#
# Ojo con esto: robots.txt NO es HTML. Si le pedís a read_html() que lea un
# texto plano y corto, xml2 cree que le pasaste el nombre de un archivo y
# falla con un mensaje confuso. Por eso el argumento `formato`.

descargar <- function(url, cache = NULL, pausa = 2, formato = "html") {

  # 1. Si ya la bajamos antes, no la volvemos a pedir.
  #    Esto no es solo eficiencia: cada pedido que no hacés es carga que no
  #    le ponés a un servidor que no es tuyo.
  if (!is.null(cache)) {
    extension <- if (formato == "texto") ".txt" else ".html"
    destino   <- file.path(cache, paste0(nombre_archivo(url), extension))

    if (file.exists(destino)) {
      message("[cache] ", url)

      if (formato == "texto") {
        return(paste(readLines(destino, warn = FALSE), collapse = "\n"))
      }
      return(read_html(destino))
    }
  }

  # 2. Pausa antes de pedir.
  message("[red]   ", url)
  Sys.sleep(pausa)

  # 3. El pedido, con identidad y reintentos.
  respuesta <- request(url) |>
    req_user_agent(IDENTIDAD) |>
    req_timeout(30) |>
    req_retry(max_tries = 3) |>
    req_error(is_error = function(resp) FALSE) |>   # no cortar: queremos ver el código
    req_perform()

  codigo <- resp_status(respuesta)

  if (codigo != 200) {
    warning("El servidor respondió ", codigo, " para ", url, call. = FALSE)
    return(NULL)
  }

  cuerpo <- resp_body_string(respuesta)

  # 4. Guardar la copia local.
  if (!is.null(cache)) {
    dir.create(cache, recursive = TRUE, showWarnings = FALSE)
    writeLines(cuerpo, destino, useBytes = TRUE)
  }

  if (formato == "texto") {
    return(cuerpo)
  }

  # charToRaw() le deja claro a read_html() que esto es CONTENIDO,
  # no la ruta de un archivo.
  read_html(charToRaw(cuerpo))
}


# --- Diagnosticar qué respondió un sitio -------------------------------------
# Devuelve el código y una traducción en castellano de qué conviene hacer.

diagnosticar <- function(url) {

  respuesta <- request(url) |>
    req_user_agent(IDENTIDAD) |>
    req_timeout(20) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()

  codigo <- resp_status(respuesta)

  sugerencia <- switch(
    as.character(codigo),
    "200" = "Todo bien. Adelante.",
    "301" = "Se mudó. httr2 sigue la redirección solo.",
    "302" = "Se mudó temporalmente. httr2 la sigue solo.",
    "403" = "Prohibido. El sitio no atiende programas automáticos. Buscá API, sitemap o pedí acceso.",
    "404" = "No existe. Revisá la URL.",
    "429" = "Demasiados pedidos. Bajá el ritmo y aumentá la pausa.",
    "500" = "Se rompió del lado del servidor. Reintentá más tarde.",
    "503" = "Servicio no disponible. Reintentá más tarde.",
    "Código poco común. Buscá qué significa antes de insistir."
  )

  list(url = url, codigo = codigo, sugerencia = sugerencia)
}
