library(dplyr)
library(readr)
library(countrycode)

# TODO: What to do about qualify vs. win?

contestants <- readRDS("data/RDA/contestants.rda")

bookmakers <-
  read_csv(
    "data-raw/bookmakers.dat",
    col_types = "-icdicc-cc-"
  ) |>
  left_join(contestants |> select(year, performer, song, country)) |>
  mutate(
    country =
      if_else(
        is.na(country),
        countrycode(country_name, "country.name", "ecb"),
        country
      )
  ) |>
  distinct(year, contest_round, country, betting_name, betting_score) |>
  arrange(year, contest_round, country, betting_name, betting_score) |>
  select(
    year,
    round = contest_round,
    country,
    bookmaker = betting_name,
    odds = betting_score
  )

write_csv(bookmakers, "data/CSV/bookmakers.csv")
saveRDS(bookmakers, file = "data/RDA/bookmakers.rda")
