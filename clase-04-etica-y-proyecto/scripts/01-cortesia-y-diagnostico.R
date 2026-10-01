# -----------------------------------------------------------------------------
# Clase 4 · Script 1 — Cortesía técnica y diagnóstico
#
# Qué hace:  muestra cómo pedir páginas de forma responsable y cómo leer lo
#            que un sitio te está contestando cuando no te deja pasar.
# Necesita:  httr2, rvest, dplyr, purrr. Internet.
# Produce:   clase-04-etica-y-proyecto/datos/salida/diagnostico-sitios.csv
# Duración:  menos de un minuto.
# -----------------------------------------------------------------------------

library(dplyr)
library(purrr)
library(readr)
library(stringr)

# Cargamos las funciones compartidas del curso.
source("comun/R/funciones-cortesia.R")


# --- 1. Las cuatro cortesías -------------------------------------------------
# Abrí comun/R/funciones-cortesia.R y mirá la función descargar().
# Hace cuatro cosas que ningún tutorial hace, y que evitan casi todos
# los bloqueos:
#
#   1. Se IDENTIFICA con un User-Agent que dice quién sos y cómo contactarte.
#   2. Espera entre pedido y pedido.
#   3. Reintenta con paciencia si el servidor tarda.
#   4. Guarda una copia local, así nunca pide dos veces lo mismo.
#
# La cuarta es la más importante y la que menos se usa. Cada pedido que no
# hacés es carga que no le ponés a un servidor que no es tuyo.

pagina <- descargar(
  "https://quotes.toscrape.com/",
  cache = "clase-04-etica-y-proyecto/datos/crudo",
  pausa = 1
)

# Corré la misma línea otra vez. Fijate en el mensaje: dice [cache].
# No salió a la red.

pagina <- descargar(
  "https://quotes.toscrape.com/",
  cache = "clase-04-etica-y-proyecto/datos/crudo",
  pausa = 1
)


# --- 2. Leer lo que el sitio contesta ----------------------------------------
# Un código de estado no es un obstáculo técnico a esquivar. Es un mensaje.
# La función diagnosticar() lo traduce.

sitios <- c(
  "https://quotes.toscrape.com/",
  "https://www.eldia.com/",
  "https://datos.gob.ar/api/3/action/package_search?q=empleo&rows=1",
  "https://convenios.trabajo.gob.ar/ConsultaWeb/consultaBasica.asp",
  "https://www.zonajobs.com.ar/robots.txt",
  "https://ar.computrabajo.com/robots.txt"
)

diagnostico <- map(sitios, diagnosticar) |>
  map(as_tibble) |>
  list_rbind()

diagnostico |> select(codigo, url)


# --- 3. El caso computrabajo -------------------------------------------------
# Mirá la última fila: 403.
#
# No es que falte un User-Agent, ni que haga falta esperar más. El sitio
# devuelve 403 hasta para su propio robots.txt: no atiende programas
# automáticos, punto. Es una decisión suya, y está en su derecho.
#
# Insistir con más técnica ahí es empujar una puerta cerrada. Frágil,
# caro, y difícil de justificar en un informe de investigación.
#
# Ahora mirá zonajobs, dos filas más arriba: 200.

# Pedimos formato = "texto" porque robots.txt no es HTML: es texto plano.
reglas <- descargar(
  "https://www.zonajobs.com.ar/robots.txt",
  cache   = "clase-04-etica-y-proyecto/datos/crudo",
  pausa   = 1,
  formato = "texto"
)

cat(reglas)

# Ese archivo hace dos cosas:
#   - Dice qué rutas prefiere que no recorras (Disallow).
#   - Y publica sus SITEMAPS: listados de URLs que el propio sitio ofrece
#     para que los programas los recorran.
#
# Mismo rubro, mismo dato, dos respuestas opuestas. Elegir bien la fuente
# es parte del método, no un detalle técnico.

sitemaps <- str_extract_all(reglas, "https?://[^\\s]+\\.xml")[[1]]
sitemaps


# --- 4. robots.txt: qué es y qué no es ---------------------------------------
# NO es una ley. NO es un candado técnico. Es una declaración de intención
# del sitio sobre qué le gustaría que los programas automáticos no recorran.
#
# Ignorarlo es una decisión que se puede tomar, pero hay que poder
# justificarla — ante un comité de ética, ante un revisor, ante vos.
#
# Cuatro preguntas antes de ignorar un Disallow:
#   1. ¿Hay otra forma de conseguir el dato? (API, datos abiertos, pedido formal)
#   2. ¿El dato es indispensable para la pregunta de investigación?
#   3. ¿La carga que genero es despreciable para ese servidor?
#   4. ¿Podría explicar públicamente lo que hice, y sostenerlo?
#
# Si alguna respuesta es "no", no es un problema técnico. Es otro problema.


# --- 5. Guardar el diagnóstico -----------------------------------------------
# Vale la pena guardarlo: es documentación del estado de tus fuentes
# en una fecha determinada. En seis meses te vas a acordar de por qué
# descartaste un sitio.

diagnostico <- diagnostico |>
  mutate(fecha = Sys.Date())

write_csv(diagnostico, "clase-04-etica-y-proyecto/datos/salida/diagnostico-sitios.csv")

cat("\nDiagnóstico de", nrow(diagnostico), "sitios guardado.\n")


# -----------------------------------------------------------------------------
# EJERCICIO
#
# 1. Agregá a la lista `sitios` la fuente de TU investigación y corré de nuevo.
# 2. Leé su robots.txt completo. ¿Menciona algún sitemap?
# 3. Si te da 403 o 429: ¿qué alternativa tenés? Anotala. Es la tarea de hoy.
# -----------------------------------------------------------------------------
