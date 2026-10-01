# -----------------------------------------------------------------------------
# Clase 3 · Script 3 — Un formulario de búsqueda real: convenios colectivos
#
# Qué hace:  consulta el buscador de convenios y acuerdos del Ministerio de
#            Trabajo (que funciona con POST) y arma una base de datos.
# Necesita:  httr2, rvest, dplyr, purrr, stringr, readr. Internet.
# Produce:   clase-03-iteracion-apis-dinamico/datos/salida/convenios-2024.csv
#            datos/crudo/convenios-2024-pagina-1-2026-10-01.html (respaldo)
# Duración:  cerca de un minuto (bajamos 3 páginas con pausas).
#
# Sitio:     https://convenios.trabajo.gob.ar/ConsultaWeb/consultaBasica.asp
#            Fuente pública del Ministerio de Trabajo. Su robots.txt solo
#            excluye la página de ayuda, así que la consulta está permitida.
#
# Este es el caso más parecido a lo que se van a encontrar en la vida real:
# un sistema viejo, con formulario POST y HTML imperfecto. Nada de sandbox.
# -----------------------------------------------------------------------------

library(httr2)
library(rvest)
library(dplyr)
library(purrr)
library(stringr)
library(readr)


# --- 1. GET no alcanza -------------------------------------------------------
# Hasta ahora todas las páginas se pedían con GET: la dirección lo dice todo.
# Acá no. El buscador manda los criterios por POST: van en el CUERPO del
# pedido, no en la URL. Por eso la dirección nunca cambia mientras buscás.
#
# ¿Cómo se descubre qué mandar? En el navegador:
#   F12 -> pestaña Network (Red) -> hacé la búsqueda a mano ->
#   clic en el pedido -> sección "Form Data" / "Payload".
#
# Ahí aparecen los campos. Muchos son de ESTADO INTERNO del sistema y no
# tienen nada que ver con tu búsqueda, pero hay que mandarlos igual porque
# el servidor los espera.

URL <- "https://convenios.trabajo.gob.ar/ConsultaWeb/consultaBasica.asp"


# --- 2. Una función que pide una página --------------------------------------
# Los campos que importan son tres:
#   Anio    -> el año que buscamos
#   Accion  -> "Buscar" la primera vez, "IrPagina" para las siguientes
#   Pagina  -> el número de página (empieza en 1, no en 0)
#
# El resto es el estado que el sistema necesita para no confundirse.

pedir_pagina <- function(anio, pagina = 1, por_pagina = 50) {

  accion <- if (pagina == 1) "Buscar" else "IrPagina"

  message("Año ", anio, " · página ", pagina)
  Sys.sleep(2)   # este es un servidor público y viejo: vamos despacio

  request(URL) |>
    req_user_agent("Curso ASET - web scraping con R (docencia)") |>
    req_body_form(
      # --- lo que buscamos ---
      Anio            = as.character(anio),
      Numero          = "",
      TipoDocumentoId = "",
      NivelId         = "",
      SubNivelId      = "",

      # --- cómo navegamos ---
      Accion          = accion,
      Pagina          = as.character(pagina),
      CantFilas       = as.character(por_pagina),

      # --- estado interno del sistema: se manda tal cual ---
      Tabla             = "DocumentoWeb",
      Modo              = "Consulta",
      AntModo           = "Consulta",
      AntAccion         = "Consultar",
      IsPostBack        = "1",
      Id                = "0",
      AtEof             = "0",
      CambiosPendientes = "False"
    ) |>
    req_perform() |>
    # Este sitio es anterior a UTF-8 y usa la codificación vieja.
    # Sin este argumento, los acentos y las eñes llegan rotos.
    resp_body_html(encoding = "ISO-8859-1")
}

# Poné TRUE si el servidor no responde. El respaldo fechado es la primera
# página capturada el 2026-10-01; en ese modo se procesa esa página (50 filas)
# y se omite la paginación en vivo.
usar_respaldo <- FALSE

archivo_respaldo <- "clase-03-iteracion-apis-dinamico/datos/crudo/convenios-2024-pagina-1-2026-10-01.html"

primera <- if (usar_respaldo) {
  read_html(archivo_respaldo, encoding = "ISO-8859-1")
} else {
  pedir_pagina(2024, 1)
}


# --- 3. Cuántos hay ----------------------------------------------------------
# El sitio lo dice en una frase. La sacamos con una expresión regular.

texto <- primera |> html_element("body") |> html_text2()

total <- texto |> str_extract("(?<=encontrado )[0-9]+") |> as.integer()
total

texto |> str_extract("Registros: [0-9]+-[0-9]+")

# Saber el total ANTES de iterar te deja calcular cuántas páginas vas a pedir,
# y decidir si el pedido es razonable o si conviene achicar la búsqueda.

