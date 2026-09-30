# -----------------------------------------------------------------------------
# Clase 3 · Script 4 — Páginas que arma JavaScript (demostración)
#
# Qué hace:  muestra qué pasa cuando el contenido no viene en el HTML, y las
#            dos formas de resolverlo.
# Necesita:  rvest, jsonlite, dplyr, stringr. Para la parte 3, chromote y
#            un Chrome instalado. Internet.
# Produce:   clase-03-iteracion-apis-dinamico/datos/salida/citas-js.csv
# Duración:  medio minuto.
#
# Este script es una DEMOSTRACIÓN: lo corre el docente en clase. Si chromote
# no te instaló, podés seguir igual: la parte 2 no lo necesita, y es la que
# más te va a servir en la práctica.
# -----------------------------------------------------------------------------

library(rvest)
library(dplyr)
library(stringr)
library(jsonlite)
library(readr)


# --- 1. El problema ----------------------------------------------------------
# Esta página se ve idéntica a la del script 1 en el navegador.
# Pero está armada de otra forma: el HTML llega vacío y el contenido lo
# construye JavaScript dentro de tu navegador.
#
# R no ejecuta JavaScript. R baja el HTML y lo lee. Nada más.

pagina <- read_html("https://quotes.toscrape.com/js/")

pagina |> html_elements("div.quote") |> length()

# Cero. En el navegador ves diez citas; R ve ninguna.
#
# Cómo detectarlo antes de perder una tarde: en el navegador, botón derecho ->
# "Ver código fuente de la página" (NO "Inspeccionar"). El código fuente es
# lo que recibe R. El inspector muestra la página YA armada por JavaScript.
# Si tu dato está en el inspector pero no en el código fuente, es este caso.


# --- 2. La salida elegante: buscar el dato en el propio HTML -----------------
# Antes de sacar la artillería pesada, mirá el código fuente completo.
# Muchas veces el dato SÍ está: viene adentro de una etiqueta <script>,
# como un bloque de JSON, esperando que JavaScript lo dibuje.

scripts <- pagina |> html_elements("script") |> html_text()

# Buscamos el bloque que contiene los datos.
bloque <- scripts[str_detect(scripts, "var data")]

substr(bloque, 1, 120)

# Ahí está. Ahora recortamos solo el arreglo que sigue a "var data = ",
# hasta el corchete que lo cierra.
#
#   (?s)              el punto también toma saltos de línea
#   (?<=var data = )  arranca después de ese texto, sin incluirlo
#   \\[.*?\\]           del corchete que abre al primero que cierra
#   (?=;)             y que esté seguido de un punto y coma
#
# El signo de pregunta en .*? es la clave: sin él la expresión se estira
# hasta el ÚLTIMO corchete del archivo y se lleva código JavaScript de regalo.

json_texto <- bloque |>
  str_extract("(?s)(?<=var data = )\\[.*?\\](?=;)")

citas <- fromJSON(json_texto)

nrow(citas)
citas$text[1]
citas$author$name[1]

# Sin navegador, sin esperas, sin dependencias nuevas. Y es más rápido y
# más estable que renderizar la página entera.
#
# Regla práctica: cuando una página parece "dinámica", revisá primero
# el código fuente y la pestaña Network del navegador. En la mayoría de los
# casos vas a encontrar el JSON crudo, que es mejor dato que el HTML.

resultado <- tibble(
  cita  = citas$text,
  autor = citas$author$name
)

resultado |> head(3)


# --- 3. La artillería pesada: chromote --------------------------------------
# Cuando el dato NO está en el HTML de ninguna forma, hay que abrir un
# navegador de verdad, dejar que ejecute el JavaScript, y recién ahí leer.
#
# chromote controla un Chrome sin ventana visible.
# Es potente, pero tiene un costo: es lento, consume memoria y se rompe
# más seguido. Usalo como último recurso, no como primera opción.

if (requireNamespace("chromote", quietly = TRUE)) {

  navegador <- chromote::ChromoteSession$new()

  navegador$Page$navigate("https://quotes.toscrape.com/js/")
  navegador$Page$loadEventFired()
  Sys.sleep(2)                       # darle tiempo a que JavaScript termine

  # Le pedimos el HTML YA ARMADO, no el original.
  html_renderizado <- navegador$Runtime$evaluate(
    "document.documentElement.outerHTML"
  )$result$value

  navegador$close()

  renderizado <- read_html(html_renderizado)

  cat("Citas con chromote:",
      length(html_elements(renderizado, "div.quote")), "\n")

} else {
  cat("chromote no está instalado. La parte 2 alcanza para este caso.\n")
}


# --- 4. Guardar --------------------------------------------------------------

write_csv(resultado, "clase-03-iteracion-apis-dinamico/datos/salida/citas-js.csv")

cat("\n", nrow(resultado), "citas guardadas (extraídas del JSON, sin navegador).\n")


# -----------------------------------------------------------------------------
# PARA PENSAR
#
# Las tres opciones frente a una página dinámica, de mejor a peor:
#
#   1. Hay una API pública          -> usala (script 2 de hoy)
#   2. El JSON está en el HTML      -> extraelo (parte 2 de este script)
#   3. No queda otra                -> renderizá con chromote (parte 3)
#
# La opción 3 es la que más aparece en los tutoriales y la que menos
# conviene. Es lenta, frágil y cara. Antes de llegar ahí, agotá las otras dos.
#
# Y hay una cuarta que no es técnica: escribirle al organismo y pedir los
# datos. Más de una vez te los mandan en un CSV, mejor y más completos.
# -----------------------------------------------------------------------------
