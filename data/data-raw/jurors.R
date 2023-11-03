library(dplyr)
library(readr)
library(stringr)
library(countrycode)

jurors <-
  read_csv(
    "data-raw/jurors.dat",
    col_types =
      c(
        Country = col_character(),
        juror_A = col_integer(),
        juror_B = col_integer(),
        juror_C = col_integer(),
        juror_D = col_integer(),
        juror_E = col_integer(),
        act = col_character(),
        night = col_character(),
        city = col_character(),
        year = col_integer()
      )
  ) |>
  transmute(
    year,
    round =
      case_when(
        night == "first-semi-final" ~ "semi-final-1",
        night == "second-semi-final" ~ "semi-final-2",
        night == "grand-final" ~ "final"
      ),
    from_country =
      case_when(
        act == "bosnia-herzogovina" ~ "Bosnia & Herzogovina",
        act == "north-macedonia" ~ "North Macedonia",
        act == "san-marino" ~ "San Marino",
        act == "united-kingdom" ~ "United Kingdom",
        TRUE ~ str_to_title(act)
      ) |>
      countrycode("country.name.en", "ecb"),
    A = juror_A,
    B = juror_B,
    C = juror_C,
    D = juror_D,
    E =
      if_else(
        year == 2016 & from_country == "RU" & round == "semi-final-1",
        NA,
        juror_E
      ),
    to_country =
      case_when(
        Country == "BosniaHerzegovina" ~ "Bosnia & Herzogovina",
        Country == "NorthMacedonia" ~ "North Macedonia",
        Country == "SanMarino" ~ "San Marino",
        Country == "UnitedKingdom" ~ "United Kingdom",
        TRUE ~ Country
      ) |>
      countrycode("country.name.en", "ecb")
  )
write_csv(jurors, 'data-raw/jurors.csv')
saveRDS(jurors, file = 'data/jurors.rda')
