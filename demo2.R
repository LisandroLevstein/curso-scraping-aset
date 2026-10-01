library(rvest)
library(tibble)

url <- paste0("https://search.scielo.org/?q=trabajadores&lang=es&count=100&from=", 1:124)

indice_completo <- c()

tag <- '/html/body/section/div/div/div[1]/div[2]/div[3]/div/div[2]/div[1]/a'

for (u in url) {
  html <- read_html(u)
  Sys.sleep(2)
  pag <- html_attr(html_elements(html, xpath = tag), "href")
  indice_completo <- append(pag, indice_completo)
  cat(u, "\n\n")
}


url <- "https://search.scielo.org/?q=trabajadores&lang=es&count=100&from=1"

html_text2(html_elements(html, css = "strong.title"))

html_elements(html, xpath = '/html/body/section/div/div/div[1]/div[2]/div[3]/div/div[2]/div[1]/a') |> html_attr("href")

html <- read_html(url)
html_live <- read_html_live(url)

'/html/body/section/div/div/div[1]/div[2]/div[3]/div[2]/div[2]/div[1]/a'                                                      
'/html/body/section/div/div/div[1]/div[2]/div[3]/div[69]/div[2]/div[1]/a'

indice <- tibble(
  titulo = html_text2(html_elements(html_live, css = "strong.title")),
  url    = html_attr(html_elements(html_live, xpath = '/html/body/section/div/div/div[1]/div[2]/div[3]/div/div[2]/div[1]/a'), "href")
)

url_local <- "./Búsqueda _ SciELO.html"
html_local <- read_html(url_local)

indice_local <- tibble(
  titulo = html_text2(html_elements(html_local, "strong.title")),
  url    = html_attr(html_elements(html_local, xpath = '/html/body/section/div/div/div[1]/div[2]/div[3]/div/div[2]/div[1]/a'), "href")
)

html_text2(html_element(read_html(indice_local$url), ".title"))

html_text2(html_element(read_html(indice_local$url), ".body"))

tabla_articulos <- data.frame()

for (a in indice_local$url) {
  html <- read_html(a)
  articulo <- tibble(
    titulo = html_text2(html_element(html, ".title, .page_title, .article-title")),
    contenido = html_text2(html_element(html, ".body, .item.abstract, #articleText")),
    url = a
  )
  tabla_articulos <- rbind(articulo, tabla_articulos)
  Sys.sleep(5)
}

#######################################

url_wiki <- 'https://es.wikipedia.org/wiki/Poblaci%C3%B3n_mundial'

tablas <- read_html(url_wiki) |> html_elements("table.wikitable")

tablas[12] |> html_text()

df_tablas <- read_html(url_wiki) |> html_elements("table.wikitable") |> html_table()