paginas_totales <- ceiling(total / 50)
paginas_totales


# --- 4. Encontrar las filas --------------------------------------------------
# Cada resultado es una <table> con un atributo `numrow`. Ese atributo es
# el mejor selector posible: existe solo en las filas de resultado.

filas <- primera |> html_elements("table[numrow]")
length(filas)


# --- 5. El HTML está mal formado (y hay que verlo) ---------------------------
# Miremos cuántas celdas encuentra rvest en la primera fila y en la última:

length(filas[[1]]  |> html_elements("td.campos"))
length(filas[[50]] |> html_elements("td.campos"))

# 300 y 6. ¿Por qué?
#
# Porque el HTML del sitio tiene etiquetas sin cerrar. Al leerlo, el parser
# hace lo que puede: en vez de 50 tablas hermanas, arma 50 tablas ANIDADAS
# una dentro de otra. La primera contiene a todas las demás.
#
# Esto NO es un error tuyo ni de rvest. Es HTML roto, y es muy común en
# sistemas viejos. Lo importante es detectarlo antes de confiar en el dato.
#
# Por suerte hay un orden estable: las PRIMERAS 6 celdas de cada tabla
# siempre son las de su propia fila. Nos quedamos con esas.


# --- 6. Extraer --------------------------------------------------------------

extraer_fila <- function(fila) {
  celdas <- fila |>
    html_elements("td.campos") |>
    html_text2() |>
    str_squish()

  celdas <- celdas[1:6]   # las 6 propias, en orden

  tibble(
    documento = celdas[1],
    fecha     = celdas[2],
    actividad = celdas[3],
    sindicato = celdas[4],
    empleador = celdas[5],
    contenido = celdas[6]
  )
}

convenios <- map(filas, extraer_fila) |> list_rbind()

convenios |> select(documento, fecha, actividad) |> head(5)


# --- 7. Limpiar --------------------------------------------------------------

convenios <- convenios |>
  mutate(
    tipo   = str_extract(documento, "^[A-Z ]+(?= [0-9])"),
    numero = str_extract(documento, "[0-9]+(?=/)"),
    anio   = str_extract(documento, "(?<=/)[0-9]{4}"),
    fecha  = as.Date(fecha, format = "%d-%m-%Y")
  )

convenios |> count(tipo)


# --- 8. Recorrer varias páginas ----------------------------------------------
# Ya tenemos las dos piezas: pedir una página y extraer sus filas.
# Las juntamos y aplicamos el mismo patrón de iteración del script 1.

bajar_pagina <- function(anio, pagina) {
  pedir_pagina(anio, pagina) |>
    html_elements("table[numrow]") |>
    map(extraer_fila) |>
    list_rbind()
}

# Bajamos solo 3 páginas para no hacer esperar a la clase.
# Para bajar todo sería 1:paginas_totales, pero con 2 segundos de pausa
# eso son varios minutos. Está bien que tarde: no es una carrera.
# El respaldo local contiene solo la primera página: no simula las otras dos.

base <- if (usar_respaldo) {
  map(filas, extraer_fila) |> list_rbind()
} else {
  map(1:3, function(p) bajar_pagina(2024, p)) |> list_rbind()
}

nrow(base)
base |> count(actividad, sort = TRUE) |> head(8)


# --- 9. Guardar --------------------------------------------------------------

write_csv(base, "clase-03-iteracion-apis-dinamico/datos/salida/convenios-2024.csv")

cat("\n", nrow(base), "documentos guardados de", total, "disponibles para 2024.")
if (usar_respaldo) {
  cat(" Se usó el respaldo de la página 1 (captura 2026-10-01); no es la descarga de 3 páginas.\n")
} else {
  cat("\n")
}


# -----------------------------------------------------------------------------
# EJERCICIO
#
# 1. Cambiá el año y volvé a correr. Cuántos documentos hay para 2020?
# 2. Agregá el filtro TipoDocumentoId = "1" para traer solo convenios
#    colectivos (sin acuerdos). Cuántos quedan?
# 3. Bajá las 33 páginas de 2024 y guardá la base completa.
#    Antes de correrlo: 33 páginas x 2 segundos = poco más de un minuto.
#    Calculá siempre el costo antes de largar una recolección.
#
# DESAFÍO
#
# El boletín del Ministerio de Seguridad bonaerense
# (https://boletin.mseg.gba.gov.ar/NrosAnteriores.aspx) es un ASP.NET y usa
# un campo oculto llamado __VIEWSTATE que cambia en cada pedido.
# Ahí no alcanza con mandar los campos fijos: hay que LEER el VIEWSTATE de
# la respuesta anterior y devolverlo en el pedido siguiente.
# Es el mismo principio de este script, un escalón más arriba.
# -----------------------------------------------------------------------------
