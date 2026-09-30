# ============================================================
# WEB SCRAPING CON R
# Extracción de enlaces desde resultados de búsqueda en SciELO
#
# Objetivos:
# 1. Realizar solicitudes HTTP desde R.
# 2. Simular una petición realizada por un navegador.
# 3. Construir múltiples URL de búsqueda.
# 4. Recorrer páginas de resultados mediante un bucle.
# 5. Extraer enlaces mediante XPath.
# 6. Acumular los resultados obtenidos.
# ============================================================


# ------------------------------------------------------------
# 1. CARGAR LAS BIBLIOTECAS
# ------------------------------------------------------------

# httr2 permite realizar solicitudes HTTP.
#
# Lo utilizamos para enviar una petición al servidor,
# agregar encabezados, definir un User-Agent, establecer
# tiempos máximos de espera y recuperar la respuesta.
#
# rvest permite analizar el HTML recibido y extraer
# elementos específicos de una página web.

library(httr2)
library(rvest)


# ------------------------------------------------------------
# 2. DEFINIR UN USER-AGENT
# ------------------------------------------------------------

# Un User-Agent es una cadena de texto que identifica
# al programa que realiza una solicitud web.
#
# Los navegadores envían automáticamente esta información
# cuando visitamos una página.
#
# En este caso utilizamos un User-Agent semejante al de
# Google Chrome sobre Windows.
#
# Esto permite que la solicitud realizada desde R tenga
# características similares a una petición de navegador.

ua <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"


# ------------------------------------------------------------
# 3. CONSTRUIR LAS URL DE BÚSQUEDA
# ------------------------------------------------------------

# La búsqueda corresponde al término "trabajadores"
# en el buscador de SciELO.
#
# La URL contiene distintos parámetros:
#
# q=trabajadores
#     término de búsqueda.
#
# lang=es
#     idioma de la interfaz.
#
# count=100
#     cantidad de resultados solicitados.
#
# from=
#     indica desde qué posición comenzar a mostrar resultados.
#
# paste0() concatena la parte fija de la URL con una
# secuencia de números.
#
# En este caso se generan 124 direcciones diferentes.

url <- paste0("https://search.scielo.org/?q=trabajadores&lang=es&count=100&from=", 1:124)


# ------------------------------------------------------------
# 4. OTRA FORMA POSIBLE DE CONSTRUIR LAS URL
# ------------------------------------------------------------

# Esta línea está comentada y no se ejecuta.
#
# seq() permite construir secuencias numéricas especificando:
#
# 1        = valor inicial.
# by = 100 = incremento entre valores.
# length.out = 124 = cantidad de valores.
#
# Esta variante generaría:
#
# 1, 101, 201, 301, ...
#
# y puede utilizarse cuando el parámetro "from" representa
# la posición del primer resultado de cada página.

# paste0("https://search.scielo.org/?q=trabajadores&lang=es&count=100&from=", seq(1, by = 100, length.out = 124))


# ------------------------------------------------------------
# 5. CREAR UN OBJETO PARA ACUMULAR RESULTADOS
# ------------------------------------------------------------

# Creamos un objeto vacío.
#
# A medida que recorramos las páginas, iremos agregando
# los enlaces encontrados en cada una.

indice_completo <- c()


# ------------------------------------------------------------
# 6. DEFINIR EL ELEMENTO QUE QUEREMOS EXTRAER
# ------------------------------------------------------------

# Guardamos en el objeto tag una expresión XPath.
#
# XPath permite localizar elementos dentro de la estructura
# jerárquica de un documento HTML.
#
# En este caso, la expresión apunta al elemento <a>
# que contiene el enlace de interés dentro de cada resultado.

tag <- "/html/body/section/div/div/div[1]/div[2]/div[3]/div/div[2]/div[1]/a"


# ------------------------------------------------------------
# 7. RECORRER TODAS LAS URL
# ------------------------------------------------------------

