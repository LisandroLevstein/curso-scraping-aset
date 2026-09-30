# ============================================================
# WEB SCRAPING CON R
# Extracción de tablas e interacción con páginas web
# Ejemplo: CONICET en Cifras
#
# Objetivos:
# 1. Introducir la extracción de información de sitios web.
# 2. Identificar y extraer tablas HTML.
# 3. Comprender la diferencia entre páginas estáticas y dinámicas.
# 4. Interactuar con botones y selectores de una página web.
# 5. Automatizar la extracción de información mediante bucles.
# ============================================================


# ------------------------------------------------------------
# 1. CARGAR LAS BIBLIOTECAS
# ------------------------------------------------------------

# tidyverse reúne herramientas para manipular, transformar
# y visualizar datos.
#
# rvest permite leer páginas web, seleccionar elementos HTML
# y extraer información estructurada, como tablas.

library(tidyverse)
library(rvest)


# ------------------------------------------------------------
# 2. DEFINIR LA PÁGINA WEB
# ------------------------------------------------------------

# Guardamos la dirección de la página en un objeto.
# Esto permite reutilizarla sin escribir nuevamente la URL.

url <- "https://cifras.conicet.gov.ar/publica/detalle-tags/6"


# ------------------------------------------------------------
# 3. LEER EL HTML DE UNA PÁGINA WEB
# ------------------------------------------------------------

# read_html() descarga y analiza el código HTML de la página.
#
# IMPORTANTE:
# Esta función permite acceder al documento HTML, pero no
# interactúa con los botones ni ejecuta las acciones dinámicas
# que requieren la intervención del navegador.

html <- read_html(url)


# ------------------------------------------------------------
# 4. IDENTIFICAR Y EXTRAER TABLAS HTML
# ------------------------------------------------------------

# html_elements() permite seleccionar elementos del documento
# mediante selectores CSS.
#
# En este caso buscamos todos los elementos <table>.
# El resultado conserva la estructura HTML de las tablas,
# pero todavía no transforma su contenido en datos tabulares.

tabla <- html |> html_elements("table")


# html_table() identifica las tablas HTML y convierte
# su contenido en objetos tabulares de R.
#
# A diferencia de la instrucción anterior, aquí obtenemos
# directamente los datos organizados en filas y columnas.

tabla <- html |> html_table()


# ------------------------------------------------------------
# 5. TRABAJAR CON UNA PÁGINA WEB DINÁMICA
# ------------------------------------------------------------

# Algunas páginas permiten cambiar los datos mediante botones,
# seleccionar períodos o actualizar gráficos sin modificar
# la dirección de la página.
#
# read_html_live() abre la página en un navegador controlado
# desde R y permite interactuar con sus elementos.

html <- read_html_live(url)


# view() abre una representación visual de la página.
#
# Esto resulta útil para observar su estructura y comprobar
# las modificaciones realizadas mediante las interacciones.

html$view()


# ------------------------------------------------------------
# 6. INTERACTUAR CON BOTONES Y SELECTORES
# ------------------------------------------------------------

# click() simula un clic sobre un elemento de la página.
#
# El argumento es un selector CSS.
#
# El símbolo # indica que estamos seleccionando un elemento
# mediante su identificador HTML (atributo id).
#
# En este caso activamos el botón que permite mostrar
# los datos del gráfico en forma de tabla.

html$click("#table-button")


# También podemos interactuar con los selectores de años.
#
# En este sitio, cada año tiene una etiqueta HTML (label)
# asociada a un elemento mediante el atributo for.
#
# Seleccionamos primero el año 2024.

html$click("label[for='option-2024']")

# Activamos nuevamente el botón para mostrar la tabla
# correspondiente al año seleccionado.

html$click("#table-button")


# Repetimos el procedimiento para el año 2023.

html$click("label[for='option-2023']")
html$click("#table-button")


# ------------------------------------------------------------
# 7. EXTRAER LOS DATOS DESPUÉS DE INTERACTUAR
# ------------------------------------------------------------

