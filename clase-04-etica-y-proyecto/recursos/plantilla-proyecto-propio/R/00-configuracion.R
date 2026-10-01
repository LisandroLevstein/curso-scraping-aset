# -----------------------------------------------------------------------------
# 00 — Configuración del proyecto
#
# Todo lo que puede cambiar vive acá, en un solo lugar y con nombre.
# Los demás scripts leen de este objeto y no definen nada por su cuenta.
# -----------------------------------------------------------------------------

paquetes <- c("rvest", "httr2", "dplyr", "stringr", "purrr", "readr")

faltantes <- paquetes[!paquetes %in% rownames(installed.packages())]
if (length(faltantes) > 0) install.packages(faltantes)

invisible(lapply(paquetes, library, character.only = TRUE))


CONFIG <- list(

  # --- Fuente ---
  fuente   = "[https://ejemplo.com/listado]",
  selector = "[.clase-del-bloque-que-se-repite]",

  # --- Identidad: cambiá esto por tus datos reales ---
  identidad = "[Nombre del proyecto] - [tu.correo@institucion.edu.ar]",

  # --- Cortesía ---
  pausa       = 2,      # segundos entre pedidos
  max_paginas = 5,      # tope de seguridad: empezá bajo

  # --- Rutas (relativas al proyecto) ---
  crudo  = "datos/crudo",
  salida = "datos/salida"
)

dir.create(CONFIG$crudo,  recursive = TRUE, showWarnings = FALSE)
dir.create(CONFIG$salida, recursive = TRUE, showWarnings = FALSE)

message("Configuración cargada. Fuente: ", CONFIG$fuente)
