################################################################################
library(rvest)
library(purrr)
library(dplyr)
library(stringr)
library(tibble)

# usethis::edit_r_environ()
url <- 'https://www.facebook.com/groups/HospitalRegioMAL/'
html <- read_html_live(url)
html$view()
html$type("input[name='email']", Sys.getenv("FB_USER"))
html$type("input[name='pass']", Sys.getenv("FB_PASS"))
html$click("#login_form div[role='button'][aria-label='Iniciar sesión']")
html$html_elements('[data-ad-rendering-role="story_message"]') |> html_text2()

html$scroll_by(top = 1500)
Sys.sleep(1)
html$html_elements(xpath=tag) |> html_text()

################################################################################

expandir <- function(x) {
  x$session$Runtime$evaluate("
    document.querySelectorAll('div[role=\"button\"]').forEach(b => {
      if (b.innerText.trim() === 'Ver más') b.click();
    });
  ")
  Sys.sleep(1)
  invisible(x)
}

leer_feed <- function(x) {
  x$html_elements('div[role="feed"] > div') |>
    html_element('[data-ad-rendering-role="story_message"]') |>
    html_text2() |>
    str_trim() |>
    discard(\(t) is.na(t) || t == "")
}

una_vuelta <- function(x, vuelta) {
  expandir(x)
  res <- tibble(vuelta = vuelta, texto = leer_feed(x))
  message("Vuelta ", vuelta, ": ", nrow(res), " posts visibles")
  x$scroll_by(top = 1500)
  Sys.sleep(runif(1, 2, 4))
  res
}

posts <- tibble(vuelta = integer(), texto = character())

posts <- bind_rows(posts, map(7:20, una_vuelta, x = html) |> list_rbind()) |>
  distinct(texto, .keep_all = TRUE)

posts