# Como estamos trabajando con una página dinámica,
# podemos recuperar el contenido después de seleccionar
# los diferentes años.
#
# html_elements("table") identifica las tablas existentes.
#
# html_text() extrae su contenido textual, pero no conserva
# necesariamente su organización en filas y columnas.

html |> html_elements("table") |> html_text()


# html_table() convierte las tablas en objetos tabulares.
#
# [[1]] selecciona el primer elemento de la lista resultante,
# es decir, la primera tabla identificada.
#
# Por defecto, la función intenta convertir automáticamente
# los valores de las columnas a sus tipos correspondientes.

html_table(html)[[1]]


# Con convert = FALSE evitamos la conversión automática.
#
# Esta alternativa es especialmente importante cuando
# los datos utilizan el punto como separador de miles.
#
# Por ejemplo, una cifra escrita como 9.638 podría
# interpretarse incorrectamente como un número decimal
# si se aplica una conversión automática.

html_table(html, convert = FALSE)[[1]]


# ============================================================
# SEGUNDA PARTE
# AUTOMATIZACIÓN DE LA EXTRACCIÓN DE DATOS
# ============================================================


# ------------------------------------------------------------
# 8. ABRIR UNA NUEVA PÁGINA
# ------------------------------------------------------------

# Ahora trabajamos con otra página de CONICET en Cifras.
#
# El procedimiento es similar al anterior, pero esta vez
# automatizaremos la selección de los diferentes años.

html <- read_html_live("https://cifras.conicet.gov.ar/publica/detalle-tags/23")


# Visualizamos la página.

html$view()


# ------------------------------------------------------------
# 9. CONSTRUIR LOS SELECTORES DE LOS AÑOS
# ------------------------------------------------------------

# En lugar de escribir manualmente un selector para cada año,
# utilizamos paste0() para construirlos automáticamente.
#
# El operador : genera una secuencia de números enteros.
#
# 2016:2025 produce:
# 2016, 2017, 2018, ..., 2025.
#
# El primer paste0() agrega el prefijo option- a cada año.
#
# El segundo paste0() completa el selector CSS correspondiente
# a las etiquetas HTML asociadas a esos elementos.
#
# El resultado es un vector de diez selectores.

tags_clics <- paste0("label[for='", paste0("option-", 2016:2025), "']")


# ------------------------------------------------------------
# 10. INTRODUCCIÓN AL BUCLE FOR
# ------------------------------------------------------------

# Un bucle for permite repetir una operación para cada
# elemento de un vector.
#
# En este primer ejemplo recorremos los selectores CSS
# y los imprimimos en la consola.
#
# La variable i toma sucesivamente cada uno de los valores
# almacenados en tags_clics.

for (i in tags_clics) { print(i) }


# ------------------------------------------------------------
# 11. PREPARAR UN OBJETO PARA ALMACENAR LOS RESULTADOS
# ------------------------------------------------------------

# Creamos un objeto vacío en el que incorporaremos
# las tablas recuperadas durante el recorrido.
#
# La función c() sin argumentos genera un vector vacío.

tablas <- c()


# ------------------------------------------------------------
# 12. AUTOMATIZAR LA EXTRACCIÓN DE TABLAS
# ------------------------------------------------------------

# Este bucle combina las operaciones anteriores.
#
# Para cada año:
#
# 1. Espera un segundo.
# 2. Selecciona el año mediante un clic.
# 3. Espera un segundo.
# 4. Activa el botón que muestra la tabla.
# 5. Espera un segundo.
# 6. Extrae la primera tabla.
# 7. Incorpora su contenido al objeto tablas.
# 8. Espera un segundo.
# 9. Imprime el selector procesado.
#
# Las pausas introducidas mediante Sys.sleep() permiten
# dar tiempo al navegador para actualizar el contenido.
#
# Es importante recordar que los tiempos de carga
# pueden variar según la conexión y el servidor.

for (t in tags_clics) {
  Sys.sleep(1)
  html$click(t)
  Sys.sleep(1)
  html$click("#table-button")
  Sys.sleep(1)
  tablas <- append(tablas, html_table(html)[[1]])
  Sys.sleep(1)
  print(t)
}
