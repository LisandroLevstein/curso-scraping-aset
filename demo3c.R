# ===============================================================
# CONICET EN CIFRAS: DESCUBRIMIENTO Y DESCARGA MASIVA DE JSON
# Páginas públicas show-publico, incluidas sus series históricas.
# Guarda avances para poder interrumpir y reanudar.
# ===============================================================

paquetes <- c("rvest", "xml2", "httr2", "stringr", "dplyr",
              "tibble", "purrr", "readr", "jsonlite")
faltantes <- setdiff(paquetes, rownames(installed.packages()))
if (length(faltantes)) install.packages(faltantes)

# ----------------------- CONFIGURACIÓN --------------------------
BASE <- "https://cifras.conicet.gov.ar"
IDS <- 1:1600                    # Aumentar si aparecen IDs superiores
PAUSA_HTTP <- 0.40              # No realizar solicitudes simultáneas
PAUSA_CLIC <- 0.50
MAX_ESPERA <- 12                # Segundos por selección de año
DESTINO <- "conicet_json_completo"
DIR_JSON <- file.path(DESTINO, "json")
dir.create(DIR_JSON, recursive = TRUE, showWarnings = FALSE)
ARCH_SCAN <- file.path(DESTINO, "avance_paginas.rds")
ARCH_LIVE <- file.path(DESTINO, "avance_anios.rds")
AGENTE <- "Mozilla/5.0 (compatible; investigacion-academica; descarga-moderada)"

# ----------------------- FUNCIONES ------------------------------
url_grafico <- function(id) sprintf("%s/publica/grafico/show-publico/%s", BASE, id)

# Evita que las rutas JSON escapadas como \/archivos-grafico se pierdan.
urls_json_texto <- function(texto, base = BASE) {
  if (!length(texto) || is.na(texto)) return(character())
  texto <- gsub("\\/", "/", texto, fixed = TRUE)
  patron <- "(?:https?://[^\\\"' <>]+)?/?archivos-grafico/[A-Za-z0-9._%-]+\\.json(?:\\?[^\\\"' <>]*)?"
  hallados <- unique(stringr::str_extract_all(texto, patron)[[1]])
  if (!length(hallados)) return(character())
  hallados <- xml2::url_absolute(hallados, paste0(base, "/"))
  # El parámetro después de ?render-grafico-... no forma parte del archivo.
  unique(sub("\\?.*$", "", hallados))
}

# La mayoría de las páginas tienen input[name=selector] + label[for].
extraer_pagina <- function(id) {
  url <- url_grafico(id)
  tryCatch({
    resp <- httr2::request(url) |>
      httr2::req_user_agent(AGENTE) |>
      httr2::req_timeout(20) |>
      httr2::req_retry(max_tries = 2) |>
      httr2::req_error(is_error = function(resp) FALSE) |>
      httr2::req_perform()
    estado <- httr2::resp_status(resp)
    if (estado != 200) {
      return(list(id = id, estado = estado, error = NA_character_,
                  titulo = NA_character_, anios = character(),
                  internos = character(), json_html = character()))
    }
    doc <- xml2::read_html(httr2::resp_body_raw(resp))
    entradas <- rvest::html_elements(doc, 'input[name="selector"]')
    anios <- rvest::html_attr(entradas, "value")
    anios <- unique(anios[!is.na(anios) & grepl("^[12][0-9]{3}$", anios)])
    # Extraer renderGraficoAnio tanto de etiquetas como de scripts.
    bruto <- as.character(doc)
    internos <- stringr::str_match_all(
      bruto, "renderGraficoAnio\\s*\\(\\s*([0-9]+)"
    )[[1]]
    internos <- if (nrow(internos)) unique(internos[, 2]) else character()
    titulos <- rvest::html_text2(rvest::html_elements(doc, "h1,h2,h3,h4"))
    titulos <- trimws(titulos[nzchar(trimws(titulos))])
    titulo <- if (length(titulos)) tail(titulos, 1) else NA_character_
    list(id = id, estado = estado, error = NA_character_, titulo = titulo,
         anios = anios, internos = internos, json_html = urls_json_texto(bruto))
  }, error = function(e) {
    list(id = id, estado = NA_integer_, error = conditionMessage(e),
         titulo = NA_character_, anios = character(), internos = character(),
         json_html = character())
  })
}

ejecutar_js <- function(pagina, js) {
  res <- pagina$session$Runtime$evaluate(expression = js, returnByValue = TRUE)
  if (!is.null(res$exceptionDetails)) stop("JavaScript: ", res$exceptionDetails$text)
  res$result$value
}

obtener_json_live <- function(pagina) {
  js <- paste0(
    "performance.getEntriesByType('resource').map(x => x.name)",
    ".filter(x => x.includes('/archivos-grafico/') && x.includes('.json'))"
  )
  urls <- unlist(ejecutar_js(pagina, js), use.names = FALSE)
  unique(sub("\\?.*$", "", urls))
}

