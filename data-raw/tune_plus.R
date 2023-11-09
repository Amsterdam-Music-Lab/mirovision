library(readr)
library(dplyr)

countries <- readRDS("data/RDA/countries.rda")
tune_plus <- 
  read_csv(
    "data-raw/tune_plus.dat",
    col_types = "--ic-dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
  ) |> 
  rename(country_name = country) |> 
  inner_join(countries) |> 
  select(year, country, `0`:`511`)

write_csv(tune_plus, 'data/CSV/tune_plus.csv')
saveRDS(tune_plus, file = 'data/RDA/tune_plus.rda')
