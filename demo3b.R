# Instalar una sola vez si hace falta:
# install.packages(c("rvest", "httr2", "xml2", "stringr", "purrr"))

library(rvest)
library(httr2)
library(xml2)
library(stringr)
library(purrr)

base_url <- "https://cifras.conicet.gov.ar"
inicio   <- paste0(base_url, "/publica/")

dir.create("conicet_xlsx", showWarnings = FALSE)

# ------------------------------------------------------------
# 1. Función para obtener enlaces de una página
# ------------------------------------------------------------

obtener_links <- function(url) {
  
  message("Leyendo: ", url)
  
  html <- read_html(url)
  
  hrefs <- html |>
    html_elements("a") |>
    html_attr("href") |>
    na.omit() |>
    unique()
  
  # Convertir enlaces relativos a absolutos
  xml2::url_absolute(hrefs, url)
}


# ------------------------------------------------------------
# 2. Recorrer las páginas internas de /publica/
# ------------------------------------------------------------

visitadas <- character()
pendientes <- inicio
links_descarga <- character()

while (length(pendientes) > 0) {
  
  url <- pendientes[1]
  pendientes <- pendientes[-1]
  
  if (url %in% visitadas)
    next
  
  visitadas <- c(visitadas, url)
  
  links <- tryCatch(
    obtener_links(url),
    error = function(e) {
      message("Error leyendo ", url, ": ", conditionMessage(e))
      character()
    }
  )
  
  if (length(links) == 0)
    next
  
  # Enlaces de datasets
  datasets <- links[
    str_detect(
      links,
      "/publica/grafico/downloadDataset/"
    )
  ]
  
  links_descarga <- unique(c(links_descarga, datasets))
  
  # Enlaces internos que permanecen dentro de /publica/
  nuevos <- links[
    str_starts(links, paste0(base_url, "/publica/"))
  ]
  
  # No volver a visitar datasets ni recursos estáticos
  nuevos <- nuevos[
    !str_detect(
      nuevos,
      "downloadDataset|\\.(css|js|png|jpg|jpeg|gif|svg|ico|pdf|xlsx?|zip)(\\?|$)"
    )
  ]
  
  nuevos <- setdiff(nuevos, visitadas)
  
  pendientes <- unique(c(pendientes, nuevos))
  
  message(
    "Páginas visitadas: ", length(visitadas),
    " | datasets encontrados: ", length(links_descarga)
  )
  
  Sys.sleep(0.2)
}


# ------------------------------------------------------------
# 3. Descargar todos los datasets
# ------------------------------------------------------------

message("\nTotal de datasets encontrados: ", length(links_descarga))

for (i in seq_along(links_descarga)) {
  
  url <- links_descarga[i]
  
  # IDs del enlace, por ejemplo:
  # /downloadDataset/1063/86e68f4d467d3ae1e636e320c17ea09a
  
  partes <- str_match(
    url,
    "downloadDataset/([^/]+)/([^/?]+)"
  )
  
  id   <- partes[, 2]
  hash <- partes[, 3]
  
  archivo <- file.path(
    "conicet_xlsx",
    sprintf("%04d_dataset_%s.xlsx", i, id)
  )
  
  message(
    "[", i, "/", length(links_descarga), "] ",
    basename(archivo)
  )
  
  tryCatch({
    
    request(url) |>
      req_user_agent(
        "Mozilla/5.0 R downloader"
      ) |>
      req_retry(max_tries = 3) |>
      req_perform(path = archivo)
    
  }, error = function(e) {
    
    message(
      "ERROR: ",
      conditionMessage(e)
    )
    
  })
  
  Sys.sleep(0.3)
}


# ------------------------------------------------------------
# 4. Guardar inventario de URLs
# ------------------------------------------------------------

writeLines(
  links_descarga,
  "conicet_xlsx/urls_descarga.txt"
)

cat(
  "\nFinalizado.\n",
  "Datasets encontrados:", length(links_descarga), "\n",
  "Directorio: conicet_xlsx\n"
)

##################################################

library(rvest)
library(xml2)
library(stringr)
library(httr2)

url <- "https://cifras.conicet.gov.ar/publica/"

html <- read_html(url)

links <- html |>
  html_elements("a.dataset-download") |>
  html_attr("href") |>
  url_absolute(url) |>
  unique()

dir.create("conicet_xlsx2", showWarnings = FALSE)

for (i in seq_along(links)) {
  
  destino <- file.path(
    "conicet_xlsx2",
    sprintf("dataset_%04d.xlsx", i)
  )
  
  request(links[i]) |>
    req_perform(path = destino)
  
  message(i, "/", length(links))
}