esperar_json <- function(pagina, segundos = MAX_ESPERA) {
  inicio <- Sys.time()
  repeat {
    urls <- obtener_json_live(pagina)
    if (length(urls)) return(urls)
    if (as.numeric(difftime(Sys.time(), inicio, units = "secs")) >= segundos)
      return(character())
    Sys.sleep(0.4)
  }
}

guardar_tablas <- function(paginas, registros) {
  paginas_tabla <- dplyr::bind_rows(lapply(paginas, function(x) {
    tibble::tibble(id = x$id, estado = x$estado, error = x$error,
                   titulo = x$titulo,
                   anios = paste(x$anios, collapse = ", "),
                   ids_internos = paste(x$internos, collapse = ", "),
                   json_html = paste(x$json_html, collapse = " | "))
  }))
  readr::write_csv(paginas_tabla, file.path(DESTINO, "inventario_paginas.csv"))
  if (nrow(registros))
    readr::write_csv(registros, file.path(DESTINO, "inventario_json.csv"))
}

# -------------------- FASE 1: FUERZA BRUTA ----------------------
# Primero se examinan los IDs con HTTP normal: mucho más rápido
# que abrir una sesión Chrome por cada identificador inexistente.
message("FASE 1: revisando páginas públicas...")
paginas <- if (file.exists(ARCH_SCAN)) readRDS(ARCH_SCAN) else list()
for (id in IDS) {
  clave <- as.character(id)
  if (!is.null(paginas[[clave]]) && !is.na(paginas[[clave]]$estado)) next
  info <- extraer_pagina(id)
  paginas[[clave]] <- info
  message("ID ", id, " -> ", info$estado, "; años=", length(info$anios),
          "; JSON HTML=", length(info$json_html),
          if (!is.na(info$error)) paste0("; error=", info$error) else "")
  # Guardar también errores: se reintentarán en la siguiente ejecución.
  if (id %% 20 == 0) saveRDS(paginas, ARCH_SCAN)
  Sys.sleep(PAUSA_HTTP)
}
saveRDS(paginas, ARCH_SCAN)

# Si las páginas remiten mediante renderGraficoAnio a IDs superiores,
# examinarlos también. NO probar indefinidamente nuevos números.
extra <- unique(as.integer(unlist(lapply(paginas, `[[`, "internos"))))
extra <- extra[!is.na(extra) & !(extra %in% IDS)]
message("IDs adicionales encontrados en selectores: ", length(extra))
for (id in extra) {
  clave <- as.character(id)
  if (!is.null(paginas[[clave]]) && !is.na(paginas[[clave]]$estado)) next
  paginas[[clave]] <- extraer_pagina(id)
  saveRDS(paginas, ARCH_SCAN)
  Sys.sleep(PAUSA_HTTP)
}

validas <- Filter(function(x) !is.na(x$estado) && x$estado == 200, paginas)
message("Páginas HTTP 200: ", length(validas))

# Registra JSON encontrados directamente en el HTML, aunque no tengan año.
registros <- if (file.exists(ARCH_LIVE)) readRDS(ARCH_LIVE) else
  tibble::tibble(pagina_id = integer(), anio = character(),
                 url_json = character(), origen = character(),
                 estado = character())
hechos <- if (file.exists(file.path(DESTINO, "anios_procesados.rds")))
  readRDS(file.path(DESTINO, "anios_procesados.rds")) else character()

for (p in validas) {
  for (u in p$json_html) {
    if (!u %in% registros$url_json) {
      registros <- dplyr::bind_rows(registros,
                                    tibble::tibble(pagina_id = as.integer(p$id), anio = NA_character_,
                                                   url_json = u, origen = "html", estado = "detectado"))
    }
  }
}
saveRDS(registros, ARCH_LIVE)

# ---------------- FASE 2: SERIES HISTÓRICAS --------------------
# Si varias páginas apuntan a los MISMOS IDs internos, basta
# una página representante por serie. Si no hay IDs internos,
# se procesa individualmente (sin agrupamientos inseguros).
con_anios <- Filter(function(x) length(x$anios) > 0, validas)
firmas <- vapply(con_anios, function(x) {
  if (length(x$internos)) {
    paste0("serie:", paste(sort(unique(x$internos)), collapse = "-"))
  } else {
    paste0("pagina:", x$id)
  }
}, character(1))
representantes <- con_anios[!duplicated(firmas)]
message("FASE 2: ", length(representantes), " páginas/series con años")

