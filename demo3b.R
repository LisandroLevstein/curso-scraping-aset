library(rvest)
library(httr2)
library(xml2)
library(stringr)
library(purrr)
library(dplyr)
library(tibble)

base_url <- "https://cifras.conicet.gov.ar"

dir.create("conicet_xlsx_03", showWarnings = FALSE)


# ============================================================
# 1. Explorar sistemáticamente todos los IDs de gráficos
# ============================================================

buscar_dataset <- function(id) {
  
  url_grafico <- sprintf(
    "%s/publica/grafico/show-publico/%d",
    base_url,
    id
  )
  
  message("Probando gráfico ", id)
  
  resultado <- tryCatch({
    
    resp <- request(url_grafico) |>
      req_user_agent(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
      ) |>
      req_timeout(15) |>
      req_perform()
    
    # Si no existe
    if (resp_status(resp) != 200) {
      return(NULL)
    }
    
    html <- resp_body_html(resp)
    
    # --------------------------------------------------------
    # título del gráfico
    # --------------------------------------------------------
    
    titulo <- html |>
      html_elements("h1, h2, h3, h4") |>
      html_text2()
    
    titulo <- titulo[nzchar(titulo)]
    
    if (length(titulo) > 0) {
      titulo <- titulo[length(titulo)]
    } else {
      titulo <- NA_character_
    }
    
    
    # --------------------------------------------------------
    # años disponibles en la página
    # --------------------------------------------------------
    
    texto <- html |>
      html_text2()
    
    anios <- str_extract_all(
      texto,
      "\\b(19|20)\\d{2}\\b"
    )[[1]] |>
      unique()
    
    anios <- paste(anios, collapse = ", ")
    
    
    # --------------------------------------------------------
    # enlaces downloadDataset
    # --------------------------------------------------------
    
    links <- html |>
      html_elements("a") |>
      html_attr("href") |>
      na.omit()
    
    datasets <- links[
      str_detect(
        links,
        "/publica/grafico/downloadDataset/"
      )
    ]
    
    if (length(datasets) == 0) {
      return(NULL)
    }
    
    datasets <- url_absolute(
      datasets,
      url_grafico
    ) |>
      unique()
    
    
    tibble(
      grafico_id = id,
      titulo = titulo,
      anios = anios,
      pagina = url_grafico,
      dataset = datasets
    )
    
  }, error = function(e) {
    
    message(
      "  Error en ID ", id,
      ": ", conditionMessage(e)
    )
    
    NULL
  })
  
  resultado
}


# ============================================================
# 2. Recorrer IDs
# ============================================================

# El sitio actualmente supera ID 1100.
# Uso 1500 para dejar margen.

ids <- 1:1500

resultados <- vector(
  "list",
  length(ids)
)

for (i in seq_along(ids)) {
  
  resultados[[i]] <- buscar_dataset(ids[i])
  
  if (i %% 50 == 0) {
    
    encontrados <- sum(
      !vapply(
        resultados[seq_len(i)],
        is.null,
        logical(1)
      )
    )
    
    message(
      "\n------------------------------",
      "\nIDs revisados: ", i,
      "\nGráficos con dataset: ", encontrados,
      "\n------------------------------\n"
    )
  }
  
  # pequeña pausa para no golpear innecesariamente el servidor
  Sys.sleep(0.15)
}


# ============================================================
# 3. Crear inventario
# ============================================================

inventario <- bind_rows(resultados) |>
  distinct(dataset, .keep_all = TRUE)

cat(
  "\nDatasets encontrados:",
  nrow(inventario),
  "\n"
)

print(inventario)


# guardar inventario

write.csv(
  inventario,
  "conicet_xlsx_03/inventario_datasets.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

# ============================================================
# 4. Descargar datasets
# ============================================================

limpiar_nombre <- function(x) {
  
  x |>
    str_replace_all("[^[:alnum:]áéíóúÁÉÍÓÚñÑ_-]+", "_") |>
    str_replace_all("_+", "_") |>
    str_remove_all("^_|_$") |>
    str_sub(1, 120)
}


for (i in seq_len(nrow(inventario))) {
  
  fila <- inventario[i, ]
  
  titulo_limpio <- limpiar_nombre(fila$titulo)
  
  if (
    is.na(titulo_limpio) ||
    titulo_limpio == ""
  ) {
    
    titulo_limpio <- paste0(
      "grafico_",
      fila$grafico_id
    )
  }
  
  archivo <- sprintf(
    "%04d_ID-%s_%s.xlsx",
    i,
    fila$grafico_id,
    titulo_limpio
  )
  
  destino <- file.path(
    "conicet_xlsx_03",
    archivo
  )
  
  message(
    "\n[",
    i,
    "/",
    nrow(inventario),
    "] ",
    archivo
  )
  
  
  tryCatch({
    
    request(fila$dataset) |>
      req_user_agent(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
      ) |>
      req_retry(max_tries = 3) |>
      req_timeout(60) |>
      req_perform(
        path = destino
      )
    
  }, error = function(e) {
    
    message(
      "ERROR: ",
      conditionMessage(e)
    )
    
  })
  
  Sys.sleep(0.25)
}
