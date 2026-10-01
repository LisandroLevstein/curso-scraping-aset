# -----------------------------------------------------------------------------
# Clase 4 · Script 2 — De CSV a base de datos
#
# Qué hace:  guarda lo recolectado en las clases anteriores en una base
#            SQLite y muestra cómo consultarla sin cargarla entera a memoria.
# Necesita:  DBI, RSQLite, dplyr, readr. NO necesita internet.
# Produce:   clase-04-etica-y-proyecto/datos/salida/corpus.sqlite
# Duración:  segundos.
#
# Requisito: haber corrido los scripts de las clases 2 y 3, que dejan
#            los CSV que acá vamos a cargar.
# -----------------------------------------------------------------------------

library(DBI)
library(RSQLite)
library(dplyr)
library(readr)


# --- 1. Por qué una base y no CSV --------------------------------------------
# El CSV está perfecto hasta que deja de estarlo. Deja de estarlo cuando:
#
#   - El archivo no entra cómodo en memoria.
#   - Recolectás todos los días y querés agregar sin releer todo.
#   - Necesitás cruzar dos tablas.
#   - Querés evitar duplicados de forma confiable.
#
# SQLite es una base de datos entera dentro de UN archivo. No hay servidor,
# no hay usuario, no hay contraseña. Lo copiás con Ctrl+C. Para un corpus
# de investigación es exactamente lo que hace falta.

archivo_base <- "clase-04-etica-y-proyecto/datos/salida/corpus.sqlite"

con <- dbConnect(SQLite(), archivo_base)


# --- 2. Guardar tablas -------------------------------------------------------

notas <- read_csv("clase-02-rvest-estaticas/datos/salida/eldia-notas.csv",
                  show_col_types = FALSE)

dbWriteTable(con, "notas", notas, overwrite = TRUE)

convenios <- read_csv("clase-03-iteracion-apis-dinamico/datos/salida/convenios-2024.csv",
                      show_col_types = FALSE)

dbWriteTable(con, "convenios", convenios, overwrite = TRUE)

dbListTables(con)


# --- 3. Consultar sin cargar todo --------------------------------------------
# tbl() no trae los datos: arma la consulta y la deja preparada.
# dplyr la traduce a SQL y la base hace el trabajo pesado.

tabla_convenios <- tbl(con, "convenios")

resumen <- tabla_convenios |>
  count(actividad, sort = TRUE) |>
  head(10)

# Todavía no se ejecutó nada. Podés mirar el SQL que se va a mandar:
resumen |> show_query()

# collect() es el que trae los datos a R.
resumen |> collect()

# La diferencia importa cuando la tabla tiene millones de filas: filtrás y
# agrupás dentro de la base, y traés solo el resultado.


# --- 4. Agregar sin duplicar -------------------------------------------------
# El caso real: corrés el scraper todos los días y querés sumar lo nuevo
# sin repetir lo viejo.
#
# append = TRUE agrega al final en vez de reemplazar.

nuevas <- notas |> head(3)

dbWriteTable(con, "notas", nuevas, append = TRUE)

tbl(con, "notas") |> count() |> collect()   # sumó 3 filas repetidas

# Las quitamos con distinct(). Por eso conviene guardar SIEMPRE un
# identificador estable de cada registro: acá es la columna `id`.

limpias <- tbl(con, "notas") |> collect() |> distinct(id, .keep_all = TRUE)

dbWriteTable(con, "notas", limpias, overwrite = TRUE)

tbl(con, "notas") |> count() |> collect()

# Con un id estable, un registro duplicado es un problema de dos líneas.
# Sin id, es un problema de tarde entera.


# --- 5. Cerrar ---------------------------------------------------------------
# Cerrá siempre la conexión. Si no, el archivo puede quedar bloqueado.

dbDisconnect(con)

cat("\nBase guardada en", archivo_base, "\n")
cat("Tamaño:", round(file.size(archivo_base) / 1024, 1), "KB\n")


# -----------------------------------------------------------------------------
# EJERCICIO
#
# 1. Agregá a la base el CSV de citas de la clase 3.
# 2. Contá cuántos convenios hay por año usando tbl() + count() + collect().
# 3. Abrí el archivo .sqlite con DB Browser for SQLite (https://sqlitebrowser.org)
#    y mirá tus datos sin escribir una línea de código.
# -----------------------------------------------------------------------------