for (p in representantes) {
  id <- p$id
  message("Abriendo en Chrome gráfico ", id)
  pagina <- tryCatch(rvest::read_html_live(url_grafico(id)),
                     error = function(e) { message("Chrome: ", conditionMessage(e)); NULL })
  if (is.null(pagina)) next
  
  # El año inicialmente seleccionado puede cargar JSON sin ningún clic.
  inicial <- tryCatch(ejecutar_js(pagina,
                                  "document.querySelector('input[name=selector]:checked')?.value || null"),
                      error = function(e) NULL)
  inicial <- if (length(inicial)) as.character(inicial) else NA_character_
  urls_iniciales <- tryCatch(esperar_json(pagina), error = function(e) character())
  if (length(urls_iniciales)) {
    registros <- dplyr::bind_rows(registros, tibble::tibble(
      pagina_id = as.integer(id), anio = inicial, url_json = urls_iniciales,
      origen = "carga_inicial", estado = "detectado"))
    if (!is.na(inicial)) hechos <- unique(c(hechos, paste(id, inicial, sep = ":")))
    saveRDS(registros, ARCH_LIVE)
    saveRDS(hechos, file.path(DESTINO, "anios_procesados.rds"))
  }
  
  # Detectar los años desde el DOM EN VIVO, no asumir 2016:2025.
  anios <- tryCatch({
    nodos <- rvest::html_elements(pagina, 'input[name="selector"]')
    unique(rvest::html_attr(nodos, "value"))
  }, error = function(e) p$anios)
  anios <- anios[!is.na(anios) & grepl("^[12][0-9]{3}$", anios)]
  
  for (anio in anios) {
    llave <- paste(id, anio, sep = ":")
    if (llave %in% hechos) next
    message("  Año: ", anio)
    resultado <- tryCatch({
      ejecutar_js(pagina, "performance.clearResourceTimings()")
      pagina$click(sprintf("label[for='option-%s']", anio))
      urls <- esperar_json(pagina)
      if (!length(urls)) return_value <- "sin_json" else return_value <- "detectado"
      list(urls = urls, estado = return_value)
    }, error = function(e) list(urls = character(), estado = paste0("error: ", conditionMessage(e))))
    
    if (length(resultado$urls)) {
      registros <- dplyr::bind_rows(registros, tibble::tibble(
        pagina_id = as.integer(id), anio = anio,
        url_json = resultado$urls, origen = "clic", estado = resultado$estado))
      hechos <- unique(c(hechos, llave))
    } else {
      # Registrar el fallo, PERO no marcar como completado: reintentable.
      registros <- dplyr::bind_rows(registros, tibble::tibble(
        pagina_id = as.integer(id), anio = anio,
        url_json = NA_character_, origen = "clic", estado = resultado$estado))
      message("    Atención: ", resultado$estado)
    }
    saveRDS(registros, ARCH_LIVE)
    saveRDS(hechos, file.path(DESTINO, "anios_procesados.rds"))
    Sys.sleep(PAUSA_CLIC)
  }
  # Cerrar Chrome para evitar acumular cientos de sesiones abiertas.
  try(pagina$session$close(), silent = TRUE)
}

registros <- dplyr::distinct(registros)
guardar_tablas(paginas, registros)

# --------------------- FASE 3: DESCARGA ------------------------
# URLs únicas, preservando en inventario todas sus procedencias.
urls <- sort(unique(stats::na.omit(registros$url_json)))
message("FASE 3: JSON únicos descubiertos: ", length(urls))
descargas <- tibble::tibble(
  url_json = urls,
  archivo = file.path(DIR_JSON, basename(urls)),
  estado = "pendiente"
)
# Por precaución, evitar sobrescribir si dos URL usan el mismo basename.
descargas$archivo <- file.path(DIR_JSON, make.unique(basename(urls)))

validar_json <- function(ruta) {
  if (!file.exists(ruta) || file.info(ruta)$size == 0) return(FALSE)
  tryCatch(jsonlite::validate(paste(readLines(ruta, warn = FALSE,
                                              encoding = "UTF-8"), collapse = "\n")),
           error = function(e) FALSE)
}

for (i in seq_len(nrow(descargas))) {
  destino <- descargas$archivo[i]
  if (validar_json(destino)) {
    descargas$estado[i] <- "existia_valido"
    next
  }
  temporal <- paste0(destino, ".part")
  message("JSON ", i, "/", nrow(descargas), ": ", basename(destino))
  resultado <- tryCatch({
    httr2::request(descargas$url_json[i]) |>
      httr2::req_user_agent(AGENTE) |>
      httr2::req_timeout(50) |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_perform(path = temporal)
    if (!validar_json(temporal)) stop("La respuesta no es un JSON válido")
    if (!file.rename(temporal, destino)) stop("No se pudo mover archivo temporal")
    "descargado"
  }, error = function(e) {
    if (file.exists(temporal)) unlink(temporal)
    paste0("error: ", conditionMessage(e))
  })
  descargas$estado[i] <- resultado
  readr::write_csv(descargas, file.path(DESTINO, "estado_descargas.csv"))
  Sys.sleep(PAUSA_HTTP)
}
readr::write_csv(descargas, file.path(DESTINO, "estado_descargas.csv"))
message("FINALIZADO: ", nrow(descargas), " JSON detectados; ",
        sum(descargas$estado %in% c("descargado", "existia_valido")),
        " descargados/válidos.")
message("Revisar inventario_json.csv y filas 'sin_json' o 'error' para detectar faltantes.")