# El bucle for toma, una por una, todas las direcciones
# almacenadas en el vector url.
#
# En cada iteración:
#
# 1. Espera dos segundos.
# 2. Realiza una solicitud HTTP.
# 3. Agrega encabezados semejantes a los de un navegador.
# 4. Descarga el HTML.
# 5. Busca los enlaces mediante XPath.
# 6. Extrae el atributo href.
# 7. Incorpora los enlaces al índice completo.
# 8. Imprime en pantalla la URL procesada.

for (u in url) {
  
  
  # ----------------------------------------------------------
  # 7.1. PAUSA ENTRE SOLICITUDES
  # ----------------------------------------------------------
  
  # Sys.sleep() detiene temporalmente la ejecución.
  #
  # En este caso esperamos dos segundos antes de realizar
  # cada nueva solicitud.
  #
  # Esto reduce la velocidad de las consultas al servidor.
  
  Sys.sleep(2)
  
  
  # ----------------------------------------------------------
  # 7.2. REALIZAR LA SOLICITUD HTTP
  # ----------------------------------------------------------
  
  # request(u) crea una solicitud dirigida a la URL
  # correspondiente a la iteración actual.
  #
  # El operador |> permite encadenar sucesivamente
  # las distintas configuraciones de la solicitud.
  
  html <- request(u) |>
    
    
    # --------------------------------------------------------
  # USER-AGENT
  # --------------------------------------------------------
  
  # Agregamos el User-Agent definido anteriormente.
  
  req_user_agent(ua) |>
    
    
    # --------------------------------------------------------
  # ENCABEZADOS HTTP
  # --------------------------------------------------------
  
  # req_headers() permite agregar otros encabezados.
  #
  # Accept indica qué tipos de documentos puede recibir
  # el cliente.
  #
  # Accept-Language indica los idiomas preferidos.
  
  req_headers(
    Accept = "text/html,application/xhtml+xml",
    `Accept-Language` = "es-AR,es;q=0.9"
  ) |>
    
    
    # --------------------------------------------------------
  # TIEMPO MÁXIMO DE ESPERA
  # --------------------------------------------------------
  
  # Si el servidor tarda más de 30 segundos en responder,
  # la solicitud se interrumpe.
  
  req_timeout(30) |>
    
    
    # --------------------------------------------------------
  # EJECUTAR LA SOLICITUD
  # --------------------------------------------------------
  
  # req_perform() envía efectivamente la solicitud
  # al servidor.
  
  req_perform() |>
    
    
    # --------------------------------------------------------
  # CONVERTIR LA RESPUESTA EN HTML
  # --------------------------------------------------------
  
  # resp_body_html() toma el cuerpo de la respuesta
  # y lo transforma en un documento HTML que puede
  # ser procesado con rvest.
  
  resp_body_html()
  
  
  # ----------------------------------------------------------
  # 7.3. LOCALIZAR LOS ENLACES
  # ----------------------------------------------------------
  
  # html_elements() busca todos los elementos que coinciden
  # con la expresión XPath almacenada en tag.
  #
  # html_attr(..., "href") extrae el valor del atributo href
  # de cada enlace encontrado.
  #
  # El resultado es un vector con las direcciones
  # correspondientes a los registros recuperados.
  
  pag <- html_attr(html_elements(html, xpath = tag), "href")
  
  
  # ----------------------------------------------------------
  # 7.4. ACUMULAR LOS RESULTADOS
  # ----------------------------------------------------------
  
  # append() agrega los enlaces encontrados en esta página
  # al objeto indice_completo.
  #
  # Al finalizar el bucle, indice_completo contendrá
  # los enlaces recuperados de todas las páginas recorridas.
  
  indice_completo <- append(pag, indice_completo)
  
  
  # ----------------------------------------------------------
  # 7.5. MOSTRAR EL AVANCE
  # ----------------------------------------------------------
  
  # cat() imprime en la consola la URL que acaba
  # de procesarse.
  #
  # "\n\n" agrega dos saltos de línea para separar
  # visualmente cada iteración.
  
  cat(u, "\n\n")
}
