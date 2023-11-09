## N.B. Country codes correspond to the `ecb` column of countrycode::codelist

library(dplyr)
library(purrr)
library(readr)
library(stringr)
library(tidyr)

votes <-
  read_csv(
    "data-raw/votes.dat",
    col_types =
      cols(
        year = col_integer(),
        round = col_character(),
        from_country = col_character(),
        to_country = col_character(),
        total_points = col_integer(),
        tele_points = col_integer(),
        jury_points = col_integer()
      )
  ) |>
  transmute(
    year,
    round,
    from_country = str_to_upper(from_country),
    to_country = str_to_upper(to_country),
    total_points = total_points,
    televoting_points = tele_points,
    jury_points = jury_points
  ) |>
  filter(to_country != from_country)

write_csv(votes, "data/CSV/votes.csv")
saveRDS(votes, file = "data/RDA/votes.rda")
