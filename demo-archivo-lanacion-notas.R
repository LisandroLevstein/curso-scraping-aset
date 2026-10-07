# -----------------------------------------------------------------------------
# Clase 4 · Demo — Archivo La Nación: contenido de enero de 1999
#
# Qué hace:  lee el CSV de URLs (demo-archivo-lanacion-rss.R), baja cada nota y extrae una fila
#            por nota: sección, título, bajada, autor, fechas, cuerpo y más.
# Necesita:  httr2, rvest, xml2, jsonlite, dplyr, purrr, readr. Internet.
# Produce:   lanacion-1999-01-notas.csv (en este mismo directorio)
#            + copia de cada HTML en lanacion-notas/ (caché).
# Duración:  ~1 minuto la muestra de 20; el mes completo (~4000 notas) ~1 hora.
#
# Ojo: el sitemap solo trae loc + lastmod. Todo lo demás (título, cuerpo,
# autor) vive DENTRO de cada nota, en dos JSON embebidos: el NewsArticle
# (schema.org) y el bloque liftigniter (autor, bajada, sección). Por eso este
# script hace un pedido por nota, con pausa y caché.
# -----------------------------------------------------------------------------

library(httr2)
library(rvest)
library(xml2)
library(jsonlite)
library(dplyr)
library(purrr)
library(readr)

IDENTIDAD <- "Docente"
ENTRADA  <- "lanacion-1999-01-urls.csv"
CACHE    <- "lanacion-notas"
SALIDA   <- "lanacion-1999-01-notas.csv"
dir.create(CACHE, recursive = TRUE, showWarnings = FALSE)

# En clase: muestra chica para ver el mecanismo. Para el mes completo,
# poné MUESTRA <- NULL y dejalo corriendo (tarda ~1 hora por la pausa).
MUESTRA <- 20

urls <- read_csv(ENTRADA, show_col_types = FALSE)
if (!is.null(MUESTRA)) urls <- head(urls, MUESTRA)


# --- 1. Bajar el HTML de UNA nota (con caché) -----------------------------------
# Igual que en la demo del sitemap (demo-archivo-lanacion-rss.R): si ya está en disco, no se vuelve a pedir.

bajar_html <- function(url, pausa = 1) {
  destino <- file.path(
    CACHE,
    url |> sub("^https?://", "", x = _) |> gsub("[^A-Za-z0-9]+", "-", x = _) |> substr(1, 120) |> paste0(".html")
  )
  if (file.exists(destino)) return(read_html(destino))
  Sys.sleep(pausa)
  respuesta <- request(url) |>
    req_user_agent(IDENTIDAD) |>
    req_timeout(30) |>
    req_retry(max_tries = 3) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()
  if (resp_status(respuesta) != 200) return(NULL)
  writeLines(resp_body_string(respuesta), destino, useBytes = TRUE)
  read_html(destino)
}


# --- 2. Extraer TODOS los campos de una nota -------------------------------------
# Dos fuentes dentro del HTML: el JSON NewsArticle (título, cuerpo, fechas,
# imagen) y el JSON liftigniter (autor, bajada, sección, tags).

extraer_nota <- function(url, lastmod, fuente) {
  h <- bajar_html(url)
  if (is.null(h)) {
    return(tibble(url = url, estado = "error"))
  }

  # NewsArticle: el bloque ld+json que lo contiene (hay 5, solo 1 sirve).
  textos <- h |> html_elements("script[type='application/ld+json']") |> html_text2()
  noticia <- textos[grepl("NewsArticle", textos, fixed = TRUE)][1] |> fromJSON()

  # liftigniter: autor y bajada vienen con HTML adentro ("Por X<br/>...").
  lift <- h |> html_element("script#liftigniter-metadata") |> html_text2() |> fromJSON()
  autor <- lift$autor |> gsub("<[^>]+>", " ", x = _) |> trimws() |> gsub("\\s+", " ", x = _)

  tibble(
    url               = url,
    seccion           = lift$tematica,
    titulo            = noticia$headline,
    bajada            = lift$leadText,
    autor             = ifelse(autor == "", NA, autor),
    fecha_publicacion = noticia$datePublished,
    fecha_modificacion = noticia$dateModified,
    lastmod_sitemap   = lastmod,
    fuente_sitemap    = fuente,
    descripcion       = noticia$description,
    cuerpo            = noticia$articleBody,
    n_caracteres      = nchar(noticia$articleBody),
    imagen            = noticia$thumbnailUrl,
    tags              = paste(unlist(lift$tags), collapse = "; "),
    estado            = "ok"
  )
}

# Que una nota caída no tire abajo las otras 4000:
extraer_segura <- possibly(
  extraer_nota,
  otherwise = tibble(url = character(), estado = character())
)


# --- 3. Iterar, unir y guardar -----------------------------------------------------

notas <- pmap(
  list(urls$loc, urls$lastmod, urls$fuente),
  function(u, l, f) extraer_segura(u, l, f)
) |> list_rbind()

write_csv(notas, SALIDA)

cat("\nNotas:", nrow(notas),
    "| OK:", sum(notas$estado == "ok"),
    "| Con autor:", sum(!is.na(notas$autor)),
    "| Con bajada:", sum(notas$bajada != "", na.rm = TRUE), "\n")

# -----------------------------------------------------------------------------
# EJERCICIO
# 1. Con el CSV: ¿qué sección publicó más en enero de 1999? (hint: count(seccion))
# 2. ¿Qué nota es la más larga? (hint: arrange(desc(n_caracteres)))
# -----------------------------------------------------------------------------
