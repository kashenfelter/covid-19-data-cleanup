library(tidyverse)
library(gh)

cases <- gh("GET /repos/:owner/:repo/contents/:path",
            owner = "CSSEGISandData",
            repo = "2019-nCoV",
            path = "/daily_case_updates",
            branch = "master")

cases_df <- cases %>%
  unlist() %>%
  matrix(ncol = 12, byrow = T) %>%
  as_tibble() %>%
  rename(
    name = V1,
    path = V2,
    sha = V3,
    size = V4,
    url = V5,
    html_url = V6,
    git_url = V7,
    download_url = V8,
    type = V9,
    link_self = V10,
    link_git = V11,
    link_html = V12
  ) %>%
  filter(
    str_detect(name, "\\.csv")
  )

raw_data <- list()

# for (r in cases_df$download_url) {
#   fn = r
#   localfn = paste0("data/raw/", basename(r))
#   download.file(fn, destfile = localfn)
# }

get_data <- function(csv) {
  fname <- csv
  ts <- basename(fname) %>%
    str_remove(".csv") %>%
    str_replace("_", " ") %>%
    strptime(format = "%m-%d-%Y %H%M") %>%
    strftime()
  # parse only first 6 columns
  col_spec <- list(
    province_state = col_character(),
    country_region = col_character(),
    update = col_character(),
    confirmed = col_integer(),
    dead = col_integer(),
    recovered = col_integer()
  )
  read_csv(fname,
           col_types = col_spec, skip = 1,
           col_names = names(col_spec)) %>%
    mutate(
      update = ts
    )
}

cases_raw <- data.frame()

for (fn in cases_df$download_url) {
  d <- get_data(fn)
  cases_raw <- bind_rows(cases_raw, d)
}

cases_raw <- cases_raw %>%
  select(
    country_region,
    province_state,
    confirmed,
    dead,
    recovered,
    update
  )

saveRDS(
  cases_raw,
  file = "data/2019ncov_cases_raw.rds"
)