# -----------------------------------------------------------------------------
# Clase 4 · Script 3 — Un pipeline reproducible
#
# Qué hace:  recolecta, limpia y guarda en una sola corrida, dejando registro
#            de cuándo se hizo y qué salió.
# Necesita:  rvest, dplyr, stringr, readr, DBI, RSQLite. Internet.
# Produce:   datos/salida/corpus.sqlite  (tabla `notas_diarias`)
#            datos/salida/registro.csv   (bitácora de corridas)
# Duración:  segundos.
#
# Este es el script que corrés todos los días. La diferencia con los
# anteriores no es técnica: es que está pensado para ejecutarse SOLO,
# muchas veces, y dejar rastro de lo que hizo.
# -----------------------------------------------------------------------------

library(rvest)
library(dplyr)
library(stringr)
library(readr)
library(DBI)
library(RSQLite)

source("comun/R/funciones-cortesia.R")


# =============================================================================
# CONFIGURACIÓN — lo único que se toca
# =============================================================================
# Todo lo que puede cambiar va arriba, junto y con nombre.
# Si mañana querés otro diario u otra carpeta, cambiás acá y nada más.

CONFIG <- list(
  fuente     = "https://www.eldia.com/",
  medio      = "El Día",
  selector   = "article.nota",
  carpeta    = "clase-04-etica-y-proyecto/datos",
  base       = "clase-04-etica-y-proyecto/datos/salida/corpus.sqlite",
  bitacora   = "clase-04-etica-y-proyecto/datos/salida/registro.csv",
  pausa      = 2
)

momento <- Sys.time()


# =============================================================================
# PASO 1 — Recolectar
# =============================================================================
# Usamos la función con cortesía: identidad, pausa, reintentos y copia local.

message("\n[1/4] Recolectando de ", CONFIG$medio)

pagina <- descargar(
  CONFIG$fuente,
  cache = file.path(CONFIG$carpeta, "crudo"),
  pausa = CONFIG$pausa
)

if (is.null(pagina)) {
  stop("No se pudo descargar la fuente. Revisá el diagnóstico del script 1.")
}


# =============================================================================
# PASO 2 — Extraer
# =============================================================================
# Misma técnica de la clase 2: primero la unidad, después los campos.

message("[2/4] Extrayendo")

bloques <- pagina |> html_elements(CONFIG$selector)

notas <- tibble(
  titulo = bloques |> html_element(".nota__titulo-item")   |> html_text2(),
  copete = bloques |> html_element(".nota__introduccion")  |> html_text2(),
  enlace = bloques |> html_element(".nota__titulo-item a") |> html_attr("href")
)


# =============================================================================
# PASO 3 — Limpiar
# =============================================================================
# Las dos columnas del final son las que hacen reproducible al corpus:
# de dónde salió cada registro y cuándo se recolectó.
#
# Sin fecha de recolección, dentro de seis meses no vas a poder decir
# qué había en esa portada. Con fecha, tu base es una serie temporal.

message("[3/4] Limpiando")

notas <- notas |>
  mutate(
    titulo  = str_squish(titulo),
    copete  = str_squish(copete),
    enlace  = paste0("https://www.eldia.com", enlace),
    seccion = str_extract(enlace, "(?<=eldia[.]com/)[^/]+"),
    id      = str_extract(enlace, "[0-9]+$"),

    medio        = CONFIG$medio,
    recolectado  = as.character(momento)
  ) |>
  filter(!is.na(titulo), titulo != "") |>
  distinct(id, .keep_all = TRUE)


# =============================================================================
# PASO 4 — Guardar
# =============================================================================
# append = TRUE suma lo de hoy sin borrar lo de ayer.
# Después quitamos duplicados por id, que es estable entre corridas.

message("[4/4] Guardando")

con <- dbConnect(SQLite(), CONFIG$base)

existe <- "notas_diarias" %in% dbListTables(con)

dbWriteTable(con, "notas_diarias", notas, append = existe, overwrite = !existe)

# Deduplicar: si corrés esto dos veces el mismo día, las notas repetidas
# no se acumulan.
todo <- tbl(con, "notas_diarias") |> collect() |> distinct(id, .keep_all = TRUE)
dbWriteTable(con, "notas_diarias", todo, overwrite = TRUE)

total_acumulado <- nrow(todo)

dbDisconnect(con)


# =============================================================================
# BITÁCORA
# =============================================================================
# Una línea por corrida. Es lo que te va a salvar cuando, dentro de tres
# meses, algo se rompa y tengas que reconstruir qué pasó y cuándo.

entrada <- tibble(
  momento         = as.character(momento),
  fuente          = CONFIG$fuente,
  recolectadas    = nrow(notas),
  total_acumulado = total_acumulado,
  duracion_seg    = round(as.numeric(difftime(Sys.time(), momento, units = "secs")), 1)
)

if (file.exists(CONFIG$bitacora)) {
  write_csv(entrada, CONFIG$bitacora, append = TRUE)
} else {
  write_csv(entrada, CONFIG$bitacora)
}

cat("\n-----------------------------------------\n")
cat("Recolectadas hoy: ", nrow(notas), "\n")
cat("Total acumulado:  ", total_acumulado, "\n")
cat("Duración:         ", entrada$duracion_seg, "segundos\n")
cat("-----------------------------------------\n")


# -----------------------------------------------------------------------------
# LO QUE HACE QUE ESTO SEA REPRODUCIBLE
#
#   1. Configuración arriba, en un solo lugar y con nombres claros.
#   2. Rutas relativas al proyecto. Funciona en cualquier computadora.
#   3. Pasos numerados que avisan por dónde van.
#   4. Cada registro guarda su fuente y su fecha de recolección.
#   5. Un id estable permite correrlo mil veces sin duplicar.
#   6. Una bitácora que deja rastro de cada corrida.
#
# Ninguna de las seis es difícil. Las seis juntas son la diferencia entre
# un script que anduvo una vez y un pipeline del que podés dar cuenta.
#
#
# QUÉ HACER CUANDO EL SITIO CAMBIA
#
# Va a pasar. No es una posibilidad, es cuestión de tiempo.
#
#   - Síntoma: el script corre sin error pero devuelve 0 filas, o filas vacías.
#     Por eso el paso 4 imprime cuántas recolectó: un cero salta a la vista.
#   - Primer paso: abrí el sitio y volvé a inspeccionar el selector.
#   - Segundo paso: cambialo en CONFIG y en el paso 2. Nada más.
#   - Tercero: anotá en la bitácora qué cambió y cuándo. Tu yo futuro
#     va a necesitar saber que el corpus tiene una costura ahí.
#
# Por eso los selectores viven en un solo lugar y no repartidos por todo
# el código: para que arreglarlo sea cambiar una línea, no diez.
# -----------------------------------------------------------------------------
